----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2019 08:48:00 PM
-- Design Name: 
-- Module Name: uart_tx_control - arch
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Common.CLK_FREQUENCY;
use work.constants_uart.all;

entity uart_tx_control is
   port(TX       : out std_logic;
        TX_READY : out std_logic;
        TX_START  : in std_logic;
        TX_DATA  : in std_logic_vector(7 downto 0);
        CLK      : in std_logic;
        RESET    : in std_logic);
end uart_tx_control;

architecture arch of uart_tx_control is
   type TX_STATE_TYPE is (TX_RESET, TX_RDY, TX_LOAD_BIT, TX_HOLD);
   constant COUNT_MAX : integer := CLK_FREQUENCY / UART_BAUD_RATE - 1;  -- TODO: replace numerator with a clock rate constant
   constant MAX_INDEX : integer := UART_PACKET_LENGTH - 1;
   
   signal tx_state : TX_STATE_TYPE;
   signal tx_count : integer range 0 to COUNT_MAX;
   signal tx_bits_sent : integer range 0 to UART_PACKET_LENGTH;
   signal tx_packet : std_logic_vector(UART_PACKET_LENGTH - 1 downto 0);
begin

   tx_state_process : process (RESET, CLK)
   begin
      if RESET = '1' then
         TX_STATE <= TX_RESET;
      elsif rising_edge(CLK) then
         case tx_state is
            when TX_RESET =>
               tx_state <= TX_RDY;
            when TX_RDY =>
               if TX_START = '1' then
                  tx_state <= TX_LOAD_BIT;
               else
                  tx_state <= TX_RDY;
               end if;
            when TX_LOAD_BIT =>
               tx_state <= TX_HOLD;
            when TX_HOLD =>
               if tx_count = COUNT_MAX then
                  if tx_bits_sent = UART_PACKET_LENGTH then
                     tx_state <= TX_RDY;
                  else
                     tx_state <= TX_LOAD_BIT;
                  end if;
               else
                  tx_state <= TX_HOLD;
               end if;
            when others =>  -- never executed
               tx_state <= TX_RDY;
         end case;
      end if;
   end process tx_state_process;
   
   tx_load_bit_process : process (CLK)
   begin
      if rising_edge(CLK) then
         if tx_state = TX_RDY then
            TX <= '1';
         elsif tx_state = TX_LOAD_BIT then
            TX <= tx_packet(tx_bits_sent);
         end if;
      end if;
   end process tx_load_bit_process;
   
   tx_count_process : process (CLK)
   begin
      if rising_edge(CLK) then
         if tx_state = TX_HOLD then
            tx_count <= tx_count + 1;
         else
            tx_count <= 0;
         end if;
      end if;
   end process tx_count_process;
   
   tx_bits_sent_process : process (CLK)
   begin
      if rising_edge(CLK) then
         if tx_state = TX_RDY then
            tx_bits_sent <= 0;
         elsif tx_state = TX_LOAD_BIT then
            tx_bits_sent <= tx_bits_sent + 1;
         end if;
      end if;
   end process tx_bits_sent_process;
   
   tx_packet_process : process (CLK)
   begin
      if rising_edge(CLK) then
         if (tx_state = TX_RDY) and (TX_START = '1') then
            tx_packet <= '1' & TX_DATA & '0';
         end if;
      end if;
   end process tx_packet_process;
   
   -- handle TX_READY output
   TX_READY <= '1' when tx_state = TX_RDY else
             '0';
end arch;
