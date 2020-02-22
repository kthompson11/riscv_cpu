----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/10/2019 08:52:47 AM
-- Design Name: 
-- Module Name: ProgramCounter - arch1
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ProgramCounter is
   port ( clk     : in std_logic;
          reset   : in std_logic;
          next_pc : in std_logic_vector(31 downto 0);
          pc_out  : out std_logic_vector(31 downto 0));
end ProgramCounter;

architecture arch1 of ProgramCounter is
   signal current_instruction : std_logic_vector(31 downto 0);
begin
   PC: process (clk, reset) is
   begin
      if reset = '0' then
         if rising_edge(clk) then
            current_instruction <= next_pc;
         end if;
      else
         -- async reset
         current_instruction <= (others => '0');
      end if;
   end process PC;
   
   pc_out <= current_instruction;

end arch1;
