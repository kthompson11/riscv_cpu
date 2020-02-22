-- TODO: check that there is a pma check when translation is turned off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Common.all;
use work.Common_Memory.all;
use work.common_exceptions.all;
use work.tools.ceil_log2;


entity tlb_sv32 is
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
      mem_st_data       : out    std_logic_vector(XLEN - 1 downto 0);  -- low byte of the PTE
      mem_st_mask       : out    std_logic_vector(XLEN / 8 - 1 downto 0);
      mem_ld_data       : in    std_logic_vector(XLEN - 1 downto 0);
      
      -- exceptions 
      exception         : out    std_logic;
      exception_code    : out    t_exception_code
   );
end tlb_sv32;
 

architecture Behavioral of tlb_sv32 is
   component pma_checker is
      port (
         enable               : in     std_logic;
         address              : in     std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
         tlb_op               : in     t_tlb_op;
         cacheable            : out    std_logic;  -- when '1' indicates that the address should not be cached
         
         except_load          : out    std_logic;
         except_store         : out    std_logic;
         except_ifetch        : out    std_logic
      );
   end component;

   type t_tlb_state is (ST_RESET, ST_READY, ST_TRANS_DONE, ST_LOOKUP, ST_CACHE_DECODE, ST_LD1_START, ST_LD2_START, ST_LD1_WAIT, ST_LD2_WAIT,
                        ST_LD1_DECODE, ST_LD2_DECODE, ST_FLUSH_LOOKUP, ST_FLUSH_DECODE, ST_STORE_PTE);
   signal state, next_state : t_tlb_state;
   
   -- constants
   constant N_WAYS : integer := 2;
   constant N_TLB_SETS : integer := N_TLB_ENTRIES / N_WAYS;
   constant N_INDEX_BITS : integer := ceil_log2(N_TLB_SETS);
   constant PTE_LENGTH : integer := XLEN;
   constant TAG_LENGTH : integer := VIRT_ADDR_WIDTH - SV32_OFFSET_BITS - N_INDEX_BITS;
   
   -- tlb storage
   type t_asid_array is array(integer range <>) of std_logic_vector(SV32_ASID_LEN - 1 downto 0);
   signal asid_array0, asid_array1 : t_asid_array(0 to N_TLB_SETS - 1);
   type t_valid_array is array(integer range <>) of std_logic;
   signal valid_array0, valid_array1 : t_valid_array(0 to N_TLB_SETS - 1);
   type t_lru_array is array(integer range <>) of integer range 0 to N_WAYS - 1;
   signal lru_array : t_lru_array(0 to N_TLB_SETS - 1);
   type t_mtag_array is array(integer range <>) of std_logic_vector(TAG_LENGTH downto 0);  -- megapage & tag
   signal mtag_array0, mtag_array1 : t_mtag_array(0 to N_TLB_SETS - 1);
   type t_pte_array is array(integer range <>) of std_logic_vector(PTE_LENGTH - 1 downto 0);
   signal pte_array0, pte_array1 : t_pte_array(0 to N_TLB_SETS - 1);
   type t_paddr_array is array(integer range <>) of std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal paddr_array0, paddr_array1 : t_paddr_array(0 to N_TLB_SETS - 1);
   
   signal tag : std_logic_vector(TAG_LENGTH - 1 downto 0);
   signal tag_index : integer range 0 to 2**N_INDEX_BITS - 1;
   signal i_set : integer range 0 to 2**N_INDEX_BITS - 1;
   
   -- virtual address signals
   signal vpn1 : std_logic_vector(SV32_VA_VPN1_LEN - 1 downto 0);
   signal vpn0 : std_logic_vector(SV32_VA_VPN0_LEN - 1 downto 0);
   signal offset : std_logic_vector(SV32_OFFSET_BITS - 1 downto 0);
   signal mega_offset : std_logic_vector(SV32_VA_VPN0_HIGH downto 0);
   
   signal i_way_hit : integer range 0 to N_WAYS - 1;
   
   -- satp csr fields
   signal tlb_mode : std_logic;
   signal satp_asid : std_logic_vector(SV32_ASID_LEN - 1 downto 0);
   signal satp_ppn  : std_logic_vector(SATP_PPN_LEN - 1 downto 0);
   
   signal new_pte : std_logic_vector(PTE_LENGTH - 1 downto 0);
   
   signal ld_pte : std_logic_vector(PTE_LENGTH - 1 downto 0);
   
   signal st_data_reg : std_logic_vector(XLEN - 1 downto 0);
   
   -- signals for holding result of cache lookup
   signal lru : integer range 0 to N_WAYS - 1;
   
   signal leaf_pte_found : boolean;
   signal in_cache : boolean;
   signal translation_successful : boolean;
   signal has_exception : boolean;
   signal store_needed : boolean;
   
   -- physical address assignment signals
   signal new_translated_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal new_ld_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal new_st_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal translated_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal ld_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal st_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   
   -- pma
   signal pma_enable : std_logic;
   signal pma_check_addr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal current_op : t_tlb_op;
   
   -- exceptions
   signal pg_fault : std_logic;
   signal access_fault : std_logic;
   signal pg_fault_code : t_exception_code;
   signal access_fault_code : t_exception_code;
   signal i_access_fault : std_logic;
   signal st_access_fault : std_logic;
   signal ld_access_fault : std_logic;
   
   -- sv32 pte record and conversion functions
   type t_sv32_pte is record
      ppn1  : std_logic_vector(11 downto 0);
      ppn0  : std_logic_vector(9 downto 0);
      rsw   : std_logic_vector(1 downto 0);
      d     : std_logic;
      a     : std_logic;
      g     : std_logic;
      u     : std_logic;
      x     : std_logic;
      w     : std_logic;
      r     : std_logic;
      v     : std_logic;
   end record t_sv32_pte;
   
   signal pte : t_sv32_pte;
   
   function to_sv32_pte(constant stv_in : std_logic_vector) return t_sv32_pte is
      variable res : t_sv32_pte;
   begin
      res.ppn1 := stv_in(SV32_PTE_PPN1_HIGH downto SV32_PTE_PPN1_LOW);
      res.ppn0 := stv_in(SV32_PTE_PPN0_HIGH downto SV32_PTE_PPN0_LOW);
      res.rsw := stv_in(SV32_PTE_RSW_HIGH downto SV32_PTE_RSW_LOW);
      res.d := stv_in(SV32_PTE_D);
      res.a := stv_in(SV32_PTE_A);
      res.g := stv_in(SV32_PTE_G);
      res.u := stv_in(SV32_PTE_U);
      res.x := stv_in(SV32_PTE_X);
      res.w := stv_in(SV32_PTE_W);
      res.r := stv_in(SV32_PTE_R);
      res.v := stv_in(SV32_PTE_V);
      return res;
   end to_sv32_pte;
   
   function from_sv32_pte(constant pte_in : t_sv32_pte) return std_logic_vector is
      variable res : std_logic_vector(PTE_LENGTH - 1 downto 0);
   begin
      res(SV32_PTE_PPN1_HIGH downto SV32_PTE_PPN1_LOW) := pte_in.ppn1;
      res(SV32_PTE_PPN0_HIGH downto SV32_PTE_PPN0_LOW) := pte_in.ppn0;
      res(SV32_PTE_RSW_HIGH downto SV32_PTE_RSW_LOW) := pte_in.rsw;
      res(SV32_PTE_D) := pte_in.d;
      res(SV32_PTE_A) := pte_in.a;
      res(SV32_PTE_G) := pte_in.g;
      res(SV32_PTE_U) := pte_in.u;
      res(SV32_PTE_X) := pte_in.x;
      res(SV32_PTE_W) := pte_in.w;
      res(SV32_PTE_R) := pte_in.r;
      res(SV32_PTE_V) := pte_in.v;
      return res;
   end from_sv32_pte;
   
   -- sv32 cache_set and conversion functions
   type t_cache_entry is record  -- the cache data and all of its auxiliary information
      valid    : std_logic;
      megapage : std_logic;
      asid     : std_logic_vector(SV32_ASID_LEN - 1 downto 0);
      tag      : std_logic_vector(TAG_LENGTH - 1 downto 0);
      pte      : t_sv32_pte;
      paddr    : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   end record t_cache_entry;
   type t_cache_set is array(0 to N_WAYS - 1) of t_cache_entry;
   signal indexed_set : t_cache_set;  -- the set that matches the index of the input address
   signal current_cache_entry : t_cache_entry;
   
   function to_cache_entry(constant valid    : std_logic;
                           constant asid     : std_logic_vector(SV32_ASID_LEN - 1 downto 0);
                           constant mtag     : std_logic_vector(TAG_LENGTH downto 0);  -- megapage & tag
                           constant pte      : std_logic_vector(PTE_LENGTH - 1 downto 0);
                           constant paddr    : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0))
                           return t_cache_entry is
      variable res : t_cache_entry;
   begin
      res.valid := valid;
      res.megapage := mtag(TAG_LENGTH);
      res.asid := asid;
      res.tag := mtag(TAG_LENGTH - 1 downto 0);
      res.pte := to_sv32_pte(pte);
      res.paddr := paddr;
      return res;
   end to_cache_entry;
   
begin
   
   decode_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            next_state <= ST_READY;
         when ST_READY | ST_TRANS_DONE =>
            if (enable = '1') and (has_exception = false) then
               next_state <= ST_LOOKUP;
            else
               next_state <= ST_READY;
            end if;
         when ST_LOOKUP =>
            next_state <= ST_CACHE_DECODE;
         when ST_CACHE_DECODE => 
            if has_exception then
               next_state <= ST_READY;
            elsif in_cache then
               if store_needed then
                  next_state <= ST_STORE_PTE;
               else
                  next_state <= ST_READY;
               end if;
            else  -- not in cache
               next_state <= ST_LD1_START;
            end if;
         when ST_LD1_START =>
            if mem_ready = '1' then
               next_state <= ST_LD1_WAIT;
            else
               next_state <= ST_LD1_START;
            end if;
         when ST_LD1_WAIT =>
            if mem_done = '1' then
               next_state <= ST_LD1_DECODE;
            else
               next_state <= ST_LD1_WAIT;
            end if;
         when ST_LD1_DECODE =>
            if leaf_pte_found and not has_exception then
               if store_needed then
                  next_state <= ST_STORE_PTE;
               else
                  next_state <= ST_TRANS_DONE;
               end if;
            elsif has_exception then
               next_state <= ST_READY;
            else
               next_state <= ST_LD2_START;
            end if;
         when ST_LD2_START =>
            if mem_ready = '1' then
               next_state <= ST_LD2_WAIT;
            else
               next_state <= ST_LD2_START;
            end if;
         when ST_LD2_WAIT =>
            if mem_done = '1' then
               next_state <= ST_LD2_DECODE;
            else
               next_state <= ST_LD2_WAIT;
            end if;
         when ST_LD2_DECODE =>
            if has_exception then
               next_state <= ST_READY;
            elsif store_needed then
               next_state <= ST_STORE_PTE;
            else
               next_state <= ST_TRANS_DONE;
            end if;
         when ST_STORE_PTE =>
            if mem_done = '1' then
               next_state <= ST_TRANS_DONE;
            else
               next_state <= ST_STORE_PTE;
            end if;
         when others => 
            next_state <= ST_READY;
      end case;
   end process;
   
   
   advance_state : process (reset, clk)
   begin
      if reset = '1' then
         state <= ST_RESET;
      elsif rising_edge(clk) then
         state <= next_state;
      end if;
   end process advance_state;
   
   
   lock_input_output : process (clk)
   begin
      if rising_edge(clk) then
         -- lock in the tag when starting a translation
         if (state = ST_READY) and (next_state = ST_LOOKUP) then
            tag <= vaddr(VIRT_ADDR_WIDTH - 1 downto VIRT_ADDR_WIDTH - TAG_LENGTH);
         end if;
         
         -- lock in virtual address fields
         if (state = ST_READY) and (next_state = ST_LOOKUP) then
            vpn1 <= vaddr(SV32_VA_VPN1_HIGH downto SV32_VA_VPN1_LOW);
            vpn0 <= vaddr(SV32_VA_VPN0_HIGH downto SV32_VA_VPN0_LOW);
            offset <= vaddr(SV32_VA_OFFSET_HIGH downto 0);
            mega_offset <= vaddr(SV32_VA_VPN0_HIGH downto 0);
         end if;
         
         -- lock in the pte from memory when loading a new pte
         if ((state = ST_LD1_WAIT) or (state = ST_LD2_WAIT)) and (mem_done = '1') then
            ld_pte <= mem_ld_data;
         end if;
         
         -- lock in the index of the tlb set
         if (state = ST_READY) and (next_state = ST_LOOKUP) then
            i_set <= tag_index;
         end if;
         
         -- lock in the value of the pte written back to memory
         if (next_state = ST_STORE_PTE) and(state /= ST_STORE_PTE) then
            st_data_reg <= (XLEN - 1 downto BYTE_WIDTH => '-') & new_pte(BYTE_WIDTH - 1 downto 0);
         end if;
      end if;
   end process lock_input_output;
   
   
   -- modify page table storage and write-through signals
   modify_tlb_storage : process (clk, reset)
   begin
      if reset = '1' then
         -- invalidate all pte in cache
         for i in 0 to N_TLB_SETS - 1 loop
            valid_array0(i) <= '0';
            valid_array1(i) <= '0';
         end loop;
      elsif rising_edge(clk) then
         if sfence_vma = '1' then
            -- perform global flush
            -- TODO: rework TLB to support using rs1 and rs2 to only flush some pages (need to flush all megapages for a given addr)
            for i in 0 to N_TLB_SETS - 1 loop
               valid_array0(i) <= '0';
               valid_array1(i) <= '0';
            end loop;
         elsif state = ST_CACHE_DECODE then
            if in_cache and store_needed and not has_exception then
               if i_way_hit = 0 then
                  pte_array0(i_set) <= new_pte;
                  lru_array(i_set) <= 1;
               else
                  pte_array1(i_set) <= new_pte;
                  lru_array(i_set) <= 0;
               end if;
            end if;
         elsif state = ST_LD1_DECODE then
            if leaf_pte_found and not has_exception then
               -- enter the megapage into the tlb storage
               if lru = 0 then
                  asid_array0(i_set) <= satp_asid;
                  valid_array0(i_set) <= '1';
                  lru_array(i_set) <= 1;
                  mtag_array0(i_set) <= '1' & tag;
                  pte_array0(i_set) <= new_pte;
                  paddr_array0(i_set) <= ld_paddr;
               else
                  asid_array1(i_set) <= satp_asid;
                  valid_array1(i_set) <= '1';
                  lru_array(i_set) <= 0;
                  mtag_array1(i_set) <= '1' & tag;
                  pte_array1(i_set) <= new_pte;
                  paddr_array1(i_set) <= ld_paddr;
               end if;
            end if;
         elsif state = ST_LD2_DECODE then
            if leaf_pte_found and not has_exception then
               -- enter leaf pte into the tlb storage
               if lru_array(i_set) = 0 then
                  asid_array0(i_set) <= satp_asid;
                  valid_array0(i_set) <= '1';
                  lru_array(i_set) <= 1;
                  mtag_array0(i_set) <= '0' & tag;
                  pte_array0(i_set) <= new_pte;
                  paddr_array0(i_set) <= ld_paddr;
               else
                  asid_array1(i_set) <= satp_asid;
                  valid_array1(i_set) <= '1';
                  lru_array(i_set) <= 0;
                  mtag_array1(i_set) <= '0' & tag;
                  pte_array1(i_set) <= new_pte;
                  paddr_array1(i_set) <= ld_paddr;
               end if;
            end if;
         end if;
      end if;
   end process modify_tlb_storage;
   
   
   get_set_from_cache : process (clk)
   begin
      if rising_edge(clk) then
         if (state = ST_READY) and (next_state = ST_LOOKUP) then
            -- get the tlb set at tag_index
            lru <= lru_array(tag_index);
            indexed_set(0) <= to_cache_entry(valid_array0(tag_index),
                                             asid_array0(tag_index),
                                             mtag_array0(tag_index),
                                             pte_array0(tag_index),
                                             paddr_array0(tag_index));
            indexed_set(1) <= to_cache_entry(valid_array1(tag_index),
                                             asid_array1(tag_index),
                                             mtag_array1(tag_index),
                                             pte_array1(tag_index),
                                             paddr_array1(tag_index));
         end if;
      end if;
   end process get_set_from_cache;
  
   
   -- determine the new pte and translated address assuming the pte is the correct one
   handle_decode : process (all)
      variable pte_modified : boolean;
   begin
      pte_modified := false;
      
      -- modify pte as needed
      new_pte <= from_sv32_pte(pte);
      if ((state = ST_LD1_DECODE) or (state = ST_LD2_DECODE)) and (pte.a = '0') then
         new_pte(SV32_PTE_A) <= '1';
         pte_modified := true;
      end if;
      if (tlb_op = TLB_STORE) and (pte.d = '0') then
         new_pte(SV32_PTE_D) <= '1';
         pte_modified := true;
      end if;
      
      if pte_modified then
         store_needed <= true;
      else
         store_needed <= false;
      end if;
   end process handle_decode;
   
   
   -- search the currently loaded cache set for the pte
   search_set : process (all)
      variable entry : t_cache_entry;
      variable entry_vpn1 : std_logic_vector(SV32_VA_VPN1_LEN - 1 downto 0);
      variable found_pte : boolean;
   begin
      found_pte := false;
      i_way_hit <= 0;
      
      for iWay in 0 to N_WAYS - 1 loop
         entry := indexed_set(iWay);
         entry_vpn1 := entry.tag(TAG_LENGTH - 1 downto TAG_LENGTH - SV32_VA_VPN1_LEN);
         if entry.valid = '1' then
            if (((entry.tag = tag) or ((entry.megapage = '1') and (entry_vpn1 = vpn1))) and  -- tag match
                ((entry.asid = satp_asid) or (entry.pte.g = '1'))) then                      -- asid match
               found_pte := true;
               i_way_hit <= iWay;
               exit;
            end if;
         end if;
      end loop;
      
      if found_pte then
         in_cache <= true;
      else
         in_cache <= false;
      end if;
   end process search_set;
   
   
   misc_sync : process (clk)
   begin
      if rising_edge(clk) then
         if (state = ST_CACHE_DECODE) then
            if in_cache and not has_exception then
               translation_successful <= true;
            else
               translation_successful <= false;
            end if;
         elsif (state = ST_LD1_DECODE) then
            if leaf_pte_found and not has_exception then
               translation_successful <= true;
            else
               translation_successful <= false;
            end if;
         elsif (state = ST_LD2_DECODE) then
            if leaf_pte_found and not has_exception then
               translation_successful <= true;
            else
               translation_successful <= false;
            end if;
         end if;
      end if;
   end process misc_sync;
   
  
   tag_index <= to_integer(unsigned(vaddr(VIRT_ADDR_WIDTH - TAG_LENGTH - 1 downto SV32_VA_VPN0_LOW)));

   ready <= '1' when (state = ST_READY) or (state = ST_TRANS_DONE) else '0';
   done <= '1' when (state = ST_TRANS_DONE) else '0';
   mem_wren <= '1' when (state = ST_STORE_PTE) else '0';
   mem_en <= '1' when (state = ST_STORE_PTE) or (state = ST_LD1_START) or (state = ST_LD2_START) else '0';
   pte <= indexed_set(i_way_hit).pte when state = ST_CACHE_DECODE else to_sv32_pte(ld_pte);  -- TODO: input ld_pte should go into a register not be read directly
   leaf_pte_found <= true when (pte.r /= '0') or (pte.w /= '0') or (pte.x /= '0') else false;
   current_cache_entry <= indexed_set(i_way_hit);
   
   -- physical address assignment
   new_translated_paddr <= pte.ppn1 & pte.ppn0 & offset when (current_cache_entry.megapage = '0') and (state = ST_CACHE_DECODE) else
                           pte.ppn1 & mega_offset       when (current_cache_entry.megapage = '1') and (state = ST_CACHE_DECODE) else
                           pte.ppn1 & pte.ppn0 & offset when (state = ST_LD2_DECODE) else
                           pte.ppn1 & mega_offset when (state = ST_LD1_DECODE) else
                           (others => 'X');
   new_ld_paddr <= satp_ppn & vpn1 & "00" when state = ST_CACHE_DECODE else
                   pte.ppn1 & pte.ppn0 & vpn0 & "00" when state = ST_LD1_DECODE else
                   (others => 'X');  -- nothing should read it in this state
   new_st_paddr <= current_cache_entry.paddr when (state = ST_CACHE_DECODE) else
                   ld_paddr when (state = ST_LD1_DECODE) or (state = ST_LD2_DECODE) else
                   (others => 'X');
   -- update physical address registers
   update_paddr_registers : process (clk)
   begin
      if rising_edge(clk) then
         if (state = ST_CACHE_DECODE) or (state = ST_LD1_DECODE) or (state = ST_LD2_DECODE) then
            translated_paddr <= new_translated_paddr;
         end if;
         
         if (state = ST_CACHE_DECODE) or (state = ST_LD1_DECODE) then
            ld_paddr <= new_ld_paddr;
         end if;
         
         if (next_state = ST_STORE_PTE) and (state /= ST_STORE_PTE) then
            st_paddr <= new_st_paddr;
         end if;
      end if;
   end process update_paddr_registers;
   paddr <= "00" & vaddr     when (tlb_mode = '0') else
            translated_paddr when ((state = ST_READY) or (state = ST_TRANS_DONE)) and translation_successful else
            ld_paddr         when (state = ST_LD1_WAIT) or (state = ST_LD1_START) else
            ld_paddr         when (state = ST_LD2_WAIT) or (state = ST_LD2_START) else
            st_paddr         when (state = ST_STORE_PTE) else
            (others => 'X');
   mem_st_data <= st_data_reg when state = ST_STORE_PTE else (others => 'X');
   mem_st_mask <= "0001";  -- only write low byte of pte back to memory
            
   -- satp signal assignment
   tlb_mode <= satp(SATP_MODE);
   satp_asid <= satp(SATP_ASID_LOW + SV32_ASID_LEN - 1 downto SATP_ASID_LOW);
   satp_ppn <= satp(SATP_PPN_HIGH downto SATP_PPN_LOW);
   
   ---------------------------------------------------------------------------------------------------------------------
   ----------------------------------------------  Exceptions ----------------------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
   
   check_page_fault : process (all)
      variable page_fault : boolean;
   begin
      page_fault := false;
      
      -- SV32 step 3
      if (state = ST_LD1_DECODE) or (state = ST_LD2_DECODE) then
          if (pte.v = '0') or ((pte.r = '0') and (pte.w = '1')) then  -- invalid pte
            page_fault := true;
          end if;
      end if;
      
      -- SV32 step 4
      if state = ST_LD2_DECODE then
         if (pte.x = '0') and (pte.w = '0') and (pte.r = '0') then  -- no leaf pte found
            page_fault := true;
         end if;
      end if;
      
      -- SV32 step 5
      if ((state = ST_CACHE_DECODE) and in_cache) or ((state = ST_LD1_DECODE) and leaf_pte_found) or (state = ST_LD2_DECODE) then
         -- check xwru bits
         if (tlb_op = TLB_IFETCH) and (pte.x = '0') then  -- check x bit
            page_fault := true;
         elsif (tlb_op = TLB_STORE) and (pte.w = '0') then  -- check w bit
            page_fault := true;
         elsif (tlb_op = TLB_LOAD) and (pte.r = '0') then  -- check r bit
            if (sstatus_mxr = '0') or (pte.x = '0') then  -- check mxr bit
               page_fault := true;
            end if;
         elsif (pte.u = '0') and (hart_priv = PRIVILEGE_USER) then  -- user mode can't access non user mode page
            page_fault := true;
         elsif (pte.u = '1') and (hart_priv = PRIVILEGE_SUPERVISOR) and 
               ((sstatus_sum = '0') or (tlb_op = TLB_IFETCH)) then  -- supervisor can't access user pages unless sum = 1
            page_fault := true;
         end if;
      end if;
      
      -- SV32 step 6
      if (state = ST_LD1_DECODE) and leaf_pte_found then  -- check misaligned superpage
         if (pte.x = '0') and (pte.r = '0') and (unsigned(pte.ppn0) /= 0) then
            page_fault := true;
         end if;
      end if;
      
      -- assign proper page fault depending on the current operation
      -- set default signal values to prevent latches
      pg_fault_code <= EXCEPT_MIN_PRIORITY;
      pg_fault <= '0';
      if page_fault and not ((state = ST_CACHE_DECODE) and not in_cache) then  -- only fault if a valid entry is found
         if tlb_op = TLB_STORE then
            pg_fault <= '1';
            pg_fault_code <= EX_CODE_ST_PAGE_FAULT;
         elsif tlb_op = TLB_LOAD then
            pg_fault <= '1';
            pg_fault_code <= EX_CODE_LD_PAGE_FAULT;
         elsif tlb_op = TLB_IFETCH then
            pg_fault <= '1';
            pg_fault_code <= EX_CODE_INST_PAGE_FAULT;
         end if;
      end if;
   end process check_page_fault;
   

   
   has_exception <= true when exception = '1' else false;
   exception <= pg_fault or access_fault;
   exception_code <= resolve_sync_exceptions(pg_fault_code, access_fault_code);
   access_fault <= i_access_fault or st_access_fault or ld_access_fault;
   access_fault_code <= EX_CODE_ST_ACCESS_FAULT   when st_access_fault = '1' else
                       EX_CODE_LD_ACCESS_FAULT   when ld_access_fault = '1' else
                       EX_CODE_INST_ACCESS_FAULT when i_access_fault = '1' else
                       EXCEPT_MIN_PRIORITY;
   
   ---------------------------------------------------------------------------------------------------------------------
   ------------------------------------------------ pma checking -------------------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
   pma_check : pma_checker
   port map (
      enable => pma_enable,
      address => pma_check_addr,
      tlb_op => current_op,
      cacheable => cacheable,
      except_load => ld_access_fault,
      except_store => st_access_fault,
      except_ifetch => i_access_fault
   );

   pma_enable <= '1' when (state = ST_CACHE_DECODE) else
                 '1' when (state = ST_LD1_DECODE) else
                 '1' when (state = ST_LD2_DECODE) and leaf_pte_found else
                 '1' when (state = ST_STORE_PTE) else
                 '0';
   assign_pma_address : process (all)
   begin
      if state = ST_CACHE_DECODE then
         if in_cache then
            pma_check_addr <= new_translated_paddr;
            current_op <= tlb_op;
         else
            pma_check_addr <= new_ld_paddr;
            current_op <= TLB_LOAD;
         end if;
      elsif state = ST_LD1_DECODE then
         if leaf_pte_found then
            pma_check_addr <= new_translated_paddr;
            current_op <= tlb_op;
         else
            pma_check_addr <= new_ld_paddr;
            current_op <= TLB_LOAD;
         end if;
      elsif state = ST_LD2_DECODE then
         pma_check_addr <= new_translated_paddr;
         current_op <= tlb_op;
      elsif state = ST_STORE_PTE then
         pma_check_addr <= st_paddr;
         current_op <= TLB_STORE;
      else
         pma_check_addr <= (others => '-');
         current_op <= TLB_STORE;  -- don't care
      end if;
   end process assign_pma_address;
                     
end Behavioral;
