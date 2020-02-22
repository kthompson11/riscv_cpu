

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.Common.all;
use work.Common_Memory.all;
use work.common_exceptions.all;

entity tb_cache_unit is
end tb_cache_unit;


architecture Behavioral of tb_cache_unit is
   component cache_unit is
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
   end component;
   
   signal clk, reset : std_logic;
   signal hart_priv : t_hart_priv;
   signal sstatus_sum, sstatus_mxr : std_logic;
   signal satp : std_logic_vector(XLEN - 1 downto 0);
   signal data_addr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal data_funct3 : std_logic_vector(2 downto 0);
   signal data_op : t_mem_op;
   signal data_rd : std_logic_vector(XLEN - 1 downto 0);
   signal data_wd : std_logic_vector(XLEN - 1 downto 0);
   signal data_en, data_ready : std_logic;
   signal ifetch_addr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
   signal ifetch_rd : std_logic_vector(XLEN - 1 downto 0);
   signal ifetch_en, ifetch_ready : std_logic;
   signal mem_addr : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
   signal mem_rd : std_logic_vector(XLEN - 1 downto 0);
   signal mem_wd : std_logic_vector(XLEN - 1 downto 0);
   signal mem_wd_mask : std_logic_vector(XLEN / 8 - 1 downto 0);
   signal mem_wren, mem_en, mem_ready, mem_done : std_logic;
   signal fence_en, fence_ready, fence_done : std_logic;
   signal sfence_vma, fence_i : std_logic;
   signal rs1, rs2 : std_logic_vector(4 downto 0);
   signal exception : std_logic;
   signal exception_code : t_exception_code;
   
   signal iteration_number : integer := 0;
   signal sim_done : boolean := false;
   constant CLK_PERIOD : time := 10 ns;
   
   file init_file : text;
   file stim_file : text;
   file mem_check_file : text;
   
   constant OP_FENCE  : std_logic_vector(1 downto 0) := "00";
   constant OP_IFETCH : std_logic_vector(1 downto 0) := "01";
   constant OP_LOAD   : std_logic_vector(1 downto 0) := "10";
   constant OP_STORE  : std_logic_vector(1 downto 0) := "11";
begin
   mem_ready <= '1';
   rs1 <= REGISTER_0;
   rs2 <= REGISTER_1;
   

   handle_stimuli : process
      variable next_line : line;
      variable opcode : std_logic_vector(1 downto 0);
      variable vaddr : std_logic_vector(VIRT_ADDR_WIDTH - 1 downto 0);
      variable funct3 : std_logic_vector(2 downto 0);
      variable check_value : std_logic_vector(XLEN - 1 downto 0);
      variable write_data : std_logic_vector(XLEN - 1 downto 0);
      variable fence_type : std_logic;
   begin
      -- initialization
      reset <= '1';
      hart_priv <= PRIVILEGE_USER;
      sstatus_sum <= '1';
      sstatus_mxr <= '1';
      satp <= "1" & "000000001" & "0000010000000000000000";
      data_en <= '0';
      ifetch_en <= '0';
      fence_en <= '0';
      fence_i <= '0';
      sfence_vma <= '0';
      wait until rising_edge(clk);
      reset <= '0';
      wait until rising_edge(clk);
      
      file_open(stim_file, "cache_unit_stimuli",  read_mode);
      while not endfile(stim_file) loop
         readline(stim_file, next_line);
         iteration_number <= iteration_number + 1;
         read(next_line, opcode);
         case opcode is
            when OP_FENCE =>
               wait until rising_edge(clk) and (fence_ready = '1');
               read(next_line, fence_type);
               if fence_type = '0' then
                  fence_i <= '1';
               else
                  sfence_vma <= '1';
               end if;
               
               wait until rising_edge(clk);
               fence_i <= '0';
               sfence_vma <= '0';
               -- no check
            when OP_IFETCH =>
               hread(next_line, vaddr);
               hread(next_line, check_value);
               ifetch_addr <= vaddr;
               ifetch_en <= '1';
               wait until rising_edge(clk) and (ifetch_ready = '1');
               ifetch_en <= '0';
               wait until rising_edge(clk) and (ifetch_ready = '1');
               assert ifetch_rd = check_value
               report "ifetch error - returned value did not match expected value " & to_hstring(ifetch_rd) & " (actual) /= " & to_hstring(check_value) & " (expected)" severity error;
            when OP_LOAD =>
               hread(next_line, vaddr);
               read(next_line, funct3);
               hread(next_line, check_value);
               data_addr <= vaddr;
               data_op <= MEM_LOAD;
               data_funct3 <= funct3;
               data_en <= '1';
               wait until rising_edge(clk) and (data_ready = '1');
               data_en <= '0';
               wait until rising_edge(clk) and (data_ready = '1');
               assert data_rd = check_value
               report "load error - returned value did not match expected value " & to_hstring(data_rd) & " (actual) /= " & to_hstring(check_value) & " (expected)" severity error;
            when OP_STORE =>
               hread(next_line, vaddr);
               read(next_line, funct3);
               hread(next_line, write_data);
               data_addr <= vaddr;
               data_funct3 <= funct3;
               data_wd <= write_data;
               
               -- write data
               data_op <= MEM_STORE;
               data_en <= '1';
               wait until rising_edge(clk) and (data_ready = '1');
               data_en <= '0';
               wait until rising_edge(clk) and (data_ready = '1');
               
               -- check lower
               hread(next_line, vaddr);
               hread(next_line, check_value);
               data_addr <= vaddr;
               data_funct3 <= LOAD_FUNCT3_LW;
               data_op <= MEM_LOAD;
               data_en <= '1';
               wait until rising_edge(clk) and (data_ready = '1');
               data_en <= '0';
               wait until rising_edge(clk) and (data_ready = '1');
               assert data_rd = check_value
               report "store error - lower value mismatch " & to_hstring(data_rd) & " (actual) /= " & to_hstring(check_value) & " (expected)" severity error;
               
               -- check upper
               hread(next_line, vaddr);
               hread(next_line, check_value);
               data_funct3 <= LOAD_FUNCT3_LW;
               data_addr <= vaddr;
               data_op <= MEM_LOAD;
               data_en <= '1';
               wait until rising_edge(clk) and (data_ready = '1');
               data_en <= '0';
               wait until rising_edge(clk) and (data_ready = '1');
               assert data_rd = check_value
               report "store error - upper value mismatch " & to_hstring(data_rd) & " (actual) /= " & to_hstring(check_value) & " (expected)" severity error;
            when others => 
               null;
         end case;
      end loop;
      
      sim_done <= true;
      wait;
   end process handle_stimuli;

   handle_mem_rw : process (clk)
      variable mem_initialized : boolean := false;
      
      variable next_line : line;
      variable next_byte : std_logic_vector(7 downto 0);
      
      constant MEM_SIZE : integer := 3 * 2**12;  -- 3 pages
      type t_memory is array(natural range <>) of std_logic_vector(7 downto 0);
      variable sim_mem : t_memory(0 to MEM_SIZE - 1);
      variable i_mem : integer range 0 to MEM_SIZE - 1 := 0;
   begin
      if not mem_initialized then
         file_open(init_file, "mem_init",  read_mode);
         while not endfile(init_file) loop
            readline(init_file, next_line);
            read(next_line, next_byte);
            sim_mem(i_mem) := next_byte;
            i_mem := i_mem + 1;
         end loop;
         mem_initialized := true;
      end if;
      
--      -- check final memory state
--      -- cache must be flushed first
--      -- TODO: implement this and flush
--      if sim_done then
--         file_open(mem_check_file, "mem_check", read_mode);
--         for i in 0 to MEM_SIZE - 1 loop
--            readline(mem_check_file, next_line);
--            read(next_line, next_byte);
--            assert next_byte = sim_mem(i)
--            report "incorrect final memory state " & 
--         end loop;
--      end if;
      
      if rising_edge(clk) then
         mem_done <= '0';
         if mem_en = '1' then
            i_mem := to_integer(unsigned(mem_addr(15 downto 0)));
            if mem_wren = '1' then
               -- write memory
               for i in 0 to 3 loop
                  if mem_wd_mask(i) = '1' then
                     sim_mem(i_mem + i) := mem_wd((i + 1) * 8 - 1 downto i * 8);
                  end if;
               end loop;
            else
               -- read memory
               for i in 0 to 3 loop
                  mem_rd((i + 1) * 8 - 1 downto i * 8) <= sim_mem(i_mem + i);
               end loop;
            end if;
            
            mem_done <= '1';
         end if;
      end if;
   end process handle_mem_rw;

   make_clk : process
   begin
      if sim_done then
         wait;
      else
         clk <= '1';
         wait for CLK_PERIOD / 2;
         clk <= '0';
         wait for CLK_PERIOD / 2;
      end if;
   end process make_clk;

   ---------------------------------------------------------------------------------------------------------------------
   ---------------------------------------- component instantiation ----------------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------

   UUT : cache_unit
   generic map (
      N_TLB_ENTRIES => 8,
      N_CACHE_ENTRIES => 8
   )
   port map (
      clk => clk,
      reset => reset,
      hart_priv => hart_priv,
      sstatus_sum => sstatus_sum,
      sstatus_mxr => sstatus_mxr,
      satp => satp,
      data_addr => data_addr,
      data_funct3 => data_funct3,
      data_op => data_op,
      data_rd => data_rd,
      data_wd => data_wd,
      data_en => data_en,
      data_ready => data_ready,
      ifetch_addr => ifetch_addr,
      ifetch_rd => ifetch_rd,
      ifetch_en => ifetch_en,
      ifetch_ready => ifetch_ready,
      mem_addr => mem_addr,
      mem_rd => mem_rd,
      mem_wd => mem_wd,
      mem_wd_mask => mem_wd_mask,
      mem_wren => mem_wren,
      mem_en => mem_en,
      mem_ready => mem_ready,
      mem_done => mem_done,
      fence_en => fence_en,
      fence_ready => fence_ready,
      fence_done => fence_done,
      sfence_vma => sfence_vma,
      fence_i => fence_i,
      rs1 => rs1,
      rs2 => rs2,
      exception => exception,
      exception_code => exception_code
   );
end Behavioral;
