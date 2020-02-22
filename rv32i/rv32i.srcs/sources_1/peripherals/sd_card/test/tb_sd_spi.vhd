
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.MyRandom.all;


entity tb_sd_spi is
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
         data_in        : in     std_logic_vector(7 downto 0);
         data_out       : out    std_logic_vector(7 downto 0);
         
         sck            : out    std_logic;
         mosi           : out    std_logic;
         miso           : in     std_logic
      );
   end component;
   
   constant CLK_FREQUENCY : integer := 100000000;
   constant SCK_FREQUENCY : integer := 10000000;
   constant CLK_PERIOD : time := 10 ns * real(CLK_FREQUENCY) / 100000000.0; 
   
   -- component signals
   signal clk, reset : std_logic;
   signal enable, ready : std_logic;
   signal data_in, data_out : std_logic_vector(7 downto 0);
   signal sck, mosi, miso : std_logic;
   
   -- miso data signals
   signal miso_data : std_logic_vector(7 downto 0);
   
   signal sim_done : boolean := false;
begin

   miso <= mosi;

   set_stimuli : process
   begin
      reset <= '1';
      enable <= '0';
      wait until rising_edge(clk);
      reset <= '0';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      data_in <= "01010101";
      enable <= '1';
      wait until rising_edge(clk) and (ready = '1');
      enable <= '0';
      wait until rising_edge(clk) and (ready = '1');
      
      sim_done <= true;
      wait;
   end process set_stimuli;

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

   ---------------------------------------------------------------------------------------------------------------------
   ----------------------------------------- component instantiation ---------------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
   
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
      data_in => data_in,
      data_out => data_out,
      sck => sck,
      mosi => mosi,
      miso => miso
   );
end Behavioral;
