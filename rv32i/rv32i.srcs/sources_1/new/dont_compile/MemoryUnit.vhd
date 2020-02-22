-- MemoryUnit.vhd --
-- This device provides an interface for accessing RAM and MMIO.
-- In addition it provides address translation and caching.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.all;

entity MemoryUnit is
port (
   clk      : in     std_logic;
   WE       : in     std_logic;
   start    : in     std_logic;                             -- starts a read/write
   rw_type  : in     MEM_RW_TYPE;                           -- data or instruction access
   ready    : out    std_logic;                             -- indicates the device is ready (read/write is done)
   funct3   : in     std_logic_vector(2 downto 0);          -- the type of load/store
   
   -- ports for reading/writing data
   DA       : in     std_logic_vector(XLEN - 1 downto 0);
   RD       : out    std_logic_vector(XLEN - 1 downto 0);   -- read data
   WD       : in     std_logic_vector(XLEN - 1 downto 0);   -- write data
   
   -- ports for reading instructions
   IA       : in     std_logic_vector(XLEN - 1 downto 0);   -- instruction address
   ID       : out    std_logic_vector(XLEN - 1 downto 0)    -- instruction data
   
   -- TODO: add inputs/outputs for AXI4-lite bus
   -- TODO: add inputs/outputs for xilinx memory interface
);
end MemoryUnit;


architecture Behavioral of MemoryUnit is
   type MEMORY_UNIT_STATE is (MEM_UNIT_READY, MEM_UNIT_DTLB_MISS, MEM_UNIT_DCACHE_MISS, MEM_UNIT_ITLB_MISS, MEM_UNIT_ICACHE_MISS);
   signal state : MEMORY_UNIT_STATE;
begin
   proc_next_state : process (clk)
   begin
      if rising_edge(clk) then
--         case state is
--            case MEM_UNIT_READY => 
--         end case;
      end if;
   end process proc_next_state;
   
   

end Behavioral;
