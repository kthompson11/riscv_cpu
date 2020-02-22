
library ieee;
use ieee.std_logic_1164.all;


entity crc7_generator is
   port (
      clk            : in     std_logic;
      reset_crc      : in     std_logic;
      enable         : in     std_logic;
      data_in        : in     std_logic;
      crc_result     : out    std_logic_vector(6 downto 0)
   );
end crc7_generator;


architecture Behavioral of crc7_generator is
   constant CRC_LENGTH : integer := 7;
   constant POLYNOMIAL : std_logic_vector(CRC_LENGTH - 1 downto 0) := "0001001";
begin
   gen_crc : process (clk, reset_crc)
   begin
      if reset_crc = '1' then
         crc_result <= (others => '0');
      elsif rising_edge(clk) and (enable = '1') then
         crc_result(0) <= crc_result(CRC_LENGTH - 1) xor data_in;
         for i in 1 to CRC_LENGTH - 1 loop
            if POLYNOMIAL(i) = '1' then
               crc_result(i) <= crc_result(i - 1) xor data_in xor crc_result(CRC_LENGTH - 1);
            else
               crc_result(i) <= crc_result(i - 1);
            end if;
         end loop;
      end if;
   end process gen_crc;

end Behavioral;
