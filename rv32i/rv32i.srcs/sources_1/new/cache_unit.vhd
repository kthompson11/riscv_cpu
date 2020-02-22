-- Implements a unified TLB/cache.

-- TODO: make processing data_funct3 cleaner

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Common.all;
use work.Common_Memory.all;
use work.common_exceptions.all;


entity cache_unit is
   generic (
      N_TLB_ENTRIES    : integer := 128;
      N_CACHE_ENTRIES  : integer := 128
   );
   port (
      clk               : in     std_logic;
      reset             : in     std_logic;
      
      hart_priv         : in     t_hart_priv;
      sstatus_sum       : in     std_logic;
      sstatus_mxr       : in     std_logic;
      satp              : in     std_logic_vector(XLEN - 1 downto 0);
      
      -- data store/load
      data_addr         : in     std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
      data_funct3       : in     std_logic_vector(2 downto 0);
      data_op           : t_mem_op;
      data_rd           : out    std_logic_vector(XLEN - 1 downto 0);
      data_wd           : in     std_logic_vector(XLEN - 1 downto 0);
      data_en           : in     std_logic;
      data_ready        : out    std_logic;
      
      -- instruction store/load
      ifetch_addr       : in     std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
      ifetch_rd         : out    std_logic_vector(XLEN - 1 downto 0);
      ifetch_en         : in     std_logic;
      ifetch_ready      : out    std_logic;
      
      -- i/o to memory system
      mem_addr          : out    std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
      mem_rd            : in     std_logic_vector(XLEN - 1 downto 0);
      mem_wd            : out    std_logic_vector(XLEN - 1 downto 0);
      mem_wd_mask       : out    std_logic_vector(XLEN / 8 - 1 downto 0);  -- masked (set) bytes are written
      mem_wren          : out    std_logic;  -- when set, memory operation is a write
      mem_en            : out    std_logic;  -- start a memory operation
      mem_ready         : in     std_logic;
      mem_done          : in     std_logic;
      
      -- fence ports
      fence_en          : in     std_logic;
      fence_ready       : out    std_logic;
      fence_done        : out    std_logic;
      sfence_vma        : in     std_logic;
      fence_i           : in     std_logic;
      
      rs1               : in     std_logic_vector(4 downto 0);
      rs2               : in     std_logic_vector(4 downto 0);
      
      -- exceptions
      exception         : out    std_logic;
      exception_code    : out    t_exception_code
   );
end cache_unit;


architecture Behavioral of cache_unit is
   component tlb_sv32 is
      generic (
         N_TLB_ENTRIES     : integer := 128
      );
      port (
         clk               : in     std_logic;
         reset             : in     std_logic;
         
         enable            : in     std_logic;
         ready             : out    std_logic;
         done              : out    std_logic;  -- asserted for one cycle when translation is completed
         cacheable         : out    std_logic;
         vaddr             : in     std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
         paddr             : out    std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
         
         tlb_op            : in     t_tlb_op;
         hart_priv         : in     t_hart_priv;
         sstatus_sum       : in     std_logic;
         sstatus_mxr       : in     std_logic;
         satp              : in     std_logic_vector(XLEN - 1 downto 0);
         rs1               : in     std_logic_vector(INSTRUCTION_RS1_LENGTH - 1 downto 0);
         rs2               : in     std_logic_vector(INSTRUCTION_RS2_LENGTH - 1 downto 0);
         sfence_vma        : in     std_logic;
         
         -- storing and loading PTEs
         mem_wren          : out    std_logic;  -- when asserted, the memory op is a store
         mem_en            : out    std_logic;
         mem_ready         : in     std_logic;
         mem_done          : in     std_logic;  -- asserted for one cycle when an operation completes
         mem_st_data       : out    std_logic_vector(XLEN - 1 downto 0);
         mem_st_mask       : out    std_logic_vector(XLEN / 8 - 1 downto 0);
         mem_ld_data       : in    std_logic_vector(XLEN - 1 downto 0);
         
         -- exceptions 
         exception         : out    std_logic;
         exception_code    : out    t_exception_code
      );
   end component;
   
   component generic_cache is
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
         mem_st_data       : out    std_logic_vector(XLEN - 1 downto 0);
         mem_st_mask       : out    std_logic_vector(XLEN / 8 - 1 downto 0);
         mem_ld_data       : in    std_logic_vector(DATA_LENGTH - 1 downto 0)
      );
   end component;
   
   -- tlb signals
   signal tlb_enable : std_logic;
   signal tlb_ready : std_logic;
   signal tlb_done : std_logic;
   signal tlb_cacheable : std_logic;
   signal tlb_vaddr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal tlb_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal tlb_op : t_tlb_op;
   signal tlb_mem_wren : std_logic;
   signal tlb_mem_en : std_logic;
   signal tlb_mem_ready : std_logic;
   signal tlb_mem_done : std_logic;
   signal tlb_mem_st_data : std_logic_vector(XLEN - 1 downto 0);
   signal tlb_mem_st_mask : std_logic_vector(XLEN / 8 - 1 downto 0);
   signal tlb_mem_ld_data : std_logic_vector(XLEN - 1 downto 0);
   
   -- cache signals
   signal cache_flush : std_logic;
   signal cache_enable : std_logic;
   signal cache_ready : std_logic;
   signal cache_done : std_logic;
   signal cache_op : t_mem_op;
   signal cache_addr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal cache_st_data : std_logic_vector(XLEN - 1 downto 0);
   signal cache_st_mask : std_logic_vector(XLEN / 8 - 1 downto 0);
   signal cache_ld_data : std_logic_vector(XLEN - 1 downto 0);
   
   -- pending event signals
   signal pending_rw, pending_if : boolean;
   signal pending_rw_addr, pending_if_addr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal pending_rw_tlb_op, pending_if_tlb_op : t_tlb_op;
   signal pending_rw_op, pending_if_op : t_mem_op;
   signal pending_rw_width, pending_if_width : t_mem_op_width;
   signal pending_rw_uload, pending_if_uload : boolean;
   signal pending_rw_wd, pending_if_wd : std_logic_vector(XLEN - 1 downto 0);
   
   -- current operation signals
   constant DOUBLE_MASK_WIDTH : integer := 2 * WORD_WIDTH / 8;
   constant BASE_MASK_SB : std_logic_vector(DOUBLE_MASK_WIDTH - 1 downto 0) := "00000001";
   constant BASE_MASK_SH : std_logic_vector(DOUBLE_MASK_WIDTH - 1 downto 0) := "00000011";
   constant BASE_MASK_SW : std_logic_vector(DOUBLE_MASK_WIDTH - 1 downto 0) := "00001111";
   signal base_mask : std_logic_vector(DOUBLE_MASK_WIDTH - 1 downto 0);
   signal base_data : std_logic_vector(2 * XLEN - 1 downto 0);
   signal rotate_amount : natural;
   signal double_st_data : std_logic_vector(2 * XLEN - 1 downto 0);
   signal double_st_mask : std_logic_vector(DOUBLE_MASK_WIDTH - 1 downto 0);
   -- selected pending op
   signal sel_vaddr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal sel_tlb_op : t_tlb_op;
   signal sel_op : t_mem_op;
   signal sel_op_width : t_mem_op_width;
   signal sel_op_uload : boolean;
   signal sel_st_data : std_logic_vector(XLEN - 1 downto 0);
   -- current operation signals
   signal curr_vaddr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal curr_tlb_op : t_tlb_op;
   signal curr_op : t_mem_op;
   signal curr_op_width : t_mem_op_width;
   signal curr_op_uload : boolean;
   signal curr_st_data : std_logic_vector(XLEN - 1 downto 0);
   signal curr_st_mask : std_logic_vector(XLEN / 8 - 1 downto 0);
   
   signal ld_data : std_logic_vector(XLEN - 1 downto 0);
   
   signal vaddr_lower, vaddr_upper : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal st_data_lower, st_data_upper : std_logic_vector(XLEN - 1 downto 0);
   signal st_mask_lower, st_mask_upper : std_logic_vector(XLEN / 8 - 1 downto 0);
   signal ld_data_lower, ld_data_upper : std_logic_vector(XLEN - 1 downto 0);
   signal double_ld_data : std_logic_vector(2 * XLEN - 1 downto 0);
   
   -- states
   type t_cache_unit_state is (ST_RESET, ST_READY, ST_FENCE_DONE, ST_IFETCH_DONE, ST_DATA_DONE, 
                               ST_TLB_START, ST_TLB_WAIT, ST_CACHE_START, ST_CACHE_WAIT, ST_FENCE);
   signal state, next_state : t_cache_unit_state;
   
   signal current_op_is_ifetch : boolean;
   signal two_ops_required : boolean;
   signal executing_upper_op : boolean;
begin

   -- queue up requests for the cache_unit state machine to process
   handle_requests : process (reset, clk)
   begin
      if reset = '1' then
         pending_rw <= false;
         pending_if <= false;
      elsif rising_edge(clk) then
         -- get the next read/write request
         if (data_en = '1') and (not pending_rw) then
            pending_rw <= true;
            pending_rw_addr <= data_addr;
            if data_op = MEM_LOAD then
               pending_rw_tlb_op <= TLB_LOAD;
            else
               pending_rw_tlb_op <= TLB_STORE;
            end if;
            pending_rw_op <= data_op;
            -- get the access width
            case data_funct3 is
               when LOAD_FUNCT3_LB | LOAD_FUNCT3_LBU =>
                  pending_rw_width <= MEM_WIDTH_BYTE;
               when LOAD_FUNCT3_LH | LOAD_FUNCT3_LHU =>
                  pending_rw_width <= MEM_WIDTH_HALF;
               when LOAD_FUNCT3_LW =>
                  pending_rw_width <= MEM_WIDTH_WORD;
               when others =>
                  pending_rw_width <= MEM_WIDTH_WORD;
            end case;
            -- check if load is unsigned
            case data_funct3 is
               when LOAD_FUNCT3_LBU | LOAD_FUNCT3_LHU =>
                  pending_rw_uload <= true;
               when others =>
                  pending_rw_uload <= false;
            end case;
            pending_rw_wd <= data_wd;
         elsif (state = ST_CACHE_WAIT) and (next_state = ST_DATA_DONE) then
            pending_rw <= false;
         end if;
         
         -- get the next ifetch request
         if (ifetch_en = '1') and (not pending_if) then
            pending_if <= true;
            pending_if_addr <= ifetch_addr;
            pending_if_tlb_op <= TLB_IFETCH;
            pending_if_op <= MEM_LOAD;
            pending_if_width <= MEM_WIDTH_WORD;
            pending_if_uload <= false;
            pending_if_wd <= (others => '-');  -- not used
         elsif (state = ST_CACHE_WAIT) and (next_state = ST_IFETCH_DONE) then
            pending_if <= false;
         end if;
      end if;
   end process handle_requests;
   
   set_intermediates : process (all)
   begin
   end process set_intermediates;
   
   -- select which pending operation to transform as input for the tlb/cache
   select_operation : process (all)
   begin
      if current_op_is_ifetch then
         -- selected op <= ifetch signals
         sel_vaddr <= pending_if_addr;
         sel_tlb_op <= pending_if_tlb_op;
         sel_op <= pending_if_op;
         sel_op_width <= pending_if_width;
         sel_op_uload <= pending_if_uload;
         sel_st_data <= pending_if_wd;
      else
         -- selected op <= data signals
         sel_vaddr <= pending_rw_addr;
         sel_tlb_op <= pending_rw_tlb_op;
         sel_op <= pending_rw_op;
         sel_op_width <= pending_rw_width;
         sel_op_uload <= pending_rw_uload;
         sel_st_data <= pending_rw_wd;
      end if;
   end process select_operation;
   
   -- transfrom selected operation signals into inputs for the tlb/cache
   two_ops_required <= true when (sel_vaddr(1 downto 0) /= "00") and (sel_op_width = MEM_WIDTH_WORD) else
                       true when (sel_vaddr(1 downto 0) = "11") and (sel_op_width = MEM_WIDTH_HALF) else
                       false;
   vaddr_lower <= sel_vaddr(VIRT_ADDR_WIDTH - 1 downto 2) & "00";
   vaddr_upper <= std_logic_vector(unsigned(vaddr_lower) + WORD_WIDTH / 8);
   
   base_mask <= BASE_MASK_SW when sel_op_width = MEM_WIDTH_WORD else
                BASE_MASK_SH when sel_op_width = MEM_WIDTH_HALF else
                BASE_MASK_SB;
   rotate_amount <= to_integer(unsigned(sel_vaddr(1 downto 0)));
   double_st_mask <= std_logic_vector(rotate_left(unsigned(base_mask), rotate_amount));
   st_mask_lower <= double_st_mask(DOUBLE_MASK_WIDTH / 2 - 1 downto 0);
   st_mask_upper <= double_st_mask(DOUBLE_MASK_WIDTH - 1 downto DOUBLE_MASK_WIDTH / 2);
   base_data <= (WORD_WIDTH - 1 downto 0 => '-') & sel_st_data;
   double_st_data <= std_logic_vector(shift_left(unsigned(base_data), rotate_amount * 8));
   st_data_lower <= double_st_data(XLEN - 1 downto 0);
   st_data_upper <= double_st_data(2 * XLEN - 1 downto XLEN);
   
   -- choose current transformed inputs to tlb/cache
   curr_tlb_op <= sel_tlb_op;
   curr_op <= sel_op;
   curr_op_uload <= sel_op_uload;
   curr_op_width <= sel_op_width;
   process (all)
   begin
      if executing_upper_op then
         curr_vaddr <= vaddr_upper;
         curr_st_data <= st_data_upper;
         curr_st_mask <= st_mask_upper;
      else
         curr_vaddr <= vaddr_lower;
         curr_st_data <= st_data_lower;
         curr_st_mask <= st_mask_lower;
      end if;
   end process;
   
   -- load data logic
   double_ld_data(2 * XLEN - 1 downto XLEN) <= ld_data_upper;
   double_ld_data(XLEN - 1 downto 0) <= ld_data_lower;
   calc_ld_data : process (all)
      variable shifted_rd : std_logic_vector(2 * XLEN - 1 downto 0);
      variable lower_rd : std_logic_vector(XLEN - 1 downto 0);
      variable ext_bit : std_logic;  -- sign extension bit
   begin
      shifted_rd := std_logic_vector(shift_right(unsigned(double_ld_data), rotate_amount * 8));
      lower_rd := shifted_rd(XLEN - 1 downto 0);
      if curr_op_uload then
         ext_bit := '0';
      else
         if curr_op_width = MEM_WIDTH_HALF then
            ext_bit := lower_rd(HALF_WIDTH - 1);
         elsif curr_op_width = MEM_WIDTH_BYTE then
            ext_bit := lower_rd(BYTE_WIDTH - 1);
         else  -- MEM_WIDTH_WORD (ext_bit won't be used)
            ext_bit := '-';
         end if;
      end if;
      if curr_op_width = MEM_WIDTH_HALF then
         ld_data(XLEN - 1 downto HALF_WIDTH) <= (others => ext_bit);
         ld_data(HALF_WIDTH - 1 downto 0) <= lower_rd(HALF_WIDTH - 1 downto 0);
      elsif curr_op_width = MEM_WIDTH_BYTE then
         ld_data(XLEN - 1 downto BYTE_WIDTH) <= (others => ext_bit);
         ld_data(BYTE_WIDTH - 1 downto 0) <= lower_rd(BYTE_WIDTH - 1 downto 0);
      else
         ld_data <= lower_rd;
      end if;
   end process calc_ld_data;
   data_rd <= ld_data when (state = ST_DATA_DONE) else (others => 'X');
   ifetch_rd <= ld_data when (state = ST_IFETCH_DONE) else (others => 'X');
   get_ld_from_cache : process (clk)
   begin
      if rising_edge(clk) then
         if (state = ST_CACHE_WAIT) and (cache_ready = '1') then
            if executing_upper_op then
               ld_data_upper <= cache_ld_data;
            else
               ld_data_lower <= cache_ld_data;
            end if;
         end if;
      end if;
   end process get_ld_from_cache;
   
   -- cache unit status outputs
   data_ready <= '1' when (not pending_rw) else '0';
   ifetch_ready <= '1' when (not pending_if) else '0';
   fence_ready <= '1' when (tlb_ready = '1') and (cache_ready = '1') else '0';
   fence_done <= '1' when state = ST_FENCE_DONE else '0';
   
   -- tlb inputs
   tlb_enable <= '1' when state = ST_TLB_START else '0';
   tlb_op <= curr_tlb_op;
   tlb_vaddr <= curr_vaddr;
   
   tlb_mem_ready <= cache_ready;
   tlb_mem_done <= cache_done;
   tlb_mem_ld_data <= cache_ld_data;
   
   -- cache inputs
   cache_enable <= '1' when state = ST_CACHE_START else tlb_mem_en;
   cache_op <= pending_rw_op when (state = ST_CACHE_START) and (not current_op_is_ifetch) else
               pending_if_op when (state = ST_CACHE_START) and current_op_is_ifetch else
               MEM_STORE when tlb_mem_wren = '1' else
               MEM_LOAD;
   cache_addr <= tlb_paddr;
   cache_st_data <= tlb_mem_st_data when state = ST_TLB_WAIT else
                    curr_st_data;
   cache_st_mask <= tlb_mem_st_mask when state = ST_TLB_WAIT else
                    curr_st_mask;
                    
   boolean_control : process (clk)
   begin
      if rising_edge(clk) then
         if next_state = ST_TLB_START then
            if state = ST_CACHE_WAIT then
               -- continuing previous operation with the upper half
               executing_upper_op <= true;
            else
               -- starting a new operation
               executing_upper_op <= false;
               if pending_rw then
                  current_op_is_ifetch <= false;
               else
                  current_op_is_ifetch <= true;
               end if;
            end if;
         end if;
      end if;
   end process boolean_control;

   ---------------------------------------------------------------------------------------------------------------------
   ----------------------------------------------  state control  ------------------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
   
   get_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            next_state <= ST_READY;
         when ST_READY | ST_FENCE_DONE | ST_IFETCH_DONE | ST_DATA_DONE =>
            if fence_en = '1' then
               next_state <= ST_FENCE;
            elsif pending_rw or pending_if then
               next_state <= ST_TLB_START;
            else
               next_state <= ST_READY;
            end if;
         when ST_TLB_START =>
            if tlb_ready = '1' then
               next_state <= ST_TLB_WAIT;
            else
               next_state <= ST_TLB_START;
            end if;
         when ST_TLB_WAIT =>
            if tlb_ready = '1' then
               next_state <= ST_CACHE_START;
            else
               next_state <= ST_TLB_WAIT;
            end if;
         when ST_CACHE_START =>
            if cache_ready = '1' then
               next_state <= ST_CACHE_WAIT;
            else
               next_state <= ST_CACHE_START;
            end if;
         when ST_CACHE_WAIT =>
            if cache_ready = '1' then
               if two_ops_required and (not executing_upper_op) then
                  next_state <= ST_TLB_START;
               elsif current_op_is_ifetch then
                  next_state <= ST_IFETCH_DONE;
               else
                  next_state <= ST_DATA_DONE;
               end if;
            else
               next_state <= ST_CACHE_WAIT;
            end if;
         when ST_FENCE =>
            if (tlb_ready = '1') and (cache_ready = '1') then
               next_state <= ST_FENCE_DONE;
            else
               next_state <= ST_FENCE;
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

   ---------------------------------------------------------------------------------------------------------------------
   --------------------------------------------  component instantiation  ----------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------

   tlb : tlb_sv32
   generic map (
      N_TLB_ENTRIES => N_TLB_ENTRIES
   )
   port map (
      clk => clk,
      reset => reset,
      enable => tlb_enable,
      ready => tlb_ready,
      done => tlb_done,
      cacheable => tlb_cacheable,
      vaddr => tlb_vaddr,
      paddr => tlb_paddr,
      tlb_op => tlb_op,
      hart_priv => hart_priv,
      sstatus_sum => sstatus_sum,
      sstatus_mxr => sstatus_mxr,
      satp => satp,
      rs1 => rs1,
      rs2 => rs2,
      sfence_vma => sfence_vma,
      mem_wren => tlb_mem_wren,
      mem_en => tlb_mem_en,
      mem_ready => tlb_mem_ready,
      mem_done => tlb_mem_done,
      mem_st_data => tlb_mem_st_data,
      mem_st_mask => tlb_mem_st_mask,
      mem_ld_data => tlb_mem_ld_data,
      exception => exception,
      exception_code => exception_code
   );
   
   cache : generic_cache
   generic map (
      N_ENTRIES => N_CACHE_ENTRIES,
      DATA_LENGTH => XLEN,
      ADDRESS_LENGTH => PHYS_ADDR_WIDTH
   )
   port map (
      clk => clk,
      reset => reset,
      flush => fence_i,
      enable => cache_enable,
      ready => cache_ready,
      done => cache_done,
      cache_op_i => cache_op,
      cacheable => tlb_cacheable,
      address_i => cache_addr,
      st_data_i => cache_st_data,
      st_mask_i => cache_st_mask,
      ld_data => cache_ld_data,
      mem_wren => mem_wren,
      mem_en => mem_en,
      mem_ready => mem_ready,
      mem_done => mem_done,
      mem_addr => mem_addr,
      mem_st_data => mem_wd,
      mem_st_mask => mem_wd_mask,
      mem_ld_data => mem_rd
   );
end Behavioral;
   