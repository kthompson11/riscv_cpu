

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.Common.all;
use work.constants_axi4l.all;
use work.Common_Memory.all;
use work.tools.replicate_stl;

entity memory_controller is
   port (
      clk            : out     std_logic;  -- system clock
      clk_ref        : in     std_logic;  -- 200 MHz reference clock
      sys_clk        : in    std_logic;
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
end memory_controller;


architecture Behavioral of memory_controller is
   component axi4l_master is
      port (
         clk         : in     std_logic;  -- ACLK
         reset       : in     std_logic;  -- RESETn (except active high)
         write_data  : in     std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);      -- data to write
         strobe      : in     std_logic_vector(AXI4L_DATA_WIDTH / 8 - 1 downto 0);
         read_data   : out    std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);      -- data read
         address     : in     std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);  -- address to access
         operation   : in     t_axi_op;                                       -- type of operation to perform (read/write)
         op_start    : in     std_logic;                                      -- signal the start of an operation
         op_done     : out    std_logic;                                     -- previous operation has finished and results are available
         ready       : out    std_logic;                                      -- signal that the master is ready to start an operation
         
         axi_out     : out    t_axi4l_master_out;
         axi_in      : in     t_axi4l_master_in
      );
   end component;

   component pma_checker is
      port (
         address              : in     std_logic_vector(XLEN - 1 downto 0);
         op_type              : in     T_MEM_OP;
         section_type         : in     T_MEM_SECTION;
         no_cache             : out    std_logic;  -- when '1' indicates that the address should not be cached
         
         except_load          : out    std_logic;
         except_store         : out    std_logic;
         except_ifetch        : out    std_logic
         
      );
   end component;
   
   component mig_7series_0 is
      port (
         ddr3_dq       : inout std_logic_vector(15 downto 0);
         ddr3_dqs_p    : inout std_logic_vector(1 downto 0);
         ddr3_dqs_n    : inout std_logic_vector(1 downto 0);
         
         ddr3_addr     : out   std_logic_vector(13 downto 0);
         ddr3_ba       : out   std_logic_vector(2 downto 0);
         ddr3_ras_n    : out   std_logic;
         ddr3_cas_n    : out   std_logic;
         ddr3_we_n     : out   std_logic;
         ddr3_reset_n  : out   std_logic;
         ddr3_ck_p     : out   std_logic_vector(0 downto 0);
         ddr3_ck_n     : out   std_logic_vector(0 downto 0);
         ddr3_cke      : out   std_logic_vector(0 downto 0);
         ddr3_cs_n     : out   std_logic_vector(0 downto 0);
         ddr3_dm       : out   std_logic_vector(1 downto 0);
         ddr3_odt      : out   std_logic_vector(0 downto 0);
         app_addr                  : in    std_logic_vector(27 downto 0);
         app_cmd                   : in    std_logic_vector(2 downto 0);
         app_en                    : in    std_logic;
         app_wdf_data              : in    std_logic_vector(127 downto 0);
         app_wdf_end               : in    std_logic;
         app_wdf_mask         : in    std_logic_vector(15 downto 0);
         app_wdf_wren              : in    std_logic;
         app_rd_data               : out   std_logic_vector(127 downto 0);
         app_rd_data_end           : out   std_logic;
         app_rd_data_valid         : out   std_logic;
         app_rdy                   : out   std_logic;
         app_wdf_rdy               : out   std_logic;
         app_sr_req                : in    std_logic;
         app_ref_req               : in    std_logic;
         app_zq_req                : in    std_logic;
         app_sr_active             : out   std_logic;
         app_ref_ack               : out   std_logic;
         app_zq_ack                : out   std_logic;
         ui_clk                    : out   std_logic;
         ui_clk_sync_rst           : out   std_logic;
         init_calib_complete       : out   std_logic;
         -- System Clock Ports
         sys_clk_i                      : in    std_logic;
         -- Reference Clock Ports
         clk_ref_i                                : in    std_logic;
         device_temp                      : out std_logic_vector(11 downto 0);
         sys_rst                     : in    std_logic
      );
   end component;
   
   -- memory controller stats
   type t_memc_state is (ST_RESET, ST_READY, ST_AXI_OP, ST_AXI_WAIT, ST_OP_DONE, ST_RAM_OP, ST_RAM_READ, ST_RAM_SEND_WD, ST_RAM_SEND_WA);
   signal state, next_state : t_memc_state;
   
   -- input signals
   signal input_address : std_logic_vector(XLEN - 1 downto 0);
   signal input_wd : std_logic_vector(XLEN - 1 downto 0);
   signal input_wd_mask : std_logic_vector(XLEN / 8 - 1 downto 0);
   signal input_op_type : t_mem_op;
   
   -- address map
   constant RAM_START_ADDRESS  : std_logic_vector(XLEN - 1 downto 0) := PMA_REGION_MAIN_MEMORY.address_start;
   constant RAM_END_ADDRESS    : std_logic_vector(XLEN - 1 downto 0) := PMA_REGION_MAIN_MEMORY.address_end;
   signal is_ram_address : boolean;
   
   -- axi signals
   signal axi_wd, axi_rd : std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
   signal axi_strobe : std_logic_vector(AXI4L_DATA_WIDTH / 8 - 1 downto 0);
   signal axi_addr : std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
   signal axi_op : t_axi_op;
   signal axi_op_start, axi_op_done, axi_ready : std_logic;
    
   signal is_valid_address : boolean;
   
   -- MIG signals
   constant MIG_ADDR_WIDTH : integer := 28;
   constant MIG_DATA_WIDTH : integer := 128;
   constant MIG_MASK_LEN : integer := 16;
   constant MIG_WRITE : std_logic_vector(2 downto 0) := "000";
   constant MIG_READ : std_logic_vector(2 downto 0) := "001";
   constant MIG_MASK_WORD : std_logic_vector(MIG_MASK_LEN - 1 downto 0) := (MIG_MASK_LEN - 1 downto 4 => '1') & (3 downto 0 => '0');
   constant MIG_MASK_HALF : std_logic_vector(MIG_MASK_LEN - 1 downto 0) := (MIG_MASK_LEN - 1 downto 2 => '1') & (1 downto 0 => '0');
   constant MIG_MASK_BYTE : std_logic_vector(MIG_MASK_LEN - 1 downto 0) := (MIG_MASK_LEN - 1 downto 1 => '1') & (0 downto 0 => '0');
   signal word_base : std_logic_vector(XLEN - 1 downto 0);
   signal half_base : std_logic_vector(XLEN / 2 - 1 downto 0);
   signal byte_base : std_logic_vector(XLEN / 4 - 1 downto 0);
   signal ram_addr : std_logic_vector(27 downto 0);
   signal ram_cmd : std_logic_vector(2 downto 0);
   signal ram_en : std_logic;
   signal ram_wdf_data : std_logic_vector(127 downto 0);
   signal ram_wdf_end : std_logic;
   signal ram_wdf_mask : std_logic_vector(15 downto 0);
   signal ram_wdf_wren : std_logic;
   signal ram_rd_data : std_logic_vector(127 downto 0);
   signal ram_rd_data_valid : std_logic;
   signal ram_rdy : std_logic;
   signal ram_wdf_rdy : std_logic;
   signal ram_init_calib_complete : std_logic;
   signal ram_sys_clk : std_logic;
   signal ram_clk_ref : std_logic;
   
   -- other signals
   signal base_mask : std_logic_vector(MIG_MASK_LEN - 1 downto 0);
   
   -- ram indexing
   signal i_word : integer range 0 to 3;
   signal i_half : integer range 0 to 7;
   signal i_byte : integer range 0 to 15;
   
   attribute MARK_DEBUG : string;
   attribute MARK_DEBUG of ram_addr : signal is "true";
   attribute MARK_DEBUG of ram_cmd : signal is "true";
   attribute MARK_DEBUG of ram_en : signal is "true";
   attribute MARK_DEBUG of ram_rdy : signal is "true";
   
   attribute MARK_DEBUG of ram_wdf_rdy : signal is "true";
   attribute MARK_DEBUG of ram_wdf_wren : signal is "true";
   attribute MARK_DEBUG of ram_wdf_data : signal is "true";
   attribute MARK_DEBUG of ram_wdf_mask : signal is "true";
   
   attribute MARK_DEBUG of ram_rd_data : signal is "true";
   attribute MARK_DEBUG of ram_rd_data_valid : signal is "true";
begin
   axi_master : axi4l_master
      port map (
         clk => clk,
         reset => reset,
         write_data => axi_wd,
         strobe => axi_strobe,
         read_data => axi_rd,
         address => axi_addr,
         operation => axi_op,
         op_start => axi_op_start,
         op_done => axi_op_done,
         ready => axi_ready,
         axi_out => axi_out,
         axi_in => axi_in
      );
      
   pma_check : pma_checker
      port map (
         address => address,
         op_type => op_type,
         section_type => section,
         no_cache => no_cache,
         except_load => except_load,
         except_store => except_store,
         except_ifetch => except_ifetch
      );
      
   ram_controller : mig_7series_0
      port map (
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
         app_addr => ram_addr,
         app_cmd => ram_cmd,
         app_en => ram_en,
         app_wdf_data => ram_wdf_data,
         app_wdf_end => ram_wdf_end,
         app_wdf_mask => ram_wdf_mask,
         app_wdf_wren => ram_wdf_wren,
         app_rd_data => ram_rd_data,
         app_rd_data_end => open,
         app_rd_data_valid => ram_rd_data_valid,
         app_rdy => ram_rdy,
         app_wdf_rdy => ram_wdf_rdy,
         app_sr_req => '0',  -- reserved (should be '0')
         app_ref_req => '0',  -- USER_REFRESH = "OFF"
         app_zq_req => '0',  -- tZQI /= 0
         app_sr_active => open,  -- reserved
         app_ref_ack => open,  -- USER_REFRESH = "OFF"
         app_zq_ack => open,  -- tZQI /= 0
         ui_clk => clk,
         ui_clk_sync_rst => open,
         init_calib_complete => ram_init_calib_complete,
         sys_clk_i => sys_clk,
         clk_ref_i => clk_ref, -- 200 MHz
         device_temp => open,
         sys_rst => reset
      );

   get_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            if ram_init_calib_complete = '1' then
               next_state <= ST_READY;
            else
               next_state <= ST_RESET;
            end if;
         when ST_READY =>
            if (op_start = '1') and is_valid_address then
               if is_ram_address then
                  next_state <= ST_RAM_OP;
               else  -- AXI address
                  next_state <= ST_AXI_OP;
               end if;
            else
               next_state <= ST_READY;
            end if;
         when ST_AXI_OP =>
            if (axi_ready = '1') and (axi_op_start = '1') then
               next_state <= ST_AXI_WAIT;
            else
               next_state <= ST_AXI_OP;
            end if;
         when ST_AXI_WAIT =>
            if axi_op_done = '1' then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_AXI_WAIT;
            end if;
         when ST_OP_DONE =>
            next_state <= ST_READY;
         when ST_RAM_OP =>
            if (input_op_type = MEM_STORE) then
               if (ram_rdy = '1') and (ram_wdf_rdy = '1') then
                  next_state <= ST_OP_DONE;
--               elsif ram_rdy = '1' then
--                  next_state <= ST_RAM_SEND_WD;
--               elsif ram_wdf_rdy = '1' then
--                  next_state <= ST_RAM_SEND_WA;
               else
                  next_state <= ST_RAM_OP;
               end if;
            elsif (input_op_type = MEM_LOAD) and (ram_rdy = '1') then
               next_state <= ST_RAM_READ;
            else
               next_state <= ST_RAM_OP;
            end if;
         when ST_RAM_READ =>
            if ram_rd_data_valid = '1' then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_RAM_READ;
            end if;
         when ST_RAM_SEND_WD =>  -- write address sent, wait on write data
            if ram_rdy = '1' then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_RAM_SEND_WD;
            end if;
         when ST_RAM_SEND_WA =>  -- write data send, wait on write address
            if ram_wdf_rdy = '1' then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_RAM_SEND_WA;
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
   
   -- locks in inputs when transitioning from ST_READY
   handle_inputs : process (reset, clk)
   begin
      if reset = '1' then
         null;
      elsif rising_edge(clk) then
         if (state = ST_READY) and (next_state /= ST_READY) then
            input_address <= address;
            input_wd <= write_data;
            input_wd_mask <= write_mask;
            input_op_type <= op_type;
         end if;
      end if;
   end process handle_inputs;
   
   handle_axi_done : process (reset, clk)
   begin
      if reset = '1' then
         null;
      elsif rising_edge(clk) then
         read_data <= (others => 'X');  -- invalid value if read at wrong time (for simulation)
      
         if (state = ST_AXI_WAIT) and (next_state = ST_OP_DONE) then  -- AXI read done
            -- send axi outputs to hart (if applicable)
            if input_op_type = MEM_LOAD then
               read_data <= axi_rd;
            elsif input_op_type = MEM_STORE then
               null;  -- nothing to do
            end if;
         elsif (state = ST_RAM_READ) and (next_state = ST_OP_DONE) then  -- RAM read done
            -- send RAM output to hart
            read_data <= ram_rd_data((i_word + 1) * WORD_WIDTH - 1 downto i_word * WORD_WIDTH);
         end if;
      end if;
   end process handle_axi_done;

   -- axi signal assignment
   axi_op_start <= '1' when state = ST_AXI_OP else '0';
   axi_wd <= input_wd;
   axi_strobe <= input_wd_mask;
   axi_addr <= input_address;
   axi_op <= AXI_WRITE when input_op_type = MEM_STORE else
             AXI_READ;
   
   is_ram_address <= true when (address >= RAM_START_ADDRESS) and (address <= RAM_END_ADDRESS) else false;
   is_valid_address <= false when except_load = '1' else
                       false when except_store = '1' else
                       false when except_ifetch = '1' else
                       true;
                    
   ready <= '1' when state = ST_READY else '0';
   op_done <= '1' when state = ST_OP_DONE else '0';
   
   -- RAM signal assignment         
   i_word <= to_integer(unsigned(input_address(3 downto 2)));
   ram_addr <= "0" & input_address(MIG_ADDR_WIDTH - 1 downto 4) & "000";
   ram_cmd <= MIG_WRITE when input_op_type = MEM_STORE else MIG_READ;
   word_base <= input_wd;
   ram_wdf_data <= replicate_stl(word_base, MIG_DATA_WIDTH / WORD_WIDTH);
   ram_wdf_end <= '1';
   base_mask <= (MIG_MASK_LEN - 1 downto 4 => '1') & not(input_wd_mask);
   ram_wdf_mask <= std_logic_vector(rotate_left(unsigned(base_mask), i_word * (WORD_WIDTH / 8)));
   
   set_enable : process (all)
   begin
      -- else values
      ram_en <= '0';
      ram_wdf_wren <= '0';
      
      if state = ST_RAM_OP then
         if input_op_type = MEM_STORE then
            if (ram_rdy = '1') and (ram_wdf_rdy = '1') then
               ram_en <= '1';
               ram_wdf_wren <= '1';
            end if;
         else  -- MEM_LOAD
            if ram_rdy = '1' then
               ram_en <= '1';
            end if;
         end if;
      end if;
   end process set_enable;
   
end Behavioral;
