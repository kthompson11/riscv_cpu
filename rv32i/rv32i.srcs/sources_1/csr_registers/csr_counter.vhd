
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Common.all;
use work.Common_CSR.all;


entity csr_counter is
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
end csr_counter;


architecture Behavioral of csr_counter is
   signal counter_storage : std_logic_vector(COUNTER_SIZE - 1 downto 0);
   signal component_reset : boolean;
   signal high_bits_selected : boolean;
   signal counter_selected : boolean;
   
begin
   -- handle writing to counter (reset, machine_write_increment)
   write_counter : process (all)
   begin
      if component_reset then
         counter_storage <= default_value;
      elsif rising_edge(clk) then
         if counter_selected and (unsigned(write_en) /= 0) then  -- counters are always writable (interrupt occurs if user attempts to write)
            if high_bits_selected then
               counter_storage(COUNTERH_HIGH downto COUNTERH_LOW) <= write_data;
            else
               counter_storage(COUNTER_HIGH downto COUNTER_LOW) <= write_data;
            end if;
         elsif increment = '1' then
            counter_storage <= std_logic_vector(unsigned(counter_storage) + 1);
         end if;
      end if;
   end process write_counter;
   
   -- handle reset
   process (all)
   begin
      if reset = '1' then
         component_reset <= true;
      elsif (reset = '0') and rising_edge(clk) then
         component_reset <= false;
      end if;
   end process;
   
   -- handle reading counter (counters always readable)
   high_bits_selected <= true when address = address_high else
                         true when (use_address2 = true) and (address = address2_high) else
                         false;
   counter_selected <= true when address = address_high else
                       true when address = address_low else
                       true when (use_address2 = true) and (address = address2_high) else
                       true when (use_address2 = true) and (address = address2_low) else
                       false;
   read_data <= counter_storage(COUNTERH_HIGH downto COUNTERH_LOW) when high_bits_selected else
                counter_storage(COUNTER_HIGH downto COUNTER_LOW);

end Behavioral;
