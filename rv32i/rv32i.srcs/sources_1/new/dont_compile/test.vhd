----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/12/2019 12:50:40 PM
-- Design Name: 
-- Module Name: test - Behavioral
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

use work.Common_Memory.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test is
   port (
      clk            : in     std_logic;
      reset          : in     std_logic;
      ready          : out    std_logic;
      cache_op       : in     t_cache_op;
      
      -- ports for memory read/write
      mem_address    : out    std_logic_vector(32 - 1 downto 0);
      -- ports for memory write back
      mem_wb_done    : in     std_logic;
      mem_wb_needed  : out    std_logic;     -- indicates that a writeback is required before a load/store can proceed
      mem_wb_data    : out    std_logic_vector(32 - 1 downto 0);
      -- ports for memory load
      mem_ld_done    : in     std_logic;
      mem_ld_needed  : out    std_logic;
      mem_ld_data    : in     std_logic_vector(32 - 1 downto 0);
      
      -- ports for hart store/load
      address        : in     std_logic_vector(32 - 1 downto 0);
      hart_st_data   : in     std_logic_vector(32 - 1 downto 0);
      hart_ld_data   : out    std_logic_vector(32 - 1 downto 0)
   );
end test;

architecture Behavioral of test is
   component generic_cache is
      generic (
         N_ENTRIES      : integer;                 -- number of entries; must be power of 2
         DATA_LENGTH    : integer;                 -- length of the data stored in the cache
         ADDRESS_LENGTH : integer
      );
      port (
         clk            : in     std_logic;
         reset          : in     std_logic;
         ready          : out    std_logic;
         cache_op       : in     t_cache_op;
         
         -- ports for memory read/write
         mem_address    : out    std_logic_vector(ADDRESS_LENGTH - 1 downto 0);
         -- ports for memory write back
         mem_wb_done    : in     std_logic;
         mem_wb_needed  : out    std_logic;     -- indicates that a writeback is required before a load/store can proceed
         mem_wb_data    : out    std_logic_vector(DATA_LENGTH - 1 downto 0);
         -- ports for memory load
         mem_ld_done    : in     std_logic;
         mem_ld_needed  : out    std_logic;
         mem_ld_data    : in     std_logic_vector(DATA_LENGTH - 1 downto 0);
         
         -- ports for hart store/load
         address        : in     std_logic_vector(ADDRESS_LENGTH - 1 downto 0);
         hart_st_data   : in     std_logic_vector(DATA_LENGTH - 1 downto 0);
         hart_ld_data   : out    std_logic_vector(DATA_LENGTH - 1 downto 0)
      );
   end component;
begin
   t : generic_cache
      generic map (
         N_ENTRIES => 64,
         DATA_LENGTH => 32,
         ADDRESS_LENGTH => 32
      )
      port map (
         clk,
         reset,
         ready,
         cache_op,
         mem_address,
         mem_wb_done,
         mem_wb_needed,
         mem_wb_data,
         mem_ld_done,
         mem_ld_needed,
         mem_ld_data,
         address,
         hart_st_data,
         hart_ld_data
      );

end Behavioral;
