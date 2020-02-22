-- CompareALU.vhd --
-- Describes the unit responsible for comparison instructions.
-- TODO: fill out interface here
-- TODO: implement new cmp ops

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Common.all;

entity CompareALU is
   port ( cmp_enable : in std_logic;
          cmp_op     : in t_cmp_op;
          op1        : in std_logic_vector(31 downto 0);
          op2        : in std_logic_vector(31 downto 0);
          res        : out std_logic);
end CompareALU;

architecture arch1 of CompareALU is

begin
   CMP : process (all) is
   begin
      if cmp_enable = '1' then
         if cmp_op = CMP_OP_BEQ then
            if (op1 = op2) then
               res <= '1';
            else
               res <= '0';
            end if;
         elsif cmp_op = CMP_OP_BNE then
            if (op1 /= op2) then
               res <= '1';
            else
               res <= '0';
            end if;
         elsif cmp_op = CMP_OP_BLT then
            if (signed(op1) < signed(op2)) then
               res <= '1';
            else
               res <= '0';
            end if;
         elsif cmp_op = CMP_OP_BLTU then
            if (unsigned(op1) < unsigned(op2)) then
               res <= '1';
            else
               res <= '0';
            end if;
         elsif cmp_op = CMP_OP_BGE then
            if (signed(op1) >= signed(op2)) then
               res <= '1';
            else
               res <= '0';
            end if;
         elsif cmp_op = CMP_OP_BGEU then
            if (unsigned(op1) >= unsigned(op2)) then
               res <= '1';
            else
               res <= '0';
            end if;
         elsif cmp_op = CMP_OP_TRUE then
            res <= '1';
         elsif cmp_op = CMP_OP_FALSE then
            res <= '0';
         else
            res <= '-';
            report "Error - This code should never be reached." severity error;
         end if;
      else
         res <= '0';
      end if;
   end process CMP;

end arch1;
