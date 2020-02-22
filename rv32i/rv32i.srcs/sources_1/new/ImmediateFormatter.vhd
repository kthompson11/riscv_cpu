----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/03/2019 09:40:25 AM
-- Design Name: 
-- Module Name: ImmediateFormatter - arch
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
use work.Common.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ImmediateFormatter is
   port ( inst    : in std_logic_vector(31 downto 0);
          format  : in t_imm_type;
          imm_out : out std_logic_vector(31 downto 0));
end ImmediateFormatter;


architecture arch1 of ImmediateFormatter is
   signal immI, immS, immB, immU, immJ : std_logic_vector(31 downto 0);
begin
   -- format immediates
   immI <= (31 downto 11 => inst(31)) & inst(30 downto 20);
   immS <= (31 downto 11 => inst(31)) & inst(30 downto 25) & inst(11 downto 7);
   immB <= (31 downto 12 => inst(31)) & inst(7) & inst(30 downto 25) & inst(11 downto 8) & '0';
   immU <= inst(31 downto 12) & (11 downto 0 => '0');
   immJ <= (31 downto 20 => inst(31)) & inst(19 downto 12) & inst(20) & inst(30 downto 21) & '0';

   -- select which immediate to send to output
   with format select
      imm_out <= immI when IMM_TYPE_I,
                 immS when IMM_TYPE_S,
                 immB when IMM_TYPE_B,
                 immU when IMM_TYPE_U,
                 immJ when IMM_TYPE_J,
                 (others => 'X') when others;
end arch1;
