

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.Common.all;
use work.Common_Memory.all;


entity tb_tlb_sv32 is
end tb_tlb_sv32;

architecture Behavioral of tb_tlb_sv32 is
   component tlb_sv32 is
      generic (
         N_TLB_ENTRIES     : integer := 16
      );
      port (
         clk               : in     std_logic;
         reset             : in     std_logic;
         enable            : in     std_logic;
         
         tlb_op            : in     t_tlb_op;
         hart_priv         : in     t_hart_priv;
         sstatus_sum       : in     std_logic;
         sstatus_mxr       : in     std_logic;
         satp              : in     std_logic_vector(XLEN - 1 downto 0);
         vaddr             : in     std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
         rs1               : in     std_logic_vector(INSTRUCTION_RS1_LENGTH - 1 downto 0);
         rs2               : in     std_logic_vector(INSTRUCTION_RS2_LENGTH - 1 downto 0);
         flush             : in     std_logic;
         
         -- writeback and loading PTEs
         st_needed         : out    std_logic;
         ld_needed         : out    std_logic;
         op_done           : in     std_logic;
         st_data           : out    std_logic_vector(7 downto 0);  -- low byte of the pte
         ld_data           : in     std_logic_vector(XLEN - 1 downto 0);
         
         -- exceptions
         i_pg_fault        : out    std_logic;
         st_pg_fault       : out    std_logic;
         ld_pg_fault       : out    std_logic;
         i_access_fault    : out    std_logic;
         st_access_fault   : out    std_logic;
         ld_access_fault   : out    std_logic;
         
         ready             : out    std_logic;
         hit               : out    std_logic;  -- hit signifies the virtual address translation is done
         cacheable         : out    std_logic;
         paddr             : out    std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0)
      );
   end component;
   
   function get_ppn(constant paddr : std_logic_vector) return std_logic_vector is
      variable temp_addr : std_logic_vector(paddr'length - 1 downto 0);
   begin
      temp_addr := paddr;
      return temp_addr(PHYS_ADDR_WIDTH - 1 downto PHYS_ADDR_WIDTH - SATP_PPN_LEN);
   end get_ppn;
   
   signal clk, reset        : std_logic;
   signal enable            : std_logic;
   signal tlb_op            : t_tlb_op;
   signal hart_priv         : t_hart_priv;
   signal sstatus_sum       : std_logic;
   signal sstatus_mxr       : std_logic;
   signal satp              : std_logic_vector(XLEN - 1 downto 0);
   signal vaddr             : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal rs1               : std_logic_vector(INSTRUCTION_RS1_LENGTH - 1 downto 0);
   signal rs2               : std_logic_vector(INSTRUCTION_RS2_LENGTH - 1 downto 0);
   signal flush             : std_logic;
   signal st_needed         : std_logic;
   signal ld_needed         : std_logic;
   signal op_done           : std_logic;
   signal st_data           : std_logic_vector(7 downto 0);  -- low byte of the pte
   signal ld_data           : std_logic_vector(XLEN - 1 downto 0);
   signal i_pg_fault        : std_logic;
   signal st_pg_fault       : std_logic;
   signal ld_pg_fault       : std_logic;
   signal i_access_fault    : std_logic;
   signal st_access_fault   : std_logic;
   signal ld_access_fault   : std_logic;
   signal ready             : std_logic;
   signal hit               : std_logic;  -- hit signifies the virtual address translation is done
   signal cacheable         : std_logic;
   signal paddr             : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   
   signal sim_done : boolean := false;
   constant CLK_PERIOD : time := 10 ns;
   constant MEMORY_SIZE : natural := 2**18; -- words
   type t_memory is array(natural range <>) of std_logic_vector(31 downto 0);
   
   file memory_file: text;
   file stim_file : text;
   
   -- manually enter some pte to test
   
begin
   UUT : tlb_sv32
   generic map (
      N_TLB_ENTRIES => 8
   )
   port map (
      clk             ,
      reset           ,
      enable          ,
      tlb_op          ,
      hart_priv       ,
      sstatus_sum     ,
      sstatus_mxr     ,
      satp            ,
      vaddr           ,
      rs1             ,
      rs2             ,
      flush           ,
      st_needed       ,
      ld_needed       ,
      op_done         ,
      st_data         ,
      ld_data         ,
      i_pg_fault      ,
      st_pg_fault     ,
      ld_pg_fault     ,
      i_access_fault  ,
      st_access_fault ,
      ld_access_fault ,
      ready           ,
      hit             ,
      cacheable       ,
      paddr           
   );

   make_clk : process
   begin
     if not sim_done then
        clk <= '1';
        wait for CLK_PERIOD / 2;
        clk <= '0';
        wait for CLK_PERIOD / 2;
     else
        wait;
     end if;
   end process;
    
   mem_rw : process (clk)
     variable mem_loaded : boolean := false;
     variable next_line : line;
     variable next_address : std_logic_vector(33 downto 0);
     variable next_word : std_logic_vector(31 downto 0);
     variable iPTE : integer range 0 to MEMORY_SIZE - 1;
     variable sim_memory : t_memory(0 to MEMORY_SIZE - 1);  -- memory more efficient as variable
     variable stimuli_sent : boolean := false;
   begin
     if not mem_loaded then
        file_open(memory_file, "mem_init",  read_mode);
      
        while not endfile(memory_file) loop
           readline(memory_file, next_line);
           read(next_line, next_address);
           
           read(next_line, next_word);
           sim_memory(to_integer(unsigned(next_address(19 downto 2)))) := next_word;
        end loop;
        
        mem_loaded := true;
     end if;
     
     
     if rising_edge(clk) then
        iPTE := to_integer(unsigned(paddr(19 downto 2)));  -- addresses should be 4-byte aligned
        
        if ld_needed = '1' then
           ld_data <= sim_memory(iPTE);
           op_done <= '1';
        elsif (op_done = '1') then
           op_done <= '0';
        end if;
        
        if st_needed = '1' then
           sim_memory(iPTE)(7 downto 0) := st_data;
           op_done <= '1';
        elsif (op_done = '1') then
           op_done <= '0';
        end if;
     end if;
   end process mem_rw;
    
   handle_stimuli : process
      variable next_line : line;
      variable discard_char : string(1 to 1);
      variable next_op : string(1 to 7);
      variable next_priv : string(1 to 10);
      variable next_asid : std_logic_vector(SV32_ASID_LEN - 1 downto 0);
      variable next_vaddr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
      variable expected_paddr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   begin
      -- initialization
      enable <= '0';
      hart_priv <= PRIVILEGE_USER;
      satp <= "00000000000000010000000000000000";
      vaddr <= X"00001100";
      rs1 <= "00000";
      rs2 <= "00000";
      sstatus_sum <= '1';
      sstatus_mxr <= '1';
      flush <= '0';
      satp(SATP_MODE) <= '1';
      reset <= '1';
      wait until rising_edge(clk);
      reset <= '0';
      wait until rising_edge(clk) and (ready = '1');
      
      file_open(stim_file, "tlb_stimuli",  read_mode);
      
      while not endfile(stim_file) loop
         -- get stimuli from file
         readline(stim_file, next_line);
         read(next_line, next_op);
         read(next_line, discard_char);
         read(next_line, next_priv);
         read(next_line, next_asid);
         read(next_line, next_vaddr);
         read(next_line, expected_paddr);
         
         -- assign stimuli
         case next_op is
            when "STORE  " =>
               tlb_op <= TLB_STORE;
            when "LOAD   " =>
               tlb_op <= TLB_LOAD;
            when "IFETCH " =>
               tlb_op <= TLB_IFETCH;
            when others =>
               report "next_op others case should never be reached." severity error;
         end case;
         
         case next_priv is
            when "USER      " =>
               hart_priv <= PRIVILEGE_USER;
            when "SUPERVISOR" =>
               hart_priv <= PRIVILEGE_SUPERVISOR;
            when "MACHINE   " =>
               hart_priv <= PRIVILEGE_MACHINE;
            when others =>
               report "next_priv others case should never be reached." severity error;
         end case;
         satp(SATP_ASID_LOW + SV32_ASID_LEN - 1 downto SATP_ASID_LOW) <= next_asid;
         vaddr <= next_vaddr;
         
         enable <= '1';
         wait until rising_edge(clk);
         enable <= '0';
         
         wait until rising_edge(clk) and (ready = '1');
         -- check paddr = expected_paddr
         assert paddr = expected_paddr
         report "Translated address did not match expected value." severity error;
      end loop;
      
      wait until rising_edge(clk);
      flush <= '1';
      wait until rising_edge(clk);
      flush <= '0';
      
      sim_done <= true;
      wait;
   end process handle_stimuli;

--   mem_rw : process (clk)
      
--   begin
      
--   end process mem_rw;
    
--   sim : process
--   begin
--      enable <= '0';
--      hart_priv <= PRIVILEGE_USER;
--      satp <= "00000000000000010000000000000000";
--      vaddr <= X"00001100";
--      rs1 <= "00000";
--      rs2 <= "00000";
--      sstatus_sum <= '1';
--      sstatus_mxr <= '1';
--      flush <= '0';
--      reset <= '1';
--      wait until rising_edge(clk);
--      reset <= '0';
--      wait until rising_edge(clk);
--      enable <= '1';
--      wait until rising_edge(clk);
--      enable <= '0';
--      satp(SATP_MODE) <= '1';
--      wait until rising_edge(clk);
--      enable <= '1';
--      wait until rising_edge(clk);
--      enable <= '0';
      
--      wait until ready = '1';
--      wait until rising_edge(clk);
--      wait until rising_edge(clk);
--      wait until rising_edge(clk);
--      sim_done <= true;
--      wait;
--   end process sim;

end Behavioral;
