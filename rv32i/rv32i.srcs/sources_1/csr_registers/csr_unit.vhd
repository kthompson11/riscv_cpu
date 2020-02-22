-- csr_unit.vhd --
-- Describes the component that handles the CSR registers.
-- TODO: move registers out this file to the devices they most closely connect with (e.g. interrupt registers with interrupt unit)
--       convert to using axi4l bus 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Common_CSR.all;
use work.Common.all;


entity csr_unit is
port (
   clk              : in     std_logic;
   reset            : in     std_logic;
   privilege_mode   : in     std_logic_vector(1 downto 0);
   csr_enable       : in     std_logic;
   
   csr_wd           : in     std_logic_vector(XLEN - 1 downto 0);                 -- data to write to CSR
   instruction      : in     std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);   -- currently executing instruction
   csr_rd           : out    std_logic_vector(XLEN - 1 downto 0);                 -- data read from CSR
   interrupt        : out    std_logic;                                           -- raises illegal instruction exception
   
   instruction_ret  : in     std_logic
   
   -- ports for external access to CSRs (most will be left open or tied to ground)
   --direct_read_mscratch    : out    std_logic_vector(XLEN - 1 downto 0);
   --direct_write_mscratch   : in     std_logic_vector(XLEN - 1 downto 0);
   --direct_we_mscratch      : in     std_logic_vector(XLEN - 1 downto 0)
);
end csr_unit;


architecture Behavioral of csr_unit is
   component csr_generic is
      generic (
         bit_modes         : CSR_BIT_MODE_ARRAY;
         default_value     : std_logic_vector(XLEN - 1 downto 0);
         csr_address       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
         use_address2      : boolean := false;
         csr_address2      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := (others => '-');
         bit_modes2        : CSR_BIT_MODE_ARRAY := (others => CSR_WIRI);
         use_address3      : boolean := false;
         csr_address3      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := (others => '-');
         bit_modes3        : CSR_BIT_MODE_ARRAY := (others => CSR_WIRI)
      );
      port (
         clk               : in     std_logic;
         reset             : in     std_logic;
         
         address           : in     std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
         read_data         : out    std_logic_vector(XLEN - 1 downto 0);
         write_data        : in     std_logic_vector(XLEN - 1 downto 0);
         write_en          : in     std_logic_vector(XLEN - 1 downto 0);
         
         direct_read       : out    std_logic_vector(XLEN - 1 downto 0);
         direct_write      : in     std_logic_vector(XLEN - 1 downto 0);
         direct_we         : in     std_logic_vector(XLEN - 1 downto 0)
      );
   end component;
   
   component csr_counter is
      generic (
         address_low    : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
         address_high   : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
         default_value  : std_logic_vector(COUNTER_SIZE - 1 downto 0);
         use_address2   : boolean := false;
         address2_low   : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := (others => '0');
         address2_high  : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := (others => '0')
      );
      port (
         clk            : in     std_logic;
         reset          : in     std_logic;
         increment      : in    std_logic;  -- when asserted, the counter increments on the rising clock edge
         
         address        : in     std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
         read_data      : out    std_logic_vector(XLEN - 1 downto 0);
         write_data     : in     std_logic_vector(XLEN - 1 downto 0);
         write_en       : in     std_logic_vector(XLEN - 1 downto 0)
      );
   end component;

   signal csr_address : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
   signal csr_privilege : std_logic_vector(1 downto 0);
   signal csr_accessibility : std_logic_vector(1 downto 0);
   signal immediate : std_logic_vector(XLEN - 1 downto 0);
   signal csr_op : std_logic_vector(2 downto 0);
   signal opcode : std_logic_vector(INSTRUCTION_OPCODE_LENGTH - 1 downto 0);
   signal rd : std_logic_vector(4 downto 0);  -- TODO: change these constants
   signal rs : std_logic_vector(4 downto 0);
   signal source_data : std_logic_vector(XLEN - 1 downto 0);
   signal write_data : std_logic_vector(XLEN - 1 downto 0);
   signal read_data : std_logic_vector(XLEN - 1 downto 0);
   signal write_en, write_en_proposed : std_logic_vector(XLEN - 1 downto 0);
   signal valid_address : boolean;
   signal direct_we_sig : std_logic_vector(XLEN - 1 downto 0);
   signal csr_enabled : boolean;
   
   -- machine register outputs
   signal read_data_mscratch : std_logic_vector(XLEN - 1 downto 0);
   
   --------------------------------------------------------------------------------------------------
   ---------------------------------- increment signals ---------------------------------------------
   --------------------------------------------------------------------------------------------------
   signal increment_cycle         : std_logic;
   signal increment_instret       : std_logic;
   signal increment_hpmcounter3   : std_logic;
   signal increment_hpmcounter4   : std_logic;
   signal increment_hpmcounter5   : std_logic;
   signal increment_hpmcounter6   : std_logic;
   signal increment_hpmcounter7   : std_logic;
   signal increment_hpmcounter8   : std_logic;
   signal increment_hpmcounter9   : std_logic;
   signal increment_hpmcounter10  : std_logic;
   signal increment_hpmcounter11  : std_logic;
   signal increment_hpmcounter12  : std_logic;
   signal increment_hpmcounter13  : std_logic;
   signal increment_hpmcounter14  : std_logic;
   signal increment_hpmcounter15  : std_logic;
   signal increment_hpmcounter16  : std_logic;
   signal increment_hpmcounter17  : std_logic;
   signal increment_hpmcounter18  : std_logic;
   signal increment_hpmcounter19  : std_logic;
   signal increment_hpmcounter20  : std_logic;
   signal increment_hpmcounter21  : std_logic;
   signal increment_hpmcounter22  : std_logic;
   signal increment_hpmcounter23  : std_logic;
   signal increment_hpmcounter24  : std_logic;
   signal increment_hpmcounter25  : std_logic;
   signal increment_hpmcounter26  : std_logic;
   signal increment_hpmcounter27  : std_logic;
   signal increment_hpmcounter28  : std_logic;
   signal increment_hpmcounter29  : std_logic;
   signal increment_hpmcounter30  : std_logic;
   signal increment_hpmcounter31  : std_logic;
   
   -------------------------------------------------------------------------------------------------
   --------------------------------- counter outputs -----------------------------------------------
   -------------------------------------------------------------------------------------------------
   
   signal read_data_cycle              : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_instret            : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter3        : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter4        : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter5        : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter6        : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter7        : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter8        : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter9        : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter10       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter11       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter12       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter13       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter14       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter15       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter16       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter17       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter18       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter19       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter20       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter21       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter22       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter23       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter24       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter25       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter26       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter27       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter28       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter29       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter30       : std_logic_vector(XLEN - 1 downto 0);
   signal read_data_hpmcounter31       : std_logic_vector(XLEN - 1 downto 0);

begin
   -- extract instruction informatioN
   csr_address <= instruction(INSTRUCTION_CSR_ADDRESS_HIGH downto INSTRUCTION_CSR_ADDRESS_LOW);
   csr_privilege <= csr_address(CSR_ADDRESS_PRIV_HIGH downto CSR_ADDRESS_PRIV_LOW);
   csr_accessibility <= csr_address(CSR_ADDRESS_ACCESS_HIGH downto CSR_ADDRESS_ACCESS_LOW);
   immediate <= (26 downto 0 => '0') & instruction(INSTRUCTION_RS1_HIGH downto INSTRUCTION_RS1_LOW);  -- TODO: change the literal
   csr_op <= instruction(INSTRUCTION_FUNCT3_HIGH downto INSTRUCTION_FUNCT3_LOW);
   opcode <= instruction(INSTRUCTION_OPCODE_HIGH downto INSTRUCTION_OPCODE_LOW);
   rd <= instruction(INSTRUCTION_CSR_RD_HIGH downto INSTRUCTION_CSR_RD_LOW);
   rs <= instruction(INSTRUCTION_CSR_RS_HIGH downto INSTRUCTION_CSR_RS_LOW);
   
   -- handle the input source data
   with csr_op select
      source_data <= csr_wd when SYSTEM_FUNCT3_CSRRW | SYSTEM_FUNCT3_CSRRS | SYSTEM_FUNCT3_CSRRC,
                     immediate when SYSTEM_FUNCT3_CSRRWI | SYSTEM_FUNCT3_CSRRSI | SYSTEM_FUNCT3_CSRRCI,
                     (others => 'X') when others;  -- this would be an illegal instruction (pass unknown for debugging)
                    
   handle_write_en : process (all) is
   begin
      if csr_enabled then
         case csr_op is
            when SYSTEM_FUNCT3_CSRRW | SYSTEM_FUNCT3_CSRRWI =>
               write_en_proposed <= (others => '1');
            when SYSTEM_FUNCT3_CSRRS | SYSTEM_FUNCT3_CSRRSI | SYSTEM_FUNCT3_CSRRC | SYSTEM_FUNCT3_CSRRCI =>
               if unsigned(rs) = 0 then
                  write_en_proposed <= (others => '0');
               else
                  write_en_proposed <= source_data;
               end if;
            when others => -- invalid operation
               write_en_proposed <= (others => '0');
         end case;
      else
         write_en_proposed <= (others => '0');
      end if;
   end process handle_write_en;
   write_en <= write_en_proposed when interrupt = '0' else
               (others => '0');  -- no writing if an interrupt is occuring
   
   handle_interrupt : process (all) is
   begin
      if csr_enabled then  -- only interrupt if it is a CSR instruction
         if ((unsigned(privilege_mode) < unsigned(csr_privilege)) or  -- insufficient privileges to access register
             ((csr_accessibility = CSR_ACCESSIBILITY_RO) and (unsigned(write_en_proposed) /= 0)) or  -- write to read-only register
             (valid_address = false)) then  -- address is invalid
            interrupt <= '1';
         else
            interrupt <= '0';
         end if;
      else
         interrupt <= '0';
      end if;
          
   end process handle_interrupt;
        
   handle_write_data : process (all) is
   begin
      if ((csr_op = SYSTEM_FUNCT3_CSRRW) or (csr_op = SYSTEM_FUNCT3_CSRRWI)) then
         write_data <= source_data;
      elsif ((csr_op = SYSTEM_FUNCT3_CSRRS) or (csr_op = SYSTEM_FUNCT3_CSRRSI)) then
         write_data <= (others => '1');
      elsif ((csr_op = SYSTEM_FUNCT3_CSRRC) or (csr_op = SYSTEM_FUNCT3_CSRRCI)) then
         write_data <= (others => '0');
      else
         write_data <= (others => '-');  -- bad operation
      end if;
   end process handle_write_data;
   
   -- check if csr_address is valid and assign output to csr_rd
   process (all)
   begin
      case csr_address is
         when CSR_MSCRATCH_ADDRESS =>
            csr_rd <= read_data_mscratch;
            valid_address <= true;
         when CSR_MCYCLE_ADDRESS =>
            csr_rd <= read_data_cycle;
            valid_address <= true;
         when CSR_MINSTRET_ADDRESS =>
            csr_rd <= read_data_instret;
            valid_address <= true;
         when CSR_MHPMCOUNTER3_ADDRESS =>
            csr_rd <= read_data_hpmcounter3;
            valid_address <= true;
         when CSR_MHPMCOUNTER4_ADDRESS =>
            csr_rd <= read_data_hpmcounter4;
            valid_address <= true;
         when CSR_MHPMCOUNTER5_ADDRESS =>
            csr_rd <= read_data_hpmcounter5;
            valid_address <= true;
         when CSR_MHPMCOUNTER6_ADDRESS =>
            csr_rd <= read_data_hpmcounter6;
            valid_address <= true;
         when CSR_MHPMCOUNTER7_ADDRESS =>
            csr_rd <= read_data_hpmcounter7;
            valid_address <= true;
         when CSR_MHPMCOUNTER8_ADDRESS =>
            csr_rd <= read_data_hpmcounter8;
            valid_address <= true;
         when CSR_MHPMCOUNTER9_ADDRESS =>
            csr_rd <= read_data_hpmcounter9;
            valid_address <= true;
         when CSR_MHPMCOUNTER10_ADDRESS =>
            csr_rd <= read_data_hpmcounter10;
            valid_address <= true;
         when CSR_MHPMCOUNTER11_ADDRESS =>
            csr_rd <= read_data_hpmcounter11;
            valid_address <= true;
         when CSR_MHPMCOUNTER12_ADDRESS =>
            csr_rd <= read_data_hpmcounter12;
            valid_address <= true;
         when CSR_MHPMCOUNTER13_ADDRESS =>
            csr_rd <= read_data_hpmcounter13;
            valid_address <= true;
         when CSR_MHPMCOUNTER14_ADDRESS =>
            csr_rd <= read_data_hpmcounter14;
            valid_address <= true;
         when CSR_MHPMCOUNTER15_ADDRESS =>
            csr_rd <= read_data_hpmcounter15;
            valid_address <= true;
         when CSR_MHPMCOUNTER16_ADDRESS =>
            csr_rd <= read_data_hpmcounter16;
            valid_address <= true;
         when CSR_MHPMCOUNTER17_ADDRESS =>
            csr_rd <= read_data_hpmcounter17;
            valid_address <= true;
         when CSR_MHPMCOUNTER18_ADDRESS =>
            csr_rd <= read_data_hpmcounter18;
            valid_address <= true;
         when CSR_MHPMCOUNTER19_ADDRESS =>
            csr_rd <= read_data_hpmcounter19;
            valid_address <= true;
         when CSR_MHPMCOUNTER20_ADDRESS =>
            csr_rd <= read_data_hpmcounter20;
            valid_address <= true;
         when CSR_MHPMCOUNTER21_ADDRESS =>
            csr_rd <= read_data_hpmcounter21;
            valid_address <= true;
         when CSR_MHPMCOUNTER22_ADDRESS =>
            csr_rd <= read_data_hpmcounter22;
            valid_address <= true;
         when CSR_MHPMCOUNTER23_ADDRESS =>
            csr_rd <= read_data_hpmcounter23;
            valid_address <= true;
         when CSR_MHPMCOUNTER24_ADDRESS =>
            csr_rd <= read_data_hpmcounter24;
            valid_address <= true;
         when CSR_MHPMCOUNTER25_ADDRESS =>
            csr_rd <= read_data_hpmcounter25;
            valid_address <= true;
         when CSR_MHPMCOUNTER26_ADDRESS =>
            csr_rd <= read_data_hpmcounter26;
            valid_address <= true;
         when CSR_MHPMCOUNTER27_ADDRESS =>
            csr_rd <= read_data_hpmcounter27;
            valid_address <= true;
         when CSR_MHPMCOUNTER28_ADDRESS =>
            csr_rd <= read_data_hpmcounter28;
            valid_address <= true;
         when CSR_MHPMCOUNTER29_ADDRESS =>
            csr_rd <= read_data_hpmcounter29;
            valid_address <= true;
         when CSR_MHPMCOUNTER30_ADDRESS =>
            csr_rd <= read_data_hpmcounter30;
            valid_address <= true;
         when CSR_MHPMCOUNTER31_ADDRESS =>
            csr_rd <= read_data_hpmcounter31;
            valid_address <= true;
         when CSR_MCYCLEH_ADDRESS =>
            csr_rd <= read_data_cycle;
            valid_address <= true;
         when CSR_MINSTRETH_ADDRESS =>
            csr_rd <= read_data_instret;
            valid_address <= true;
         when CSR_MHPMCOUNTER3H_ADDRESS =>
            csr_rd <= read_data_hpmcounter3;
            valid_address <= true;
         when CSR_MHPMCOUNTER4H_ADDRESS =>
            csr_rd <= read_data_hpmcounter4;
            valid_address <= true;
         when CSR_MHPMCOUNTER5H_ADDRESS =>
            csr_rd <= read_data_hpmcounter5;
            valid_address <= true;
         when CSR_MHPMCOUNTER6H_ADDRESS =>
            csr_rd <= read_data_hpmcounter6;
            valid_address <= true;
         when CSR_MHPMCOUNTER7H_ADDRESS =>
            csr_rd <= read_data_hpmcounter7;
            valid_address <= true;
         when CSR_MHPMCOUNTER8H_ADDRESS =>
            csr_rd <= read_data_hpmcounter8;
            valid_address <= true;
         when CSR_MHPMCOUNTER9H_ADDRESS =>
            csr_rd <= read_data_hpmcounter9;
            valid_address <= true;
         when CSR_MHPMCOUNTER10H_ADDRESS =>
            csr_rd <= read_data_hpmcounter10;
            valid_address <= true;
         when CSR_MHPMCOUNTER11H_ADDRESS =>
            csr_rd <= read_data_hpmcounter11;
            valid_address <= true;
         when CSR_MHPMCOUNTER12H_ADDRESS =>
            csr_rd <= read_data_hpmcounter12;
            valid_address <= true;
         when CSR_MHPMCOUNTER13H_ADDRESS =>
            csr_rd <= read_data_hpmcounter13;
            valid_address <= true;
         when CSR_MHPMCOUNTER14H_ADDRESS =>
            csr_rd <= read_data_hpmcounter14;
            valid_address <= true;
         when CSR_MHPMCOUNTER15H_ADDRESS =>
            csr_rd <= read_data_hpmcounter15;
            valid_address <= true;
         when CSR_MHPMCOUNTER16H_ADDRESS =>
            csr_rd <= read_data_hpmcounter16;
            valid_address <= true;
         when CSR_MHPMCOUNTER17H_ADDRESS =>
            csr_rd <= read_data_hpmcounter17;
            valid_address <= true;
         when CSR_MHPMCOUNTER18H_ADDRESS =>
            csr_rd <= read_data_hpmcounter18;
            valid_address <= true;
         when CSR_MHPMCOUNTER19H_ADDRESS =>
            csr_rd <= read_data_hpmcounter19;
            valid_address <= true;
         when CSR_MHPMCOUNTER20H_ADDRESS =>
            csr_rd <= read_data_hpmcounter20;
            valid_address <= true;
         when CSR_MHPMCOUNTER21H_ADDRESS =>
            csr_rd <= read_data_hpmcounter21;
            valid_address <= true;
         when CSR_MHPMCOUNTER22H_ADDRESS =>
            csr_rd <= read_data_hpmcounter22;
            valid_address <= true;
         when CSR_MHPMCOUNTER23H_ADDRESS =>
            csr_rd <= read_data_hpmcounter23;
            valid_address <= true;
         when CSR_MHPMCOUNTER24H_ADDRESS =>
            csr_rd <= read_data_hpmcounter24;
            valid_address <= true;
         when CSR_MHPMCOUNTER25H_ADDRESS =>
            csr_rd <= read_data_hpmcounter25;
            valid_address <= true;
         when CSR_MHPMCOUNTER26H_ADDRESS =>
            csr_rd <= read_data_hpmcounter26;
            valid_address <= true;
         when CSR_MHPMCOUNTER27H_ADDRESS =>
            csr_rd <= read_data_hpmcounter27;
            valid_address <= true;
         when CSR_MHPMCOUNTER28H_ADDRESS =>
            csr_rd <= read_data_hpmcounter28;
            valid_address <= true;
         when CSR_MHPMCOUNTER29H_ADDRESS =>
            csr_rd <= read_data_hpmcounter29;
            valid_address <= true;
         when CSR_MHPMCOUNTER30H_ADDRESS =>
            csr_rd <= read_data_hpmcounter30;
            valid_address <= true;
         when CSR_MHPMCOUNTER31H_ADDRESS =>
            csr_rd <= read_data_hpmcounter31;
            valid_address <= true;
         when CSR_CYCLE_ADDRESS =>
            csr_rd <= read_data_cycle;
            valid_address <= true;
         when CSR_INSTRET_ADDRESS =>
            csr_rd <= read_data_instret;
            valid_address <= true;
         when CSR_HPMCOUNTER3_ADDRESS =>
            csr_rd <= read_data_hpmcounter3;
            valid_address <= true;
         when CSR_HPMCOUNTER4_ADDRESS =>
            csr_rd <= read_data_hpmcounter4;
            valid_address <= true;
         when CSR_HPMCOUNTER5_ADDRESS =>
            csr_rd <= read_data_hpmcounter5;
            valid_address <= true;
         when CSR_HPMCOUNTER6_ADDRESS =>
            csr_rd <= read_data_hpmcounter6;
            valid_address <= true;
         when CSR_HPMCOUNTER7_ADDRESS =>
            csr_rd <= read_data_hpmcounter7;
            valid_address <= true;
         when CSR_HPMCOUNTER8_ADDRESS =>
            csr_rd <= read_data_hpmcounter8;
            valid_address <= true;
         when CSR_HPMCOUNTER9_ADDRESS =>
            csr_rd <= read_data_hpmcounter9;
            valid_address <= true;
         when CSR_HPMCOUNTER10_ADDRESS =>
            csr_rd <= read_data_hpmcounter10;
            valid_address <= true;
         when CSR_HPMCOUNTER11_ADDRESS =>
            csr_rd <= read_data_hpmcounter11;
            valid_address <= true;
         when CSR_HPMCOUNTER12_ADDRESS =>
            csr_rd <= read_data_hpmcounter12;
            valid_address <= true;
         when CSR_HPMCOUNTER13_ADDRESS =>
            csr_rd <= read_data_hpmcounter13;
            valid_address <= true;
         when CSR_HPMCOUNTER14_ADDRESS =>
            csr_rd <= read_data_hpmcounter14;
            valid_address <= true;
         when CSR_HPMCOUNTER15_ADDRESS =>
            csr_rd <= read_data_hpmcounter15;
            valid_address <= true;
         when CSR_HPMCOUNTER16_ADDRESS =>
            csr_rd <= read_data_hpmcounter16;
            valid_address <= true;
         when CSR_HPMCOUNTER17_ADDRESS =>
            csr_rd <= read_data_hpmcounter17;
            valid_address <= true;
         when CSR_HPMCOUNTER18_ADDRESS =>
            csr_rd <= read_data_hpmcounter18;
            valid_address <= true;
         when CSR_HPMCOUNTER19_ADDRESS =>
            csr_rd <= read_data_hpmcounter19;
            valid_address <= true;
         when CSR_HPMCOUNTER20_ADDRESS =>
            csr_rd <= read_data_hpmcounter20;
            valid_address <= true;
         when CSR_HPMCOUNTER21_ADDRESS =>
            csr_rd <= read_data_hpmcounter21;
            valid_address <= true;
         when CSR_HPMCOUNTER22_ADDRESS =>
            csr_rd <= read_data_hpmcounter22;
            valid_address <= true;
         when CSR_HPMCOUNTER23_ADDRESS =>
            csr_rd <= read_data_hpmcounter23;
            valid_address <= true;
         when CSR_HPMCOUNTER24_ADDRESS =>
            csr_rd <= read_data_hpmcounter24;
            valid_address <= true;
         when CSR_HPMCOUNTER25_ADDRESS =>
            csr_rd <= read_data_hpmcounter25;
            valid_address <= true;
         when CSR_HPMCOUNTER26_ADDRESS =>
            csr_rd <= read_data_hpmcounter26;
            valid_address <= true;
         when CSR_HPMCOUNTER27_ADDRESS =>
            csr_rd <= read_data_hpmcounter27;
            valid_address <= true;
         when CSR_HPMCOUNTER28_ADDRESS =>
            csr_rd <= read_data_hpmcounter28;
            valid_address <= true;
         when CSR_HPMCOUNTER29_ADDRESS =>
            csr_rd <= read_data_hpmcounter29;
            valid_address <= true;
         when CSR_HPMCOUNTER30_ADDRESS =>
            csr_rd <= read_data_hpmcounter30;
            valid_address <= true;
         when CSR_HPMCOUNTER31_ADDRESS =>
            csr_rd <= read_data_hpmcounter31;
            valid_address <= true;
         when CSR_CYCLEH_ADDRESS =>
            csr_rd <= read_data_cycle;
            valid_address <= true;
         when CSR_INSTRETH_ADDRESS =>
            csr_rd <= read_data_instret;
            valid_address <= true;
         when CSR_HPMCOUNTER3H_ADDRESS =>
            csr_rd <= read_data_hpmcounter3;
            valid_address <= true;
         when CSR_HPMCOUNTER4H_ADDRESS =>
            csr_rd <= read_data_hpmcounter4;
            valid_address <= true;
         when CSR_HPMCOUNTER5H_ADDRESS =>
            csr_rd <= read_data_hpmcounter5;
            valid_address <= true;
         when CSR_HPMCOUNTER6H_ADDRESS =>
            csr_rd <= read_data_hpmcounter6;
            valid_address <= true;
         when CSR_HPMCOUNTER7H_ADDRESS =>
            csr_rd <= read_data_hpmcounter7;
            valid_address <= true;
         when CSR_HPMCOUNTER8H_ADDRESS =>
            csr_rd <= read_data_hpmcounter8;
            valid_address <= true;
         when CSR_HPMCOUNTER9H_ADDRESS =>
            csr_rd <= read_data_hpmcounter9;
            valid_address <= true;
         when CSR_HPMCOUNTER10H_ADDRESS =>
            csr_rd <= read_data_hpmcounter10;
            valid_address <= true;
         when CSR_HPMCOUNTER11H_ADDRESS =>
            csr_rd <= read_data_hpmcounter11;
            valid_address <= true;
         when CSR_HPMCOUNTER12H_ADDRESS =>
            csr_rd <= read_data_hpmcounter12;
            valid_address <= true;
         when CSR_HPMCOUNTER13H_ADDRESS =>
            csr_rd <= read_data_hpmcounter13;
            valid_address <= true;
         when CSR_HPMCOUNTER14H_ADDRESS =>
            csr_rd <= read_data_hpmcounter14;
            valid_address <= true;
         when CSR_HPMCOUNTER15H_ADDRESS =>
            csr_rd <= read_data_hpmcounter15;
            valid_address <= true;
         when CSR_HPMCOUNTER16H_ADDRESS =>
            csr_rd <= read_data_hpmcounter16;
            valid_address <= true;
         when CSR_HPMCOUNTER17H_ADDRESS =>
            csr_rd <= read_data_hpmcounter17;
            valid_address <= true;
         when CSR_HPMCOUNTER18H_ADDRESS =>
            csr_rd <= read_data_hpmcounter18;
            valid_address <= true;
         when CSR_HPMCOUNTER19H_ADDRESS =>
            csr_rd <= read_data_hpmcounter19;
            valid_address <= true;
         when CSR_HPMCOUNTER20H_ADDRESS =>
            csr_rd <= read_data_hpmcounter20;
            valid_address <= true;
         when CSR_HPMCOUNTER21H_ADDRESS =>
            csr_rd <= read_data_hpmcounter21;
            valid_address <= true;
         when CSR_HPMCOUNTER22H_ADDRESS =>
            csr_rd <= read_data_hpmcounter22;
            valid_address <= true;
         when CSR_HPMCOUNTER23H_ADDRESS =>
            csr_rd <= read_data_hpmcounter23;
            valid_address <= true;
         when CSR_HPMCOUNTER24H_ADDRESS =>
            csr_rd <= read_data_hpmcounter24;
            valid_address <= true;
         when CSR_HPMCOUNTER25H_ADDRESS =>
            csr_rd <= read_data_hpmcounter25;
            valid_address <= true;
         when CSR_HPMCOUNTER26H_ADDRESS =>
            csr_rd <= read_data_hpmcounter26;
            valid_address <= true;
         when CSR_HPMCOUNTER27H_ADDRESS =>
            csr_rd <= read_data_hpmcounter27;
            valid_address <= true;
         when CSR_HPMCOUNTER28H_ADDRESS =>
            csr_rd <= read_data_hpmcounter28;
            valid_address <= true;
         when CSR_HPMCOUNTER29H_ADDRESS =>
            csr_rd <= read_data_hpmcounter29;
            valid_address <= true;
         when CSR_HPMCOUNTER30H_ADDRESS =>
            csr_rd <= read_data_hpmcounter30;
            valid_address <= true;
         when CSR_HPMCOUNTER31H_ADDRESS =>
            csr_rd <= read_data_hpmcounter31;
            valid_address <= true;
         when others =>
            csr_rd <= (others => '0');
            valid_address <= false;
      end case;
   end process;
   
   ----------------------------------- CSR instatiation -------------------------------------------
   -- mvendorid
   -- marchid
   -- mimpid
   -- mhartid
   -- misa
--   misa : csr_generic
--   generic map (
--      bit_modes => CSR_MISA_BIT_MODES,
--      default_value => CSR_MISA_DEFAULT,
--      csr_address => CSR_MISA
--   )
--   port map (
--      clk => clk,
--      reset => reset,
--      csr_address_line => csr_address,
--      csr_read_line => csr_read_line,
--      csr_write_line => csr_write_line,
--      csr_we_line => csr_write_en,
--      direct_read => open,
--      direct_write => (others => '0'),
--      direct_we => (others => '0')
--   );
      
   -- mscratch
--   mscratch : csr_generic
--   generic map (
--      bit_modes => CSR_MSCRATCH_BIT_MODES,
--      default_value => CSR_MSCRATCH_DEFAULT,
--      csr_address => CSR_MSCRATCH_ADDRESS
--   )
--   port map (
--      clk => clk,
--      reset => reset,
--      address => csr_address,
--      read_data => read_data_mscratch,
--      write_data => write_data,
--      write_en => write_en,
--      direct_read => direct_read_mscratch,
--      direct_write => direct_write_mscratch,
--      direct_we => direct_we_mscratch
--   );
   
   -- counters/timers
   cycle : csr_counter
      generic map (
         address_low => CSR_MCYCLE_ADDRESS,
         address_high => CSR_MCYCLEH_ADDRESS,
         default_value => CSR_CYCLE_DEFAULT,
         use_address2 => true,
         address2_low => CSR_CYCLE_ADDRESS,
         address2_high => CSR_CYCLEH_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_cycle,
         address => csr_address,
         read_data => read_data_cycle,
         write_data => write_data,
         write_en => write_en
      );
   
   instret : csr_counter
      generic map (
         address_low => CSR_MINSTRET_ADDRESS,
         address_high => CSR_MINSTRETH_ADDRESS,
         default_value => CSR_INSTRET_DEFAULT,
         use_address2 => true,
         address2_low => CSR_INSTRET_ADDRESS,
         address2_high => CSR_INSTRETH_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_instret,
         address => csr_address,
         read_data => read_data_instret,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter3 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER3_ADDRESS,
         address_high => CSR_MHPMCOUNTER3H_ADDRESS,
         default_value => CSR_HPMCOUNTER3_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER3_ADDRESS,
         address2_high => CSR_HPMCOUNTER3H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter3,
         address => csr_address,
         read_data => read_data_hpmcounter3,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter4 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER4_ADDRESS,
         address_high => CSR_MHPMCOUNTER4H_ADDRESS,
         default_value => CSR_HPMCOUNTER4_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER4_ADDRESS,
         address2_high => CSR_HPMCOUNTER4H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter4,
         address => csr_address,
         read_data => read_data_hpmcounter4,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter5 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER5_ADDRESS,
         address_high => CSR_MHPMCOUNTER5H_ADDRESS,
         default_value => CSR_HPMCOUNTER5_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER5_ADDRESS,
         address2_high => CSR_HPMCOUNTER5H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter5,
         address => csr_address,
         read_data => read_data_hpmcounter5,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter6 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER6_ADDRESS,
         address_high => CSR_MHPMCOUNTER6H_ADDRESS,
         default_value => CSR_HPMCOUNTER6_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER6_ADDRESS,
         address2_high => CSR_HPMCOUNTER6H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter6,
         address => csr_address,
         read_data => read_data_hpmcounter6,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter7 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER7_ADDRESS,
         address_high => CSR_MHPMCOUNTER7H_ADDRESS,
         default_value => CSR_HPMCOUNTER7_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER7_ADDRESS,
         address2_high => CSR_HPMCOUNTER7H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter7,
         address => csr_address,
         read_data => read_data_hpmcounter7,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter8 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER8_ADDRESS,
         address_high => CSR_MHPMCOUNTER8H_ADDRESS,
         default_value => CSR_HPMCOUNTER8_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER8_ADDRESS,
         address2_high => CSR_HPMCOUNTER8H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter8,
         address => csr_address,
         read_data => read_data_hpmcounter8,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter9 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER9_ADDRESS,
         address_high => CSR_MHPMCOUNTER9H_ADDRESS,
         default_value => CSR_HPMCOUNTER9_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER9_ADDRESS,
         address2_high => CSR_HPMCOUNTER9H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter9,
         address => csr_address,
         read_data => read_data_hpmcounter9,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter10 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER10_ADDRESS,
         address_high => CSR_MHPMCOUNTER10H_ADDRESS,
         default_value => CSR_HPMCOUNTER10_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER10_ADDRESS,
         address2_high => CSR_HPMCOUNTER10H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter10,
         address => csr_address,
         read_data => read_data_hpmcounter10,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter11 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER11_ADDRESS,
         address_high => CSR_MHPMCOUNTER11H_ADDRESS,
         default_value => CSR_HPMCOUNTER11_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER11_ADDRESS,
         address2_high => CSR_HPMCOUNTER11H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter11,
         address => csr_address,
         read_data => read_data_hpmcounter11,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter12 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER12_ADDRESS,
         address_high => CSR_MHPMCOUNTER12H_ADDRESS,
         default_value => CSR_HPMCOUNTER12_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER12_ADDRESS,
         address2_high => CSR_HPMCOUNTER12H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter12,
         address => csr_address,
         read_data => read_data_hpmcounter12,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter13 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER13_ADDRESS,
         address_high => CSR_MHPMCOUNTER13H_ADDRESS,
         default_value => CSR_HPMCOUNTER13_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER13_ADDRESS,
         address2_high => CSR_HPMCOUNTER13H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter13,
         address => csr_address,
         read_data => read_data_hpmcounter13,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter14 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER14_ADDRESS,
         address_high => CSR_MHPMCOUNTER14H_ADDRESS,
         default_value => CSR_HPMCOUNTER14_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER14_ADDRESS,
         address2_high => CSR_HPMCOUNTER14H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter14,
         address => csr_address,
         read_data => read_data_hpmcounter14,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter15 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER15_ADDRESS,
         address_high => CSR_MHPMCOUNTER15H_ADDRESS,
         default_value => CSR_HPMCOUNTER15_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER15_ADDRESS,
         address2_high => CSR_HPMCOUNTER15H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter15,
         address => csr_address,
         read_data => read_data_hpmcounter15,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter16 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER16_ADDRESS,
         address_high => CSR_MHPMCOUNTER16H_ADDRESS,
         default_value => CSR_HPMCOUNTER16_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER16_ADDRESS,
         address2_high => CSR_HPMCOUNTER16H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter16,
         address => csr_address,
         read_data => read_data_hpmcounter16,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter17 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER17_ADDRESS,
         address_high => CSR_MHPMCOUNTER17H_ADDRESS,
         default_value => CSR_HPMCOUNTER17_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER17_ADDRESS,
         address2_high => CSR_HPMCOUNTER17H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter17,
         address => csr_address,
         read_data => read_data_hpmcounter17,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter18 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER18_ADDRESS,
         address_high => CSR_MHPMCOUNTER18H_ADDRESS,
         default_value => CSR_HPMCOUNTER18_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER18_ADDRESS,
         address2_high => CSR_HPMCOUNTER18H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter18,
         address => csr_address,
         read_data => read_data_hpmcounter18,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter19 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER19_ADDRESS,
         address_high => CSR_MHPMCOUNTER19H_ADDRESS,
         default_value => CSR_HPMCOUNTER19_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER19_ADDRESS,
         address2_high => CSR_HPMCOUNTER19H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter19,
         address => csr_address,
         read_data => read_data_hpmcounter19,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter20 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER20_ADDRESS,
         address_high => CSR_MHPMCOUNTER20H_ADDRESS,
         default_value => CSR_HPMCOUNTER20_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER20_ADDRESS,
         address2_high => CSR_HPMCOUNTER20H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter20,
         address => csr_address,
         read_data => read_data_hpmcounter20,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter21 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER21_ADDRESS,
         address_high => CSR_MHPMCOUNTER21H_ADDRESS,
         default_value => CSR_HPMCOUNTER21_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER21_ADDRESS,
         address2_high => CSR_HPMCOUNTER21H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter21,
         address => csr_address,
         read_data => read_data_hpmcounter21,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter22 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER22_ADDRESS,
         address_high => CSR_MHPMCOUNTER22H_ADDRESS,
         default_value => CSR_HPMCOUNTER22_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER22_ADDRESS,
         address2_high => CSR_HPMCOUNTER22H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter22,
         address => csr_address,
         read_data => read_data_hpmcounter22,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter23 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER23_ADDRESS,
         address_high => CSR_MHPMCOUNTER23H_ADDRESS,
         default_value => CSR_HPMCOUNTER23_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER23_ADDRESS,
         address2_high => CSR_HPMCOUNTER23H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter23,
         address => csr_address,
         read_data => read_data_hpmcounter23,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter24 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER24_ADDRESS,
         address_high => CSR_MHPMCOUNTER24H_ADDRESS,
         default_value => CSR_HPMCOUNTER24_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER24_ADDRESS,
         address2_high => CSR_HPMCOUNTER24H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter24,
         address => csr_address,
         read_data => read_data_hpmcounter24,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter25 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER25_ADDRESS,
         address_high => CSR_MHPMCOUNTER25H_ADDRESS,
         default_value => CSR_HPMCOUNTER25_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER25_ADDRESS,
         address2_high => CSR_HPMCOUNTER25H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter25,
         address => csr_address,
         read_data => read_data_hpmcounter25,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter26 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER26_ADDRESS,
         address_high => CSR_MHPMCOUNTER26H_ADDRESS,
         default_value => CSR_HPMCOUNTER26_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER26_ADDRESS,
         address2_high => CSR_HPMCOUNTER26H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter26,
         address => csr_address,
         read_data => read_data_hpmcounter26,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter27 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER27_ADDRESS,
         address_high => CSR_MHPMCOUNTER27H_ADDRESS,
         default_value => CSR_HPMCOUNTER27_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER27_ADDRESS,
         address2_high => CSR_HPMCOUNTER27H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter27,
         address => csr_address,
         read_data => read_data_hpmcounter27,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter28 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER28_ADDRESS,
         address_high => CSR_MHPMCOUNTER28H_ADDRESS,
         default_value => CSR_HPMCOUNTER28_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER28_ADDRESS,
         address2_high => CSR_HPMCOUNTER28H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter28,
         address => csr_address,
         read_data => read_data_hpmcounter28,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter29 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER29_ADDRESS,
         address_high => CSR_MHPMCOUNTER29H_ADDRESS,
         default_value => CSR_HPMCOUNTER29_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER29_ADDRESS,
         address2_high => CSR_HPMCOUNTER29H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter29,
         address => csr_address,
         read_data => read_data_hpmcounter29,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter30 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER30_ADDRESS,
         address_high => CSR_MHPMCOUNTER30H_ADDRESS,
         default_value => CSR_HPMCOUNTER30_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER30_ADDRESS,
         address2_high => CSR_HPMCOUNTER30H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter30,
         address => csr_address,
         read_data => read_data_hpmcounter30,
         write_data => write_data,
         write_en => write_en
      );
   
   hpmcounter31 : csr_counter
      generic map (
         address_low => CSR_MHPMCOUNTER31_ADDRESS,
         address_high => CSR_MHPMCOUNTER31H_ADDRESS,
         default_value => CSR_HPMCOUNTER31_DEFAULT,
         use_address2 => true,
         address2_low => CSR_HPMCOUNTER31_ADDRESS,
         address2_high => CSR_HPMCOUNTER31H_ADDRESS
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment_hpmcounter31,
         address => csr_address,
         read_data => read_data_hpmcounter31,
         write_data => write_data,
         write_en => write_en
      );

   increment_cycle        <= '1';  -- incremented every cycle
   increment_instret      <= instruction_ret;  -- incremented when an instruction is retired
   increment_hpmcounter3  <= '0';
   increment_hpmcounter4  <= '0';
   increment_hpmcounter5  <= '0';
   increment_hpmcounter6  <= '0';
   increment_hpmcounter7  <= '0';
   increment_hpmcounter8  <= '0';
   increment_hpmcounter9  <= '0';
   increment_hpmcounter10 <= '0';
   increment_hpmcounter11 <= '0';
   increment_hpmcounter12 <= '0';
   increment_hpmcounter13 <= '0';
   increment_hpmcounter14 <= '0';
   increment_hpmcounter15 <= '0';
   increment_hpmcounter16 <= '0';
   increment_hpmcounter17 <= '0';
   increment_hpmcounter18 <= '0';
   increment_hpmcounter19 <= '0';
   increment_hpmcounter20 <= '0';
   increment_hpmcounter21 <= '0';
   increment_hpmcounter22 <= '0';
   increment_hpmcounter23 <= '0';
   increment_hpmcounter24 <= '0';
   increment_hpmcounter25 <= '0';
   increment_hpmcounter26 <= '0';
   increment_hpmcounter27 <= '0';
   increment_hpmcounter28 <= '0';
   increment_hpmcounter29 <= '0';
   increment_hpmcounter30 <= '0';
   increment_hpmcounter31 <= '0';
   
end Behavioral;
