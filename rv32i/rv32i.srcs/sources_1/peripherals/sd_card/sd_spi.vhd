-- TODO: rename data_in/data_out


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_spi is
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
end sd_spi;

architecture Behavioral of sd_spi is
   type t_spi_state is (ST_RESET, ST_READY, ST_SENDING);
   signal state : t_spi_state;
   signal mosi_data : std_logic_vector(7 downto 0);
   signal bits_left : integer range 0 to 8;  -- index of the bits currently being transmitted or received
   
   -- sck generation signals
   constant SCK_MAX_COUNT : integer := CLK_FREQUENCY / SCK_FREQUENCY - 1;
   constant SCK_DOWN_COUNT : integer := (SCK_MAX_COUNT + 1) / 2;  -- count at which sck falls
   signal sck_count : integer;
   signal sck_rising, sck_falling : boolean;  -- true if sck will rise/fall on the next clock cycle
   signal sck_rose : boolean;  -- true if sck rose on the last clock cycle
begin

   process (reset, clk)
   begin
      if reset = '1' then
         state <= ST_RESET;
      elsif rising_edge(clk) then
         case state is
            when ST_RESET =>
               state <= ST_READY;
            when ST_READY =>
               if enable = '1' then
                  mosi_data <= tx_data;
                  bits_left <= 8;
                  sck_count <= SCK_DOWN_COUNT;
                  state <= ST_SENDING;
               end if;
            when ST_SENDING =>
               -- generate sck
               sck_rising <= false;
               sck_falling <= false;
               if sck_count = SCK_MAX_COUNT then
                  sck <= '1';
                  sck_count <= 0;
                  sck_rising <= true;
               elsif sck_count = SCK_DOWN_COUNT then
                  sck <= '0';
                  sck_falling <= true;
                  sck_count <= sck_count + 1;
               else
                  sck_count <= sck_count + 1;
               end if;
               
               if sck_rising then
                  sck_rose <= true;
               else
                  sck_rose <= false;
               end if;

               if sck_rising then
                  -- get data from miso;
                  rx_data <= rx_data(6 downto 0) & miso;
                  
                  bits_left <= bits_left - 1;
               end if;
               
               -- put the next value on mosi
               if sck_rose then
                  mosi_data <= mosi_data(6 downto 0) & '1';
               end if;
               
               if sck_falling and (bits_left = 0) then
                  state <= ST_READY;
               end if;
            when others =>
               state <= ST_RESET;
         end case;
      end if;
   end process;
   
   mosi <= mosi_data(7);
   ready <= '1' when state = ST_READY else '0';
end Behavioral;
