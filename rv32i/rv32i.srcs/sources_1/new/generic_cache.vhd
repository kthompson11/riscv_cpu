
-- Implements a generic 2-way cache with a 4-byte cache line.

-- TODO: implement flush for flush.i instruction if needed

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.Common.all;
use work.Common_Memory.all;
use work.tools.ceil_log2;


entity generic_cache is
   generic (
      N_ENTRIES      : integer := 128;                 -- number of entries; must be power of 2
      DATA_LENGTH    : integer := XLEN;                 -- length of the data stored in the cache
      ADDRESS_LENGTH : integer := PHYS_ADDR_WIDTH
   );
   port (
      clk            : in     std_logic;
      reset          : in     std_logic;
      flush          : in     std_logic;
      
      enable         : in     std_logic;
      ready          : out    std_logic;  -- indicates cache is ready to receive commands
      done           : out    std_logic;  -- asserted for one cycle when a cache op completes
      cache_op_i       : in     t_mem_op;
      cacheable       : in     std_logic;  --  enables cacheing for the given address
      
      address_i        : in     std_logic_vector(ADDRESS_LENGTH - 1 downto 0);  -- always 4-byte (1 word) aligned
      st_data_i  : in     std_logic_vector(DATA_LENGTH - 1 downto 0);
      st_mask_i  : in     std_logic_vector(DATA_LENGTH / 8 - 1 downto 0);  -- masked (set) bytes are written
      ld_data   : out    std_logic_vector(DATA_LENGTH - 1 downto 0);
      
      -- ports for storing/loading to/from memory
      mem_wren          : out    std_logic;  -- when asserted, the memory op is a store
      mem_en            : out    std_logic;
      mem_ready         : in     std_logic;
      mem_done          : in     std_logic;  -- asserted for one cycle when a memory operation completes
      mem_addr          : out    std_logic_vector(ADDRESS_LENGTH - 1 downto 0);
      mem_st_data       : out    std_logic_vector(DATA_LENGTH - 1 downto 0);
      mem_st_mask       : out    std_logic_vector(DATA_LENGTH / 8 - 1 downto 0);
      mem_ld_data       : in    std_logic_vector(DATA_LENGTH - 1 downto 0)
   );
end generic_cache;


architecture Behavioral of generic_cache is
   -- constants
   constant ADDR_ALIGN   : integer := 2;  -- 4-byte aligned address
   constant N_WAYS       : integer := 2;
   constant N_CACHE_SETS : integer := N_ENTRIES / N_WAYS;       -- number of cache sets
   constant N_INDEX_BITS : integer := ceil_log2(N_CACHE_SETS);  -- number of bits used to index the cache entry
   constant TAG_LENGTH   : integer := ADDRESS_LENGTH - N_INDEX_BITS - ADDR_ALIGN; 
   
   type t_cache_entry is record
      valid       : std_logic;
      dirty       : std_logic;
      vbytes      : std_logic_vector(DATA_LENGTH / 8 - 1 downto 0);
      tag         : std_logic_vector(TAG_LENGTH - 1 downto 0);
      data        : std_logic_vector(DATA_LENGTH - 1 downto 0);
   end record t_cache_entry;
   
   function to_cache_entry(valid : std_logic;
                           dirty : std_logic;
                           vbytes : std_logic_vector;
                           tag : std_logic_vector;
                           data : std_logic_vector)
                           return t_cache_entry is
      variable res : t_cache_entry;
   begin
      res.valid := valid;
      res.dirty := dirty;
      res.vbytes := vbytes;
      res.tag := tag;
      res.data := data;
      
      return res;
   end function to_cache_entry;
   
   -- cache entry array types
   type t_status_bytes_array is array(integer range <>) of std_logic_vector(DATA_LENGTH / 8 - 1 downto 0);
   type t_tag_array is array(integer range <>) of std_logic_vector(TAG_LENGTH - 1 downto 0);
   type t_data_array is array(integer range <>) of std_logic_vector(DATA_LENGTH - 1 downto 0);
   type t_lru_array is array(integer range <>) of integer range 0 to N_WAYS - 1;
   
   -- cache entry signals
   signal valid_array0, valid_array1 : std_logic_vector(0 to N_CACHE_SETS - 1);
   signal dirty_array0, dirty_array1 : std_logic_vector(0 to N_CACHE_SETS - 1);
   signal vbytes_array0, vbytes_array1 : t_status_bytes_array(0 to N_CACHE_SETS - 1);
   signal tag_array0, tag_array1 : t_tag_array(0 to N_CACHE_SETS - 1);
   signal data_array0, data_array1 : t_data_array(0 to N_CACHE_SETS - 1);
   signal lru_array : t_lru_array(0 to N_CACHE_SETS - 1);
   
   type t_cache_set is array(0 to N_WAYS - 1) of t_cache_entry;
   signal indexed_set : t_cache_set;
   signal entry : t_cache_entry;
   
   type t_cache_state is (ST_RESET, ST_READY, ST_DONE, ST_CACHE_LOOKUP, ST_CACHE_DECODE, 
                          ST_CACHE_ST, ST_LD_START, ST_LD_WAIT, ST_FLUSH, ST_FLUSH_LOOKUP, 
                          ST_FLUSH_ST, ST_DIRECT_LD_START, ST_DIRECT_LD_WAIT, ST_DIRECT_ST);
   signal state, next_state : t_cache_state;
   
   signal tag_match : boolean;  -- true when an entry is in the cache
   signal fully_valid : boolean;  -- true if all bytes in the entry are valid
   signal wb_needed : boolean;  -- true when the lru entry of the indexed set is dirty and no tag match
   signal has_dirty_entry : boolean;  -- true if at least one entry is dirty
   
   -- output registers
   signal ld_data_reg : std_logic_vector(DATA_LENGTH - 1 downto 0);
   
   constant ALL_VBYTES_VALID : std_logic_vector(DATA_LENGTH / 8 - 1 downto 0) := (others => '1');
   signal tag : std_logic_vector(TAG_LENGTH - 1 downto 0);
   signal lookup_index : integer range 0 to 2**N_INDEX_BITS - 1;
   signal dirty_index : integer range 0 to 2**N_INDEX_BITS - 1;
   signal i_set : integer range 0 to 2**N_INDEX_BITS - 1;
   signal lru : integer range 0 to N_WAYS - 1;
   signal i_way_match : integer range 0 to N_WAYS - 1;
   signal i_way : integer range 0 to N_WAYS - 1;
   signal entry_address : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   
   signal cache_op : t_mem_op;
   signal address : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal st_data : std_logic_vector(DATA_LENGTH - 1 downto 0);
   signal st_mask : std_logic_vector(DATA_LENGTH / 8 - 1 downto 0);
begin
   get_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            next_state <= ST_READY;
         when ST_READY | ST_DONE =>
            if flush = '1' then
               next_state <= ST_FLUSH;
            elsif enable = '1' then
               if cacheable = '1' then
                  next_state <= ST_CACHE_LOOKUP;
               else
                  -- perform a direct store/load
                  if cache_op_i = MEM_STORE then
                     next_state <= ST_DIRECT_ST;
                  else  -- cache_op_i = MEM_LOAD
                     next_state <= ST_DIRECT_LD_START;
                  end if;
               end if;
            else
               next_state <= ST_READY;
            end if;
         when ST_CACHE_LOOKUP =>
            next_state <= ST_CACHE_DECODE;
         when ST_CACHE_DECODE =>
            if cache_op = MEM_STORE then
               if not tag_match and wb_needed then
                  next_state <= ST_CACHE_ST;
               else
                  next_state <= ST_DONE;
               end if;
            else  -- MEM_LOAD
               if tag_match then
                  if fully_valid then
                     next_state <= ST_DONE;
                  else
                     next_state <= ST_LD_START;
                  end if;
               else
                  if wb_needed then
                     next_state <= ST_CACHE_ST;
                  else
                     next_state <= ST_LD_START;
                  end if;
               end if;
            end if;
         when ST_CACHE_ST =>
            if (mem_ready = '1') and (cache_op = MEM_LOAD) then
               next_state <= ST_LD_START;
            elsif (mem_ready = '1') and (cache_op = MEM_STORE) then
               next_state <= ST_DONE;
            else
               next_state <= ST_CACHE_ST;
            end if;
         when ST_LD_START =>
            if mem_ready = '1' then
               next_state <= ST_LD_WAIT;
            else
               next_state <= ST_LD_START;
            end if;
         when ST_LD_WAIT =>
            if mem_done = '1' then
               next_state <= ST_DONE;
            else
               next_state <= ST_LD_WAIT;
            end if;
         when ST_DIRECT_ST =>
            if mem_ready = '1' then
               next_state <= ST_DONE;
            else
               next_state <= ST_DIRECT_ST;
            end if;
         when ST_DIRECT_LD_START =>
            if mem_ready = '1' then
               next_state <= ST_DIRECT_LD_WAIT;
            else
               next_state <= ST_DIRECT_LD_START;
            end if;
         when ST_DIRECT_LD_WAIT =>
            if mem_done = '1' then
               next_state <= ST_DONE;
            else
               next_state <= ST_DIRECT_LD_WAIT;
            end if;
         when others =>
            next_state <= ST_READY;
      end case;
   end process get_next_state;
   
   advance_state : process (reset, clk)
   begin
      if reset = '1' then
         state <= ST_RESET;
      elsif rising_edge(clk) then
         state <= next_state;
      end if;
   end process advance_state;
   
   lock_inputs : process (clk)
   begin
      if rising_edge(clk) then
         if next_state = ST_CACHE_LOOKUP then
            address <= address_i;
            cache_op <= cache_op_i;
            st_data <= st_data_i;
            st_mask <= st_mask_i;
            i_set <= lookup_index;
         end if;
      end if;
   end process lock_inputs;
   
   lookup_entry : process (clk)
   begin
      if rising_edge(clk) then
         if next_state = ST_CACHE_LOOKUP then
            lru <= lru_array(lookup_index);
            indexed_set(0) <= to_cache_entry(valid_array0(lookup_index),
                                             dirty_array0(lookup_index),
                                             vbytes_array0(lookup_index),
                                             tag_array0(lookup_index),
                                             data_array0(lookup_index));
            indexed_set(1) <= to_cache_entry(valid_array1(lookup_index),
                                             dirty_array1(lookup_index),
                                             vbytes_array1(lookup_index),
                                             tag_array1(lookup_index),
                                             data_array1(lookup_index));
         elsif next_state = ST_FLUSH_LOOKUP then
            null; -- NOTE: fill out flush lookup if needed
         end if;
      end if;
   end process lookup_entry;
   
   
   search_set : process (all)
   begin
      -- no latches
      tag_match <= false;
      fully_valid <= false;
      i_way_match <= 0;
   
      -- search the set for the requested address
      for i in 0 to N_WAYS - 1 loop
         if (indexed_set(i).tag = tag) and (indexed_set(i).valid = '1') then
            i_way_match <= i;
            tag_match <= true;
            
            if indexed_set(i).vbytes = ALL_VBYTES_VALID then
               fully_valid <= true;
            end if;
            
            exit;
         end if;
      end loop;
   end process search_set;
   
   
   modify_cache : process (clk)
      variable new_entry : t_cache_entry;
   begin
      if reset = '1' then
         for i in 0 to N_CACHE_SETS - 1 loop
            valid_array0(i) <= '0';
            valid_array1(i) <= '0';
            lru_array(i) <= 0;
         end loop;
      elsif rising_edge(clk) then
         if (state = ST_FLUSH_ST) and (next_state = ST_FLUSH) then
            -- set the flushed entry to not dirty
            -- NOTE: fill out flush logic if needed
            null;
         elsif ((cache_op = MEM_STORE) and (((state = ST_CACHE_ST) and (next_state = ST_DONE)) or
                                            ((state = ST_CACHE_DECODE) and (next_state = ST_DONE)))) then
            -- fill out default new entry if it was a complete miss
            if not tag_match then
               new_entry.valid := '1';
               new_entry.dirty := '0';
               new_entry.vbytes := (others => '0');
               new_entry.tag := tag;
               new_entry.data := (others => '0');
            else
               new_entry := entry;
            end if;
            
            -- write the indicated bytes into the cache
            for i in 0 to st_mask'length - 1 loop
               if st_mask(i) = '1' then
                  new_entry.dirty := '1';
                  new_entry.vbytes(i) := '1';
                  new_entry.data((i + 1) * 8 - 1  downto i * 8) := st_data((i + 1) * 8 - 1  downto i * 8);
               end if;
            end loop;
            
            -- write new entry to ram
            if i_way = 0 then
               valid_array0(i_set)  <= new_entry.valid;
               dirty_array0(i_set)  <= new_entry.dirty;
               vbytes_array0(i_set) <= new_entry.vbytes;
               tag_array0(i_set)    <= new_entry.tag;
               data_array0(i_set)   <= new_entry.data;
               lru_array(i_set) <= 1;
            else
               valid_array1(i_set)  <= new_entry.valid;
               dirty_array1(i_set)  <= new_entry.dirty;
               vbytes_array1(i_set) <= new_entry.vbytes;
               tag_array1(i_set)    <= new_entry.tag;
               data_array1(i_set)   <= new_entry.data;
               lru_array(i_set) <= 0;
            end if;
         elsif (cache_op = MEM_LOAD) and (((state = ST_CACHE_DECODE) and (next_state = ST_DONE)) or
                                          ((state = ST_LD_WAIT) and (next_state = ST_DONE))) then

            if state = ST_LD_WAIT then
               if not tag_match then
                  -- set up new entry
                  new_entry.valid  := '1';
                  new_entry.dirty  := '0';
                  new_entry.vbytes := (others => '1');
                  new_entry.tag    := tag;
                  new_entry.data   := mem_ld_data;
               else
                  new_entry := entry;
                  for i in 0 to new_entry.vbytes'length - 1 loop
                     if new_entry.vbytes(i) = '0' then
                        new_entry.data((i + 1) * 8 - 1 downto i * 8) := mem_ld_data((i + 1) * 8 - 1 downto i * 8);
                     end if;
                  end loop;
               end if;
              
               if i_way = 0 then
                  valid_array0(i_set)  <= new_entry.valid;
                  dirty_array0(i_set)  <= new_entry.dirty;
                  vbytes_array0(i_set) <= new_entry.vbytes;
                  tag_array0(i_set)    <= new_entry.tag;
                  data_array0(i_set)   <= new_entry.data;
               else
                  valid_array1(i_set)  <= new_entry.valid;
                  dirty_array1(i_set)  <= new_entry.dirty;
                  vbytes_array1(i_set) <= new_entry.vbytes;
                  tag_array1(i_set)    <= new_entry.tag;
                  data_array1(i_set)   <= new_entry.data;
               end if;
            end if;
            
            -- set lru
            if i_way = 0 then
               lru_array(i_set) <= 1;
            else
               lru_array(i_set) <= 0;
            end if;
            
            -- set ld_data
            if state = ST_CACHE_DECODE then
               -- get data from cache
               ld_data_reg <= indexed_set(i_way).data;
            else
               -- get data from memory
               ld_data_reg <= new_entry.data;
            end if;
         end if;
      end if;
   end process modify_cache;
   
   -- outputs
   ld_data <= ld_data_reg when state = ST_DONE else (others => 'X');
   
   done <= '1' when state = ST_DONE else '0';
   ready <= '1' when (state = ST_READY) or (state = ST_DONE) else '0';
   mem_wren <= '1' when state = ST_CACHE_ST else '0';
   mem_en <= '1' when (state = ST_CACHE_ST) or (state = ST_LD_START) else '0';
   mem_addr <= entry_address when state = ST_CACHE_ST else
               address when state = ST_LD_START else
               address when (state = ST_DIRECT_ST) or (state = ST_DIRECT_LD_START) else
               (others => 'X');
   mem_st_data <= entry.data when state = ST_CACHE_ST else
                  st_data when state = ST_DIRECT_ST else
                  (others => 'X');
   mem_st_mask <= entry.vbytes when state = ST_CACHE_ST else
                  st_mask when state = ST_DIRECT_ST else
                  (others => 'X');
   
   entry_address <= entry.tag & std_logic_vector(to_unsigned(i_set, N_INDEX_BITS)) & (ADDR_ALIGN - 1 downto 0 => '0');
   
   lookup_index <= to_integer(unsigned(address_i(N_INDEX_BITS + ADDR_ALIGN - 1 downto ADDR_ALIGN)));
   tag <= address(ADDRESS_LENGTH - 1 downto ADDRESS_LENGTH - TAG_LENGTH);
   wb_needed <= true when (not tag_match) and (indexed_set(lru).dirty = '1') else false;
   i_way <= i_way_match when tag_match else lru;
   entry <= indexed_set(i_way);
   
end Behavioral;
