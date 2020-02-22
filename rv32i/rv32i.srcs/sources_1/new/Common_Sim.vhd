-- Common_Sim.vhd --
-- Contains constants/types common to testbenches.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.all;


package Common_Sim is
   constant SIM_CLOCK_PERIOD : time := 10 ns;
   procedure setOpcode(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant opcode : in std_logic_vector(INSTRUCTION_OPCODE_LENGTH - 1 downto 0));
   procedure setRD(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                   constant rd : in std_logic_vector(INSTRUCTION_RD_LENGTH - 1 downto 0));
   procedure setFunct3(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant funct3 : in std_logic_vector(INSTRUCTION_FUNCT3_LENGTH - 1 downto 0));
   procedure setFunct7(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant funct7 : in std_logic_vector(INSTRUCTION_FUNCT7_LENGTH - 1 downto 0));
   procedure setRS1(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                    constant rs1 : in std_logic_vector(INSTRUCTION_RS1_LENGTH - 1 downto 0));
   procedure setRS2(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                    constant rs2 : in std_logic_vector(INSTRUCTION_RS2_LENGTH - 1 downto 0));
   
end Common_Sim;

package body Common_Sim is
   procedure setOpcode(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant opcode : in std_logic_vector(INSTRUCTION_OPCODE_LENGTH - 1 downto 0)) is
   begin
      instruction(INSTRUCTION_OPCODE_HIGH downto INSTRUCTION_OPCODE_LOW) <= opcode;
   end setOpcode;
   
   procedure setRD(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                   constant rd : in std_logic_vector(INSTRUCTION_RD_LENGTH - 1 downto 0)) is
   begin
      instruction(INSTRUCTION_RD_HIGH downto INSTRUCTION_RD_LOW) <= rd;
   end setRD;
   
   procedure setFunct3(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant funct3 : in std_logic_vector(INSTRUCTION_FUNCT3_LENGTH - 1 downto 0)) is
   begin
      instruction(INSTRUCTION_FUNCT3_HIGH downto INSTRUCTION_FUNCT3_LOW) <= funct3;
   end setFunct3;
   
   procedure setFunct7(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant funct7 : in std_logic_vector(INSTRUCTION_FUNCT7_LENGTH - 1 downto 0)) is
   begin
      instruction(INSTRUCTION_FUNCT7_HIGH downto INSTRUCTION_FUNCT7_LOW) <= funct7;
   end setFunct7;
   
   procedure setRS1(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant rs1 : in std_logic_vector(INSTRUCTION_RS1_LENGTH - 1 downto 0)) is
   begin
      instruction(INSTRUCTION_RS1_HIGH downto INSTRUCTION_RS1_LOW) <= rs1;
   end setRS1;
                       
   procedure setRS2(signal instruction : inout std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
                       constant rs2 : in std_logic_vector(INSTRUCTION_RS2_LENGTH - 1 downto 0)) is
   begin
      instruction(INSTRUCTION_RS2_HIGH downto INSTRUCTION_RS2_LOW) <= rs2;
   end setRS2;
end Common_Sim;
