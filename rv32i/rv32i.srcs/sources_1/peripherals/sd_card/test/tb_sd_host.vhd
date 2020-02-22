
library ieee;
use ieee.std_logic_1164.all;

use work.constants_axi4l.all;

entity tb_sd_host is
end tb_sd_host;


architecture Behavioral of tb_sd_host is
   component sd_host is
      generic (
         SD_SCK_FREQ    : integer := 10000000
      );
      port (
         clk            : in     std_logic;
         reset          : in     std_logic;
         
         -- sd card ports
         sd_sck         : out    std_logic;
         sd_cs_n        : out    std_logic;
         sd_mosi        : out    std_logic;
         sd_miso        : in     std_logic;
         
         -- axi ports
         axi_out        : out    t_axi4l_master_in;
         axi_in         : in     t_axi4l_master_out
      );
   end component;
   
   signal clk, reset : std_logic;
   signal sck, cs, mosi, miso : std_logic;
   signal axi_out : t_axi4l_master_in;
   signal axi_in : t_axi4l_master_out;
   
   constant CLK_PERIOD : time := 10 ns;
   
   signal sim_done : boolean := false;
begin
   process
   begin
      reset <= '1';
      wait until rising_edge(clk);
      reset <= '0';
      wait until rising_edge(clk);
      
      wait for CLK_PERIOD * 50;
      wait;
   end process;

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

   UUT : sd_host
   generic map (
      SD_SCK_FREQ => 25000000
   )
   port map (
      clk => clk,
      reset => reset,
      sd_sck => sck,
      sd_cs_n => cs,
      sd_mosi => mosi,
      sd_miso => miso,
      axi_out => axi_out,
      axi_in => axi_in
   );
end Behavioral;
