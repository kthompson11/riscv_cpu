-- RegisterFile.vhd --
-- Describes the operation of the RISCV register file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Common.all;

entity RegisterFile is
   port( CLK   : in std_logic;
         RESET : in std_logic; --active high
         WE    : in std_logic;
         RS1   : in std_logic_vector (4 downto 0);             -- read source register 1
         RS2   : in std_logic_vector  (4 downto 0);            -- read source register 2
         RD    : in std_logic_vector (4 downto 0);             -- write destination register
         WD    : in std_logic_vector (XLEN - 1 downto 0);      -- data to write
         D1    : out std_logic_vector (XLEN - 1 downto 0);     -- data read from source register 1
         D2    : out std_logic_vector (XLEN - 1 downto 0));    -- data read from source register 2
end RegisterFile;

architecture arch1 of RegisterFile is
   type reg_file_storage is array (1 to N_REGISTERS - 1) of std_logic_vector (XLEN - 1 downto 0);
   signal reg_file : reg_file_storage;
   
   signal iRS1, iRS2, iRD : integer range 0 to N_REGISTERS - 1;
begin
   iRS1 <= to_integer(unsigned(RS1));
   iRS2 <= to_integer(unsigned(RS2));
   iRD <= to_integer(unsigned(RD));
   
   read_write: process (CLK, RESET)
   begin
      if RESET = '0' then
      
         -- process read 1
         if rising_edge(CLK) then
            if iRS1 = 0 then
               D1 <= (others => '0');
            else
               D1 <= reg_file(iRS1);
            end if;
         end if;
         
         -- process read 2
         if rising_edge(CLK) then
            if iRS2 = 0 then
               D2 <= (others => '0');
            else
               D2 <= reg_file(iRS2);
            end if;
         end if;
         
         --process write
         if rising_edge(CLK) and WE = '1' then
           if iRD /= 0 then
               reg_file(iRD) <= WD;
            end if;
         end if;
         
      else
         
         -- process async reset
         reg_file <= (others => (others => '0'));
         D1 <= (others => '-');
         D2 <= (others => '-');
 
      end if;
   end process read_write;
end arch1;
