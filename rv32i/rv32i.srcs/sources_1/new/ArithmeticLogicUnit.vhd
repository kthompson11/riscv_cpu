-- ArithmeticLogicUnit.vhd --
-- Describes the arithmetic logic unit.
-- TODO: describe the interface here

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Common.all;

entity ArithmeticLogicUnit is
   port ( alu_op : in t_alu_op;
          imm10  : in std_logic;  -- TODO: remove this
          op1    : in std_logic_vector(31 downto 0);
          op2    : in std_logic_vector(31 downto 0);
          res    : out std_logic_vector(31 downto 0));
end ArithmeticLogicUnit;

architecture arch1 of ArithmeticLogicUnit is
   signal res_addsub, res_slt, res_and, res_or, res_xor, res_sll, res_srlsra : std_logic_vector(31 downto 0);
begin
   -- add/sub
   res_addsub <= std_logic_vector(unsigned(op1) + unsigned(op2)) when alu_op = ALU_OP_ADD else
                 std_logic_vector(unsigned(op1) - unsigned(op2));
                 
   -- slt/sltu
   slt : process (all) is
   begin
      if alu_op = ALU_OP_SLT then
         if signed(op1) < signed(op2) then
            res_slt <= (31 downto 1 => '0') & '1';
         else
            res_slt <= (others => '0');
         end if;
      elsif alu_op = ALU_OP_SLTU then
         if unsigned(op1) < unsigned(op2) then
            res_slt <= (31 downto 1 => '0') & '1';
         else
            res_slt <= (others => '0');
         end if;
      else
         res_slt <= (others => '-');
      end if;
   end process slt;
   
   -- and
   res_and <= op1 and op2;
   
   -- or
   res_or <= op1 or op2;
   
   -- xor
   res_xor <= op1 xor op2;
   
   -- sll
   res_sll <= std_logic_vector(shift_left(unsigned(op1), to_integer(unsigned(op2(4 downto 0)))));
   
   -- srl/sra
   res_srlsra <= std_logic_vector(shift_right(unsigned(op1), to_integer(unsigned(op2(4 downto 0))))) when alu_op = ALU_OP_SRL else
                 std_logic_vector(shift_right(signed(op1), to_integer(unsigned(op2(4 downto 0)))));
   
   -- assign internal signals to output result       
   res <= res_addsub when (alu_op = ALU_OP_ADD) or (alu_op = ALU_OP_SUB) else
          res_slt    when (alu_op = ALU_OP_SLT) or (alu_op = ALU_OP_SLTU) else
          res_and    when alu_op = ALU_OP_AND else
          res_or     when alu_op = ALU_OP_OR else
          res_xor    when alu_op = ALU_OP_XOR else
          res_sll    when alu_op = ALU_OP_SLL else
          res_srlsra when (alu_op = ALU_OP_SRL) or (alu_op = ALU_OP_SRA) else
          (others => '-');
end arch1;
