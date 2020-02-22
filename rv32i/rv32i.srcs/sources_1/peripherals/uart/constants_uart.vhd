
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.CLK_FREQUENCY;

package constants_uart is
   constant UART_BAUD_RATE : integer := 9600;
   constant UART_PACKET_LENGTH : integer := 10;  -- 8N1
   
   -- address offsets
   constant ADDRESS_OFFSET_SIZE                   : integer := 8;
   constant UART_OFFSET_READ_BYTES_AVAIL  : std_logic_vector(ADDRESS_OFFSET_SIZE - 1 downto 0) := X"00";
   constant UART_OFFSET_READ_WORD         : std_logic_vector(ADDRESS_OFFSET_SIZE - 1 downto 0) := X"04";
   constant UART_OFFSET_READ_HALF         : std_logic_vector(ADDRESS_OFFSET_SIZE - 1 downto 0) := X"08";
   constant UART_OFFSET_READ_BYTE         : std_logic_vector(ADDRESS_OFFSET_SIZE - 1 downto 0) := X"0C";
   constant UART_OFFSET_WRITE_BYTES_AVAIL : std_logic_vector(ADDRESS_OFFSET_SIZE - 1 downto 0) := X"10";
   constant UART_OFFSET_WRITE             : std_logic_vector(ADDRESS_OFFSET_SIZE - 1 downto 0) := X"14";
end constants_uart;


package body constants_uart is
end constants_uart;
