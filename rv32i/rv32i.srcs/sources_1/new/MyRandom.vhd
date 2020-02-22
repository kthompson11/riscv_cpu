-- MyRandom.vhd --
-- Contains functions to aid in the generation of random integers and std_logic_vectors.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

package MyRandom is
   type random_generator is protected
      impure function randomInteger(minValue : integer;
                                    maxValue : integer)
                                    return integer;
      impure function randomStdLogicVector(width : integer)
                                           return std_logic_vector;
   end protected random_generator;
end MyRandom;

package body MyRandom is
   type random_generator is protected body
      variable seed1 : integer := 134;  -- placeholder value for seed1
      variable seed2 : integer := 744;  -- placeholder value for seed2
   
      impure function randomInteger(minValue : integer;
                                    maxValue : integer)
                                    return integer is
         variable x : real;
         variable n : integer;
      begin
         uniform(seed1, seed2, x);  -- store a pseudorandom real number in x
         n := integer(x * real(maxValue - minValue)) + minValue;
         return n;
      end randomInteger;
   
      impure function randomStdLogicVector(width : integer)
                                           return std_logic_vector is
         variable bitsLeft : integer := width;
         variable result : std_logic_vector(width - 1 downto 0);
         constant MaxChunkSize : integer := 16;  -- number of bits to process at each step
         variable chunkSize : integer;
         variable partialResult : std_logic_vector(MaxChunkSize - 1 downto 0);
      begin
         while (bitsLeft > 0) loop
            if (bitsLeft < MaxChunkSize) then
               chunkSize := bitsLeft;
            else
               chunkSize := MaxChunkSize;
            end if;
               
            bitsLeft := bitsLeft - chunkSize;
            
            partialResult(chunkSize - 1 downto 0) := std_logic_vector(to_unsigned(randomInteger(0, (2 ** chunkSize) - 1), chunkSize));
            result(bitsLeft + chunkSize - 1 downto bitsLeft) := partialResult(chunkSize - 1 downto 0);
         end loop;
         
         return result;
      end randomStdLogicVector;
   end protected body random_generator;
end MyRandom;
