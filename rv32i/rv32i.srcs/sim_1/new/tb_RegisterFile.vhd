-- tb_RegisterFile.vhd --
-- Testbench for RegisterFile.vhd.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

use work.Common.all;
use work.Common_Sim.all;
use work.MyRandom.all;

entity tb_RegisterFile is
end tb_RegisterFile;

architecture arch1 of tb_RegisterFile is
   component RegisterFile is
      port( CLK   : in std_logic;
            RESET : in std_logic;
            WE    : in std_logic;
            RS1   : in std_logic_vector(4 downto 0);
            RS2   : in std_logic_vector(4 downto 0);
            RD    : in std_logic_vector(4 downto 0);
            WD    : in std_logic_vector(XLEN - 1 downto 0);
            D1    : out std_logic_vector(XLEN - 1 downto 0);
            D2    : out std_logic_vector(XLEN - 1 downto 0));
   end component;
   
   signal CLK : std_logic := '0';
   signal RESET : std_logic := '1';
   signal WE : std_logic;
   signal RS1, RS2, RD : std_logic_vector(4 downto 0);
   signal WD, D1, D2 : std_logic_vector(XLEN - 1 downto 0);
   signal localD1, localD2 : std_logic_vector(XLEN - 1 downto 0);
   type rf_storage is array(1 to N_REGISTERS - 1) of std_logic_vector(XLEN - 1 downto 0);
   signal rf : rf_storage;  -- local copy of the register file
   signal clock_count : integer := 0;
   constant MaxClocks : integer := 10000;
begin
   RegFile : RegisterFile port map (CLK => CLK,
                                    RESET => RESET,
                                    WE => WE,
                                    RS1 => RS1,
                                    RS2 => RS2,
                                    RD => RD,
                                    WD => WD,
                                    D1 => D1,
                                    D2 => D2);


   tb : process (CLK) is
      variable data_read, data_written : std_logic_vector(XLEN - 1 downto 0);
   begin
      if rising_edge(CLK) then
         if (clock_count mod 100 = 1) then
            -- reset the register file every 100 clock cycles
            RESET <= '1';
            WE <= '0';
            RS1 <= (others => '0');
            RS2 <= (others => '0');
            RD <= (others => '0');
            WD <= (others => '0');
            rf <= (others => (others => '0'));
            localD1 <= (others => '0');
            localD2 <= (others => '0');
         elsif (RESET = '1') then
            -- remove the reset if the register file is reset
            RESET <= '0';
         else
            -- test writing and reading random registers
            
            -- write only on even clock cycles
            if (clock_count mod 2 = 0) then
               WE <= '1';
               RD <= randomStdLogicVector(5);
               WD <= randomStdLogicVector(XLEN);
            else
               WE <= '0';
            end if;
            
            -- copy written data into local array
            if (WE = '1' and not (RD = "00000")) then
               rf(to_integer(unsigned(RD))) <= WD;
            end if;
            
            -- read data from D1
            RS1 <= randomStdLogicVector(5);
            if (unsigned(RS1) = 0) then
               localD1 <= (others => '0');
            else
               localD1 <= rf(to_integer(unsigned(RS1)));
            end if;
            
            -- read data from D2
            RS2 <= randomStdLogicVector(5);
            if (unsigned(RS2) = 0) then
               localD2 <= (others => '0');
            else
               localD2 <= rf(to_integer(unsigned(RS2)));
            end if;
            
            -- check for errors when register file is not reset and at
            -- least one clock cycle has passed after reset (so that '-' disappears)
            if (RESET = '0' and (D1(0) /= '-')) then
               assert (localD1 = D1)
               report "Discrepency on data port 1." severity error;
               assert (localD2 = D2)
               report "Discrepency on data port 2." severity error;
            end if;
         end if;
      end if;
   end process tb;
   
   
   clk_process : process is
   begin
      while (clock_count < MaxClocks) loop
         CLK <= '0';
         wait for SIM_CLOCK_PERIOD / 2;
         CLK <= '1';
         wait for SIM_CLOCK_PERIOD / 2;
         clock_count <= clock_count + 1;
      end loop;
      
      wait; -- end the simulation   
   end process;
      
end arch1;
