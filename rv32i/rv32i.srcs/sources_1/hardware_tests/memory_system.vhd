-- hardware test for the memory system

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.Common.all;
use work.Common_Memory.all;
use work.constants_axi4l.all;
use work.constants_uart.all;

entity memory_system is
   port (
      clk_100_mhz    : in     std_logic;
      reset          : in     std_logic;
      
      -- status ports
      compare_error  : out    std_logic; 
      
      -- RAM memory controller ports
      ddr3_dq        : inout  std_logic_vector(15 downto 0);
      ddr3_dqs_p     : inout  std_logic_vector(1 downto 0);
      ddr3_dqs_n     : inout  std_logic_vector(1 downto 0);
      ddr3_addr      : out    std_logic_vector(13 downto 0);
      ddr3_ba        : out    std_logic_vector(2 downto 0);
      ddr3_ras_n     : out    std_logic;
      ddr3_cas_n     : out    std_logic;
      ddr3_we_n      : out    std_logic;
      ddr3_reset_n   : out    std_logic;
      ddr3_ck_p      : out    std_logic_vector(0 downto 0);
      ddr3_ck_n      : out    std_logic_vector(0 downto 0);
      ddr3_cke       : out    std_logic_vector(0 downto 0);
      ddr3_cs_n      : out    std_logic_vector(0 downto 0);
      ddr3_dm        : out    std_logic_vector(1 downto 0);
      ddr3_odt       : out    std_logic_vector(0 downto 0);
      
      -- UART ports
      uart_tx        : out    std_logic;
      uart_rx        : in     std_logic
   );
end memory_system;

architecture Behavioral of memory_system is
   component memory_controller is
      port (
         clk            : out    std_logic;
         clk_ref        : in     std_logic;
         sys_clk        : in     std_logic;
         reset          : in     std_logic;
         
         -- to/from hart
         address        : in     std_logic_vector(XLEN - 1 downto 0);
         write_data     : in     std_logic_vector(XLEN - 1 downto 0);
         write_mask     : in     std_logic_vector(XLEN / 8 - 1 downto 0);
         read_data      : out    std_logic_vector(XLEN - 1 downto 0);   
         op_type        : in     t_mem_op;
         op_start       : in     std_logic;
         op_done        : out    std_logic;
         ready          : out    std_logic;
         
         -- for pma checker
         section        : in     t_mem_section;
         except_load    : out    std_logic;
         except_store   : out    std_logic;
         except_ifetch  : out    std_logic;
         no_cache       : out    std_logic;
         
         -- RAM memory controller ports
         ddr3_dq        : inout  std_logic_vector(15 downto 0);
         ddr3_dqs_p     : inout  std_logic_vector(1 downto 0);
         ddr3_dqs_n     : inout  std_logic_vector(1 downto 0);
         ddr3_addr      : out    std_logic_vector(13 downto 0);
         ddr3_ba        : out    std_logic_vector(2 downto 0);
         ddr3_ras_n     : out    std_logic;
         ddr3_cas_n     : out    std_logic;
         ddr3_we_n      : out    std_logic;
         ddr3_reset_n   : out    std_logic;
         ddr3_ck_p      : out    std_logic_vector(0 downto 0);
         ddr3_ck_n      : out    std_logic_vector(0 downto 0);
         ddr3_cke       : out    std_logic_vector(0 downto 0);
         ddr3_cs_n      : out    std_logic_vector(0 downto 0);
         ddr3_dm        : out    std_logic_vector(1 downto 0);
         ddr3_odt       : out    std_logic_vector(0 downto 0);
         
         -- axi bus ports
         axi_out        : out    t_axi4l_master_out;
         axi_in         : in     t_axi4l_master_in
      );
   end component;

   component uart is
      port (
         clk         : in     std_logic;
         reset       : in     std_logic;
         interrupt   : out    std_logic;  -- raise an interrupt when there are bytes 
         
         -- axi ports
         axi_out     : out    t_axi4l_master_in;
         axi_in      : in     t_axi4l_master_out;
         
         -- uart ports
         tx          : out    std_logic;
         rx          : in     std_logic
      );
   end component;
   
   component clocking_unit is
      port (
         -- input clock
         input_clk    : in     std_logic;
         
         -- output clocks
         sys_clk        : out    std_logic;
         mem_ref_clk    : out    std_logic;
         
         -- clk status
         clk_locked     : out    std_logic
      );
   end component;
   
   signal address : std_logic_vector(XLEN - 1 downto 0);
   signal write_data, read_data : std_logic_vector(XLEN - 1 downto 0);
   signal op_type : t_mem_op;
   signal op_start, op_done, mem_ready : std_logic;
   signal write_mask : std_logic_vector(XLEN / 8 - 1 downto 0);
   
   signal data_waiting : std_logic;
   
   signal mem_axi_out : t_axi4l_master_out;
   signal mem_axi_in  : t_axi4l_master_in;
   
   type t_state is (ST_RESET, ST_WRITE, ST_READ, ST_READ_WAIT);
   signal state, next_state : t_state;
   
   type t_message_array is array (integer range <>) of std_logic_vector(7 downto 0);
   constant MESSAGE : t_message_array(0 to 7) := (X"48", X"65", X"6C", X"6C", X"6F", X"21", X"0A", X"0D");  -- "Hello!\n"
   signal i : integer range 0 to MESSAGE'length - 1;
   
   -- clock signals
   signal clk, clk_ref, sys_clk : std_logic;
   signal clk_locked : std_logic;
   
   -- address offsets
   constant RAM_BASE_ADDRESS : unsigned := unsigned(PMA_REGION_MAIN_MEMORY.address_start);
   constant RAM_OFFSET_MAX_STL : std_logic_vector(XLEN - 1 downto 0) := X"0FFFFFFF";
   constant RAM_OFFSET_MAX : unsigned(XLEN - 1 downto 0) := unsigned(RAM_OFFSET_MAX_STL);
   signal write_offset, read_offset : unsigned(XLEN - 1 downto 0);
   
   attribute MARK_DEBUG : string;
   attribute MARK_DEBUG of compare_error : signal is "true";
   attribute MARK_DEBUG of write_data : signal is "true";
   attribute MARK_DEBUG of read_data : signal is "true";
   attribute MARK_DEBUG of address : signal is "true";
   attribute MARK_DEBUG of clk_locked : signal is "true";
   attribute MARK_DEBUG of op_start : signal is "true";
   attribute MARK_DEBUG of op_type : signal is "true";
   attribute MARK_DEBUG of op_done : signal is "true";
   attribute MARK_DEBUG of mem_ready : signal is "true";
begin
   ---------------------------------------------------------------------------------------------------------------------
   ------------------------------------------   component instatiation   -----------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
   mem_sys : memory_controller
   port map (
      clk => clk,
      clk_ref => clk_ref,
      sys_clk => sys_clk,
      reset => reset,
      address => address,
      write_data => write_data,
      write_mask => write_mask,
      read_data => read_data,
      op_type => op_type,
      op_start => op_start,
      op_done => op_done,
      ready => mem_ready,
      section => MEM_DATA,
      except_load => open,
      except_store => open,
      except_ifetch => open,
      no_cache => open,
      ddr3_dq => ddr3_dq,
      ddr3_dqs_p => ddr3_dqs_p,
      ddr3_dqs_n => ddr3_dqs_n,
      ddr3_addr => ddr3_addr,
      ddr3_ba => ddr3_ba,
      ddr3_ras_n => ddr3_ras_n,
      ddr3_cas_n => ddr3_cas_n,
      ddr3_we_n => ddr3_we_n,
      ddr3_reset_n => ddr3_reset_n,
      ddr3_ck_p => ddr3_ck_p,
      ddr3_ck_n => ddr3_ck_n,
      ddr3_cke => ddr3_cke,
      ddr3_cs_n => ddr3_cs_n,
      ddr3_dm => ddr3_dm,
      ddr3_odt => ddr3_odt,
      axi_out => mem_axi_out,
      axi_in => mem_axi_in
   );
      
   serial_uart : uart
   port map (
      clk => clk,
      reset => reset,
      interrupt => data_waiting,
      axi_out => mem_axi_in,
      axi_in => mem_axi_out,
      tx => uart_tx,
      rx => uart_rx
   );
      
   clock_gen : clocking_unit
   port map (
      input_clk => clk_100_mhz,
      sys_clk => sys_clk,
      mem_ref_clk => clk_ref,
      clk_locked => clk_locked
   );
   
   ---------------------------------------------------------------------------------------------------------------------
   ---------------------------------------------   signal assignment   -------------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
      
   get_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            if clk_locked = '1' then
               next_state <= ST_WRITE;
            else
               next_state <= ST_RESET;
            end if;
         when ST_WRITE =>
            if (op_start = '1') and (mem_ready = '1') and (write_offset = RAM_OFFSET_MAX - 3) then
               next_state <= ST_READ;
            else
               next_state <= ST_WRITE;
            end if;
         when ST_READ =>
            if (op_start = '1') and (mem_ready = '1') then
               next_state <= ST_READ_WAIT;
            else
               next_state <= ST_READ;
            end if;
         when ST_READ_WAIT =>
            if op_done = '1' then
               if read_offset = RAM_OFFSET_MAX - 3 then
                  next_state <= ST_WRITE;
               else
                  next_state <= ST_READ;
               end if;
            else
               next_state <= ST_READ_WAIT;
            end if;
         when others =>
            next_state <= ST_WRITE;
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
   
   op_type <= MEM_STORE when state = ST_WRITE else MEM_LOAD;
   write_mask <= "1111";
   op_start <= '1' when state = ST_WRITE else
               '1' when state = ST_READ else
               '0';
               
   address <= std_logic_vector(RAM_BASE_ADDRESS + write_offset) when state = ST_WRITE else 
              std_logic_vector(RAM_BASE_ADDRESS + read_offset);
   write_data <= std_logic_vector(RAM_BASE_ADDRESS + write_offset);
   
   increment_offsets : process (reset, clk)
   begin
      if reset = '1' then
         write_offset <= to_unsigned(0, XLEN);
         read_offset <= to_unsigned(0, XLEN);
      elsif rising_edge(clk) then
         if (state = ST_WRITE) and (op_start = '1') and (mem_ready = '1') then
            if write_offset = RAM_OFFSET_MAX - 3 then
               write_offset <= to_unsigned(0, XLEN);
            else
               write_offset <= write_offset + 4;
            end if;
         elsif (state = ST_READ_WAIT) and (op_done = '1') then
            if read_offset = RAM_OFFSET_MAX - 3 then
               read_offset <= to_unsigned(0, XLEN);
            else
               read_offset <= read_offset + 4;
            end if;
         end if;
      end if;
   end process increment_offsets;
   
   check_error : process (reset, clk)
   begin
      if reset = '1' then
         compare_error <= '0';
      elsif rising_edge(clk) then
         if (state = ST_READ_WAIT) and (op_done = '1') then
            if read_data /= address then
               compare_error <= '1';
            end if;
         end if;
      end if;
   end process check_error;
   
end Behavioral;
