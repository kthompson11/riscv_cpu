library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package tools is
   function ceil_log2(N : integer) return integer;
   function replicate_stl(vec : std_logic_vector; N : integer) return std_logic_vector;
end tools;

package body tools is
   function ceil_log2(N : integer) return integer is
   begin
      return integer(ceil(log2(real(N))));
   end ceil_log2;
   
   
   function replicate_stl(vec: std_logic_vector; N: integer) return std_logic_vector is
      constant len : integer := vec'length;
      variable count : integer := 0;
      variable result : std_logic_vector(len * N - 1 downto 0);
   begin
      for i in 0 to N - 1 loop
         result((i + 1) * len - 1 downto i * len) := vec;
      end loop;
      
      return result;
   end function;
end tools;