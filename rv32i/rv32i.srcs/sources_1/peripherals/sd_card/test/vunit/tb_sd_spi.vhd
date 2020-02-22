-- VUnit testbench for sd_spi.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.Common;
use work.MyRandom.all;


entity tb_sd_spi is
   generic (
      runner_cfg        : string
   );
end tb_sd_spi;


architecture Behavioral of tb_sd_spi is
   component sd_spi is
      generic (
         CLK_FREQUENCY : integer := 100000000;
         SCK_FREQUENCY : integer := 10000000
      );
      port (
         clk            : in     std_logic;
         reset          : in     std_logic;
         
         enable         : in     std_logic;
         ready          : out    std_logic;
         tx_data        : in     std_logic_vector(7 downto 0);
         rx_data        : out    std_logic_vector(7 downto 0);
         
         sck            : out    std_logic;
         mosi           : out    std_logic;
         miso           : in     std_logic
      );
   end component;

   -- signals for UUT
   signal clk, reset : std_logic;
   signal enable, ready : std_logic;
   signal tx_data, rx_data : std_logic_vector(7 downto 0);
   signal sck, mosi, miso : std_logic;

   -- constants
   constant CLK_FREQUENCY : integer := Common.CLK_FREQUENCY;
   constant SCK_FREQUENCY : integer := 10000000;
   constant CLK_PERIOD : time := 10 ns * real(CLK_FREQUENCY) / 100000000.0; 

   -- signals for simulation
   signal sim_done : boolean := false;
   shared variable gen : random_generator;

begin

   tests : process
      variable byte : std_logic_vector(7 downto 0);
      variable bytes_left : integer := 1000;
   begin
      test_runner_setup(runner, runner_cfg);

      while test_suite loop
         if run("test_random_byte") then
            reset <= '1';
            wait until rising_edge(clk);
            reset <= '0';
            wait until rising_edge(clk);

            while bytes_left /= 0 loop
               byte := gen.randomStdLogicVector(8);
               tx_data <= byte;
               enable <= '1';
               wait until rising_edge(clk) and (ready = '1');
               enable <= '0';
               wait until rising_edge(clk) and (ready = '1');
               
               assert byte = rx_data
               report "Received byte did not match sent byte." severity error;
               bytes_left := bytes_left - 1;
            end loop;
         end if;
      end loop;

      test_runner_cleanup(runner);
      sim_done <= true;
   end process tests;

   gen_clk : process
   begin
      if sim_done then
         wait;
      else
         clk <= '1';
         wait for CLK_PERIOD / 2;
         clk <= '0';
         wait for CLK_PERIOD / 2;
      end if;
   end process gen_clk;

   miso <= mosi;

   UUT : sd_spi
   generic map (
      CLK_FREQUENCY => CLK_FREQUENCY,
      SCK_FREQUENCY => SCK_FREQUENCY
   )
   port map (
      clk => clk,
      reset => reset,
      enable => enable,
      ready => ready,
      tx_data => tx_data,
      rx_data => rx_data,
      sck => sck,
      mosi => mosi,
      miso => miso
   );

end Behavioral;