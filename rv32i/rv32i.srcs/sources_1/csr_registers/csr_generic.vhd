-- csr_generic.vhd --
-- This file describes a generic CSR register.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Common.all;
use work.Common_CSR.all;


-- read/write in port names are from the point of view of entities other than the generic_csr
entity csr_generic is
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
      
      -- connections to register read/write unit (if applicable)
      direct_read       : out    std_logic_vector(XLEN - 1 downto 0);
      direct_write      : in     std_logic_vector(XLEN - 1 downto 0);
      direct_we         : in     std_logic_vector(XLEN - 1 downto 0)
   );
end csr_generic;


architecture Behavioral of csr_generic is
   signal csr_storage : std_logic_vector(XLEN - 1 downto 0);
   signal csr_write_data : std_logic_vector(XLEN - 1 downto 0);
   signal csr_we : std_logic_vector(XLEN - 1 downto 0);
   type CSR_SELECTION is (CSR_NOT_SELECTED, CSR_ADDRESS1_SELECTED, CSR_ADDRESS2_SELECTED, CSR_ADDRESS3_SELECTED);
   signal csr_addr_selected : CSR_SELECTION;
   signal csr_selected : boolean;
   signal bit_modes_selected : CSR_BIT_MODE_ARRAY;
   signal component_reset : boolean;
begin
   -- check which address was selected and if the csr is selected
   csr_addr_selected <= CSR_ADDRESS1_SELECTED when address = csr_address else
                        CSR_ADDRESS2_SELECTED when ((address = csr_address2) and (use_address2 = true)) else
                        CSR_ADDRESS3_SELECTED when ((address = csr_address3) and (use_address3 = true)) else
                        CSR_NOT_SELECTED;
   with csr_addr_selected select
      csr_selected <= true when CSR_ADDRESS1_SELECTED | CSR_ADDRESS2_SELECTED | CSR_ADDRESS3_SELECTED,
                      false when others;
   
   -- handle which bit modes to use
   bit_modes_selected <= bit_modes when csr_addr_selected = CSR_ADDRESS1_SELECTED else
                         bit_modes2 when csr_addr_selected = CSR_ADDRESS2_SELECTED else
                         bit_modes3 when csr_addr_selected = CSR_ADDRESS3_SELECTED else
                         (others => CSR_RW);  
   
   -- handle write data and write enable source
   -- csr writes take precedence over direct writes
   process (all)
   begin
      if csr_selected and (unsigned(write_en) /= 0) then
         csr_write_data <= write_data;
         csr_we <= write_en;
      else
         csr_write_data <= direct_write;
         csr_we <= direct_we;
      end if;
   end process;
   
   -- handle writing to storage
   write_storage : process (all) is
   begin
      if component_reset then
         csr_storage <= default_value;
      else
         if rising_edge(clk) then
            for i in 0 to XLEN - 1 loop
               -- writing bit
               if csr_we(i) = '1' then
                  if bit_modes_selected(i) = CSR_RW then
                     csr_storage(i) <= csr_write_data(i);
                  end if;
               end if;
            end loop;
         end if;
      end if;
   end process write_storage;
   
   -- handle reading from storage
   read_storage : process (all) is
   begin
      for i in 0 to XLEN - 1 loop  
         case bit_modes_selected(i) is
            when CSR_WIRI | CSR_WPRI => read_data(i) <= '0';
            when CSR_WI | CSR_RW => read_data(i) <= csr_storage(i);
            when others => read_data(i) <= '-';  -- never reached
         end case;
      end loop;
   end process read_storage;
   
   direct_read <= csr_storage;
   
   -- handle reset
   reset_proc : process (all)
   begin
      if reset = '1' then
         component_reset <= true;
      elsif ((reset = '0') and rising_edge(clk)) then
         component_reset <= false;
      end if;
   end process reset_proc;
 
end Behavioral;
