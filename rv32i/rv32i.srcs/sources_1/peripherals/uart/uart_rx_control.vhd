----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2019 05:05:57 PM
-- Design Name: 
-- Module Name: uart_control - arch
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

entity uart_rx_control is
   port(RX       : in std_logic;
        RX_READY : out std_logic;
        RX_DATA  : out std_logic_vector(7 downto 0);
        CLK      : in std_logic;
        RESET    : in std_logic);
end uart_rx_control;

architecture arch of uart_rx_control is
   type RX_STATE_TYPE is (RX_RESET, RX_IDLE, RX_LOAD_BIT, RX_WAIT, RX_DATA_READY, RX_PRE_WAIT);
   constant COUNT_MAX : integer := CLK_FREQUENCY / UART_BAUD_RATE - 1;  -- TODO: replace numerator with a clock rate constant
   constant MAX_INDEX : integer := UART_PACKET_LENGTH - 1;
   
   signal rx_state : RX_STATE_TYPE;
   signal rx_count : integer range 0 to COUNT_MAX;
   signal rx_bits_received : integer range 0 to UART_PACKET_LENGTH - 1;
   signal rx_packet : std_logic_vector(UART_PACKET_LENGTH - 1 downto 0);
   signal data_out : std_logic_vector(7 downto 0);
   
   -- RX synchronization
   signal synch_regs : std_logic_vector(1 downto 0);
   signal synch_rx : std_logic;
begin
   -- Handle the receiving state.
   rx_state_process : process (RESET, CLK)
   begin
      if RESET = '1' then
         rx_state <= RX_RESET;
      elsif rising_edge(CLK) then
         case rx_state is
         when RX_RESET =>
            rx_state <= RX_IDLE;
         when RX_IDLE =>
            if synch_rx = '0' then
               rx_state <= RX_PRE_WAIT;
            end if;
         when RX_PRE_WAIT =>
            if rx_count = COUNT_MAX / 2 then
               rx_state <= RX_LOAD_BIT;
            end if;
         when RX_LOAD_BIT =>
            if rx_bits_received = UART_PACKET_LENGTH - 1 then
               rx_state <= RX_DATA_READY;
            else
               rx_state <= RX_WAIT;
            end if;
         when RX_WAIT =>
            if rx_count = COUNT_MAX then
               rx_state <= RX_LOAD_BIT;
            else
               rx_state <= RX_WAIT;
            end if;
         when RX_DATA_READY =>
            rx_state <= RX_IDLE;
         when others =>
            rx_state <= RX_IDLE;
         end case;
      end if;
   end process rx_state_process;
   
   rx_load_bit_process : process (CLK)
   begin
      if rising_edge(CLK) then
         if (rx_state = RX_LOAD_BIT) then
            rx_packet <= synch_rx & rx_packet(UART_PACKET_LENGTH - 1 downto 1);
         end if;
      end if;
   end process rx_load_bit_process;
   
   rx_count_process : process (CLK)
   begin
      if rising_edge(CLK) then
         if (rx_state = RX_WAIT) or (rx_state = RX_PRE_WAIT) then
            rx_count <= rx_count + 1;
         else
            rx_count <= 0;
         end if;
      end if;
   end process rx_count_process;
   
   rx_bits_received_process : process (CLK)
   begin
      if rising_edge(CLK) then
         if rx_state = RX_LOAD_BIT then
            rx_bits_received <= rx_bits_received + 1;
         elsif rx_state = RX_IDLE then
            rx_bits_received <= 0;
         end if;
      end if;
   end process rx_bits_received_process;
   
   -- synchonize the asynchronous RX input
   rx_synch_process : process (CLK) is
   begin
      if rising_edge(CLK) then
         synch_regs(0) <= RX;
         synch_regs(1) <= synch_regs(0);
      end if;
   end process rx_synch_process;
   synch_rx <= synch_regs(1);
   
   -- handle RX_READY output
   RX_READY <= '1' when rx_state = RX_DATA_READY else
               '0';
               
   
   RX_DATA <= rx_packet(8 downto 1);
end arch;
