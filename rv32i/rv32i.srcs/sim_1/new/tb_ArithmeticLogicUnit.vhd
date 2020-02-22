----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/08/2019 08:48:49 AM
-- Design Name: 
-- Module Name: tb_ArithmeticLogicUnit - arch1
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
use ieee.math_real.uniform;
use ieee.math_real.floor;

use work.Common.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_ArithmeticLogicUnit is
--  Port ( );
end tb_ArithmeticLogicUnit;

architecture arch1 of tb_ArithmeticLogicUnit is
   component ArithmeticLogicUnit is
      port ( funct3 : in std_logic_vector(2 downto 0);
             imm10  : in std_logic;
             op1    : in std_logic_vector(31 downto 0);
             op2    : in std_logic_vector(31 downto 0);
             res    : out std_logic_vector(31 downto 0));
   end component;
   
   signal operation : std_logic_vector(2 downto 0);
   signal imm10 : std_logic;
   signal op1, op2, res : std_logic_vector(31 downto 0);
begin
   ALU : ArithmeticLogicUnit port map (funct3 => operation,
                                       imm10 => imm10,
                                       op1 => op1,
                                       op2 => op2,
                                       res => res);
   
   tb: process is
      variable seed1, seed2 : positive;
      variable x : real;
      variable n : integer;
      variable check : unsigned (0 to (res'length - 1));
   begin
      seed1 := 183;
      seed2 := 45;
      for funct in 0 to 7 loop
         operation <= std_logic_vector(to_unsigned(funct, operation'length));
         
         for test_count in 0 to 99 loop
            -- generate op1
            uniform(seed1, seed2, x);
            n := integer((x * (2.0 ** (op1'length - 1))));
            op1 <= std_logic_vector(to_unsigned(n, op1'length));
            
            -- generate op2
            uniform(seed1, seed2, x);
            n := integer(floor(x * (2.0 ** (op2'length - 1))));
            op2 <= std_logic_vector(to_unsigned(n, op2'length));
            
            -- assign value for imm10
            if operation = ALU_FUNCTION(ALU_FUNCT_ADDSUB) or operation = ALU_FUNCTION(ALU_FUNCT_SRLSRA) then
               uniform(seed1, seed2, x);
               n := integer(floor(x * 2.0));
               imm10 <= to_unsigned(n, 1)(0);
            end if;
            
            -- check result
            if operation = ALU_FUNCTION(ALU_FUNCT_ADDSUB) then
               if imm10 = '0' then
                  check := unsigned(op1) + unsigned(op2);
                  assert (check = unsigned(res)) report "ADD failure" severity error;
               else
                  check := unsigned(op1) - unsigned(op2);
                  assert (check = unsigned(res)) report "SUB failure" severity error;
               end if;
            elsif operation = ALU_FUNCTION(ALU_FUNCT_SLT) then
               if signed(op1) < signed(op2) then
                  assert (signed(res) = 1) report "SLT failure" severity error;
               else
                  assert (signed(res) = 0) report "SLT failure" severity error;
               end if;
            elsif operation = ALU_FUNCTION(ALU_FUNCT_SLTU) then
               if unsigned(op1) < unsigned(op2) then
                  assert (unsigned(res) = 1) report "SLTU failure" severity error;
               else
                  assert (unsigned(res) = 0) report "SLTU failure" severity error;
               end if;
            elsif operation = ALU_FUNCTION(ALU_FUNCT_AND) then
               assert (res = (op1 and op2)) report "AND failure" severity error;
            elsif operation = ALU_FUNCTION(ALU_FUNCT_OR) then
               assert (res = (op1 or op2)) report "OR failure" severity error;
            elsif operation = ALU_FUNCTION(ALU_FUNCT_XOR) then
               assert (res = (op1 xor op2)) report "XOR failure" severity error;
            elsif operation = ALU_FUNCTION(ALU_FUNCT_SLL) then
               check := shift_left(unsigned(op1), to_integer(unsigned(op2(4 downto 0))));
               assert (check = unsigned(res)) report "SLL failure" severity error;
            elsif operation = ALU_FUNCTION(ALU_FUNCT_SRLSRA) then
               if imm10 = '0' then
                  check := shift_right(unsigned(op1), to_integer(unsigned(op2(4 downto 0))));
                  assert (check = unsigned(res)) report "SRL failure" severity error;
               else
                  check := unsigned(shift_right(signed(op1), to_integer(unsigned(op2(4 downto 0)))));
                  assert (check = unsigned(res)) report "SRA failure" severity error;
               end if;
            end if;
            
            wait for 10 ns;
            
         end loop;
      end loop;
      
      wait; -- end of simulation
   end process tb;

end arch1;
