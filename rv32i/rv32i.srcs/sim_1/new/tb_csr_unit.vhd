

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.all;
use work.Common_CSR.all;
use work.MyRandom.all;
use work.Common_Sim.all;

entity tb_csr_unit is
end tb_csr_unit;

architecture Behavioral of tb_csr_unit is
   component csr_unit is
   port (
      clk            : in     std_logic;
      reset          : in     std_logic;
      privilege_mode : in     std_logic_vector(1 downto 0);
      
      csr_wd         : in     std_logic_vector(XLEN - 1 downto 0);                 -- data to write to CSR
      instruction    : in     std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);   -- currently executing instruction
      csr_rd         : out    std_logic_vector(XLEN - 1 downto 0);                 -- data read from CSR
      interrupt      : out    std_logic;                                           -- raises illegal instruction exception
      
      -- bus signals for nonlocal CSRs
      csr_addr_line  : out    std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);   -- address of the CSR to operate on
      csr_write_line : out    std_logic_vector(XLEN - 1 downto 0);                 -- bus line for written data
      csr_read_line  : in     std_logic_vector(XLEN - 1 downto 0);                 -- bus line for read data
      csr_write_en   : out    std_logic_vector(XLEN - 1 downto 0)                  -- enables writes to specific bits
   );
   end component;
   
   signal clk, reset, interrupt : std_logic;
   signal privilege_mode : std_logic_vector(1 downto 0);
   signal csr_wd, csr_rd : std_logic_vector(XLEN - 1 downto 0);
   signal instruction : std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
   signal csr_addr_line : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
   signal csr_write_line, csr_read_line, csr_write_en : std_logic_vector(XLEN - 1 downto 0);
begin
   UUT : csr_unit
   port map (
      clk,
      reset,
      privilege_mode,
      csr_wd,
      instruction,
      csr_rd,
      interrupt,
      csr_addr_line,
      csr_write_line,
      csr_read_line,
      csr_write_en
   );
   
   process is
   begin
      -- test write_en
      -- opcode not SYSTEM
      setOpcode(instruction, OPCODE_LOAD);
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRW);
      setRS1(instruction, REGISTER_4);
      csr_wd <= randomStdLogicVector(XLEN);
      wait for 10 ns;
      assert csr_write_en = (XLEN - 1 downto 0 => '0')
         report "write_en - nonzero value when opcode /= SYSTEM" severity error;
      -- CSRRW
      setOpcode(instruction, OPCODE_SYSTEM);
      wait for 10 ns;
      assert csr_write_en = (XLEN - 1 downto 0 => '1')
         report "write_en - all bits of write_en should be high when csr_op = CSRRW/CSRRWI" severity error;
      -- CSRRS
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRS);
      wait for 10 ns;
      assert csr_write_en = csr_wd
         report "write_en - write_en should match rs1 on a CSR set or clear operation" severity error;
      -- RS1 = 0, csr_op = CSRRS
      setRS1(instruction, REGISTER_0);
      wait for 10 ns;
      assert csr_write_en = (XLEN - 1 downto 0 => '0')
         report "write_en - value should be zero when RS1 = 0 and csr_op /= RW/RWI" severity error;
      -- RS1 = 0, csr_op = CSRRW
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRW);
      wait for 10 ns;
      assert csr_write_en = (XLEN - 1 downto 0 => '1')
         report "write_en - value should be all '1' when RS1 = 0 and csr_op = RW/RWI" severity error;
      -- test set with immediate
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRSI);
      setRS1(instruction, REGISTER_5);
      wait for 10 ns;
      assert csr_write_en = (XLEN -1 downto INSTRUCTION_RS1_LENGTH => '0') & REGISTER_5
         report "write_en - value should be zero extended immedate of RS1" severity error;
   
      -- test interrupt
      -- opcode not SYSTEM
      instruction <= (others => '0');
      wait for 10 ns;
      assert interrupt = '0'
         report "interrupt - value should be zero if opcode != SYSTEM" severity error;
      -- privilege mode high enough
      setOpcode(instruction, OPCODE_SYSTEM);
      privilege_mode <= PRIVILEGE_MACHINE;
      instruction(INSTRUCTION_CSR_ADDRESS_HIGH downto INSTRUCTION_CSR_ADDRESS_LOW) <= CSR_MVENDORID;
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRS);
      setRS1(instruction, REGISTER_0);
      wait for 10 ns;
      assert interrupt = '0'
         report "interrupt - value should be zero when privileges are sufficient" severity error;
      -- privilege mode not high enough
      privilege_mode <= PRIVILEGE_USER;
      wait for 10 ns;
      assert interrupt = '1'
         report "interrupt - value should be '1' when privileges are insufficient" severity error;
      -- write to read-only register
      privilege_mode <= PRIVILEGE_MACHINE;
      setRS1(instruction, REGISTER_1);
      wait for 10 ns;
      assert interrupt = '1'
         report "interrupt - value should be '1' when writing to read-only register" severity error;
      -- write to RW register
      instruction(INSTRUCTION_CSR_ADDRESS_HIGH downto INSTRUCTION_CSR_ADDRESS_LOW) <= CSR_MSTATUS;
      wait for 10 ns;
      assert interrupt = '0'
         report "interrupt - value should be '0' when writing to a RW register" severity error;
      -- access valid address
      wait for 10 ns;
      assert interrupt = '0'
         report "interrupt - value should be '0' when accessing a valid register" severity error;
      -- access invalid address
      instruction(INSTRUCTION_CSR_ADDRESS_HIGH downto INSTRUCTION_CSR_ADDRESS_LOW) <= (others => '0');
      wait for 10 ns;
      assert interrupt = '1'
         report "interrupt - value should be '1' when accessing an invalid register" severity error;
         
      -- write_data
      -- csr_op = CSRRW/CSRRWI
      setOpcode(instruction, OPCODE_SYSTEM);
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRW);
      wait for 10 ns;
      assert csr_write_line = csr_wd
         report "csr_write_line - value should be equal to csr_wd when csr_op = CSRRW" severity error;
      -- csr_op = CSRRS/CSRRSI
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRS);
      wait for 10 ns;
      assert csr_write_line = (XLEN - 1 downto 0 => '1')
         report "csr_write_line - value should be all '1' when csr_op = CSRRS" severity error;
      -- csr_op = CSRRC/CSRRCI
      setFunct3(instruction, SYSTEM_FUNCT3_CSRRC);
      wait for 10 ns;
      assert csr_write_line = (XLEN - 1 downto 0 => '0')
         report "csr_write_line - value should be all '0' when csr_op = CSRRC" severity error;
      
      -- test writing/reading from registers
      -- write then read RW
      -- write then read RW with fields than ignore writes
      -- read from RO register
   
      wait;  -- end simulation
   end process;

end Behavioral;
