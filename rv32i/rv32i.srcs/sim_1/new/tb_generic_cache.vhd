
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common_Memory.all;





entity tb_generic_cache is
end tb_generic_cache;


architecture Behavioral of tb_generic_cache is
   constant DATA_LENGTH : integer := 8;
   constant ADDRESS_LENGTH : integer := 8;
   constant N_ENTRIES : integer := 8;

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
   
   signal clk, reset, ready : std_logic;
   signal cache_op : t_cache_op;
   signal mem_wb_done : std_logic;
   signal mem_wb_needed : std_logic;
   signal mem_wb_data : std_logic_vector(DATA_LENGTH - 1 downto 0);
   signal mem_address : std_logic_vector(ADDRESS_LENGTH - 1 downto 0);
   signal mem_ld_done : std_logic;
   signal mem_ld_needed : std_logic;
   signal mem_ld_data : std_logic_vector(DATA_LENGTH - 1 downto 0);
   signal address : std_logic_vector(ADDRESS_LENGTH - 1 downto 0);
   signal hart_st_data : std_logic_vector(DATA_LENGTH - 1 downto 0);
   signal hart_ld_data : std_logic_vector(DATA_LENGTH - 1 downto 0);
   signal testing_done : boolean;
begin
   UUT : generic_cache
      generic map (
         N_ENTRIES => N_ENTRIES,
         DATA_LENGTH => DATA_LENGTH,
         ADDRESS_LENGTH => ADDRESS_LENGTH
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
      
      test : process
      begin
         cache_op <= CACHE_OP_NONE;
         reset <= '1';
         wait until rising_edge(clk);
         reset <= '0';
         wait until rising_edge(clk) and (ready = '1');
         
         -- write to an address
         address <= X"43";
         hart_st_data <= X"35";
         cache_op <= CACHE_OP_STORE;
         wait until rising_edge(clk) and (ready = '1');
         
         -- write to same set as previous write
         address <= X"33";
         hart_st_data <= X"76";
         cache_op <= CACHE_OP_STORE;
         wait until rising_edge(clk) and (ready = '1');
         
         -- store with a cache hit
         address <= X"43";
         hart_st_data <= X"53";
         cache_op <= CACHE_OP_STORE;
         wait until rising_edge(clk) and (ready = '1');
         
         -- store with a cache miss + no vacancy
         address <= X"53";
         hart_st_data <= X"99";
         cache_op <= CACHE_OP_STORE;
         wait until rising_edge(clk) and (ready = '1');
         
         -- load from an address not in the cache
         address <= X"41";
         cache_op <= CACHE_OP_LOAD;
         mem_ld_data <= X"F4";
         wait until rising_edge(clk) and (ready = '1');
         
         -- load an address in the same set
         address <= X"61";
         cache_op <= CACHE_OP_LOAD;
         mem_ld_data <= X"FF";
         wait until rising_edge(clk) and (ready = '1');
         
         -- load an entry already in the cache
         address <= X"41";
         cache_op <= CACHE_OP_LOAD;
         wait until rising_edge(clk) and (ready = '1');
         
         -- load an entry + no vacancy
         address <= X"83";
         mem_ld_data <= X"AA";
         cache_op <= CACHE_OP_LOAD;
         wait until rising_edge(clk) and (ready = '1');
         
         cache_op <= CACHE_OP_NONE;
         wait until rising_edge(clk);
         wait until rising_edge(clk);
         cache_op <= CACHE_OP_FLUSH;
         wait until rising_edge(clk);
         cache_op <= CACHE_OP_NONE;
         wait until rising_edge(clk) and (ready = '1');
         
         testing_done <= true;
         wait;
      end process test;
      
      handle_wb : process
      begin
         wait until rising_edge(clk) and (mem_wb_needed = '1');
         mem_wb_done <= '1';
         wait until rising_edge(clk);
         mem_wb_done <= '0';
      end process handle_wb;
      
      handle_ld : process
      begin
         wait until rising_edge(clk) and (mem_ld_needed = '1');
         mem_ld_done <= '1';
         wait until rising_edge(clk);
         mem_ld_done <= '0';
      end process handle_ld;
      
      clk_proc : process
      begin
         if testing_done then
            wait;
         end if;
         
         clk <= '1';
         wait for 5 ns;
         clk <= '0';
         wait for 5 ns;
      end process clk_proc;


end Behavioral;
