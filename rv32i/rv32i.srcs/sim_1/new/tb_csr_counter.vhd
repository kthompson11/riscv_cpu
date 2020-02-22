
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.Common.all;
use work.Common_CSR.all;
use work.Common_Sim.all;


entity tb_csr_counter is
end tb_csr_counter;


architecture Behavioral of tb_csr_counter is
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
   
   signal clk, reset, increment : std_logic;
   signal address : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
   signal read_data, write_data, write_en : std_logic_vector(XLEN - 1 downto 0);
   constant default_value : std_logic_vector(COUNTER_SIZE - 1 downto 0) := X"0000000000000004";
   signal sim_done : boolean := false;
begin
   UUT : csr_counter
      generic map (
         address_low => CSR_CYCLE_ADDRESS,
         address_high => CSR_CYCLEH_ADDRESS,
         default_value => default_value
      )
      port map (
         clk => clk,
         reset => reset,
         increment => increment,
         address => address,
         read_data => read_data,
         write_data => write_data,
         write_en => write_en
      );
      
   test : process
      variable temp_vector : std_logic_vector(XLEN - 1 downto 0);
   begin
      increment <= '1';
      address <= (others => '0');
      write_data <= (others => '0');
      write_en <= (others => '0');
      
      wait until rising_edge(clk);  -- test reset
      wait for 3 ns;
      reset <= '1';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait for 3 ns;
      reset <= '0';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait for 1 ns;
      assert unsigned(read_data) = (unsigned(default_value) + 2)
      report "wrong value of read_data" severity error;
      
      -- test increment off
      increment <= '0';
      temp_vector := read_data;
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait for 1 ns;
      assert temp_vector = read_data
      report "counter incremented when increment = '0'" severity error;
      
      -- test address
      temp_vector := read_data;
      address <= CSR_CYCLEH_ADDRESS;
      increment <= '1';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait for 1 ns;
      assert unsigned(read_data) = 0
      report "upper bits of counter should be zero" severity error;
      
      -- test increment again
      address <= CSR_CYCLE_ADDRESS;
      wait until rising_edge(clk);
      wait for 1 ns;
      assert unsigned(read_data) = (unsigned(temp_vector) + 4)
      report "counter did not increment in background" severity error;
      
      -- test writing data
      write_en <= (others => '1');
      write_data <= X"12345678";
      wait until rising_edge(clk);
      wait for 1 ns;
      write_en <= (others => '0');
      wait until rising_edge(clk);
      wait for 1 ns;
      assert unsigned(read_data) = (unsigned(write_data) + 1)
      report "data did not get written correctly" severity error;
      
      sim_done <= true;
      wait;
   end process test;
   
   clk_proc : process
   begin
      if sim_done = false then
         clk <= '0';
         wait for SIM_CLOCK_PERIOD / 2;
         clk <= '1';
         wait for SIM_CLOCK_PERIOD / 2;
      else
         wait;
      end if;
   end process clk_proc;

end Behavioral;
