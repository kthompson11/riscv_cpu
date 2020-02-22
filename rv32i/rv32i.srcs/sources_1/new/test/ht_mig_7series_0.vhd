-- hardware test for the memory interface

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ht_mig_7series_0 is
   port (
      clk_100_mhz    : in     std_logic;
      reset          : in     std_logic;
      cs_port        : out    std_logic;
      
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
      ddr3_odt       : out    std_logic_vector(0 downto 0)
   );
end ht_mig_7series_0;

architecture Behavioral of ht_mig_7series_0 is
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

   type t_state is (ST_RESET, ST_WAIT_READY, ST_WRITE, ST_READ, ST_READ_WAIT);
   signal state, next_state : t_state;
   
   -- clock signals
   signal clk, clk_ref, sys_clk : std_logic;
   signal clk_locked : std_logic;
   
      -- MIG signals
   constant MIG_ADDR_WIDTH : integer := 28;
   constant MIG_DATA_WIDTH : integer := 128;
   constant MIG_WRITE : std_logic_vector(2 downto 0) := "000";
   constant MIG_READ : std_logic_vector(2 downto 0) := "001";
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
   
   -- ram addresses
   constant RAM_ADDR_WIDTH : integer := 28;
   constant MAX_ADDR : unsigned(RAM_ADDR_WIDTH - 1 downto 0) := to_unsigned(1, RAM_ADDR_WIDTH);
   signal write_addr, read_addr : unsigned(RAM_ADDR_WIDTH - 1 downto 0);
   signal temp_addr : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
   
   -- interface signals
   signal write_data : std_logic_vector(31 downto 0);
   signal iword : integer range 0 to 3;
   
   -- debug
   signal count : unsigned(31 downto 0);
   signal count_stl : std_logic_vector(31 downto 0);
   signal first_read : boolean;
   
   attribute MARK_DEBUG : string;
   attribute MARK_DEBUG of compare_error : signal is "true";
   
   attribute MARK_DEBUG of ram_wdf_data : signal is "true";
   attribute MARK_DEBUG of ram_wdf_mask : signal is "true";
   attribute MARK_DEBUG of ram_wdf_wren : signal is "true";
   attribute MARK_DEBUG of ram_wdf_end : signal is "true";
   attribute MARK_DEBUG of ram_wdf_rdy : signal is "true";
   
   attribute MARK_DEBUG of ram_rd_data : signal is "true";
   attribute MARK_DEBUG of ram_rd_data_valid : signal is "true";
   
   attribute MARK_DEBUG of ram_addr : signal is "true";
   attribute MARK_DEBUG of ram_rdy : signal is "true";
   attribute MARK_DEBUG of ram_en : signal is "true";
   attribute MARK_DEBUG of ram_cmd : signal is "true";
   
   attribute MARK_DEBUG of ram_init_calib_complete : signal is "true";
   attribute MARK_DEBUG of clk_locked : signal is "true";
begin
   ---------------------------------------------------------------------------------------------------------------------
   ------------------------------------------   component instatiation   -----------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
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
               next_state <= ST_WAIT_READY;
            else
               next_state <= ST_RESET;
            end if;
         when ST_WAIT_READY =>
            if (ram_rdy = '1') and (ram_wdf_rdy = '1') then
               next_state <= ST_WRITE;
            else
               next_state <= ST_WAIT_READY;
            end if;
         when ST_WRITE =>
            if (ram_en = '1') and (ram_rdy = '1') then
               next_state <= ST_READ;
            else
               next_state <= ST_WRITE;
            end if;
         when ST_READ =>
            if (ram_en = '1') and (ram_rdy = '1') then
               next_state <= ST_READ_WAIT;
            else
               next_state <= ST_READ;
            end if;
         when ST_READ_WAIT =>
            if ram_rd_data_valid = '1' then
               if first_read then
                  next_state <= ST_READ;
               else
                  next_state <= ST_WRITE;
               end if;
            else
               next_state <= ST_READ_WAIT;
            end if;
         when others =>
            next_state <= ST_WAIT_READY;
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
   
   increment_offsets : process (reset, clk)
   begin
      if reset = '1' then
         write_addr <= to_unsigned(0, RAM_ADDR_WIDTH);
         read_addr <= to_unsigned(0, RAM_ADDR_WIDTH);
         count <= to_unsigned(0, 32);
      elsif rising_edge(clk) then
         if (state = ST_READ_WAIT) and (next_state = ST_READ) then
            if write_addr = MAX_ADDR then
               write_addr <= to_unsigned(0, RAM_ADDR_WIDTH);
            else
               write_addr <= write_addr + 1;
            end if;
            
            if read_addr = MAX_ADDR then
               read_addr <= to_unsigned(0, RAM_ADDR_WIDTH);
            else
               read_addr <= read_addr + 1;
            end if;
            
            count <= count + 1;
            
            first_read <= false;
         elsif (state = ST_READ_WAIT) and (next_state = ST_WRITE) then
            first_read <= true;
         end if;
      end if;
   end process increment_offsets;
   
   check_error : process (reset, clk)
   begin
      if reset = '1' then
         compare_error <= '0';
      elsif rising_edge(clk) then
         if (state = ST_READ_WAIT) and (ram_rd_data_valid = '1') then
            if ram_rd_data((iword + 1) * 32 - 1 downto iword * 32) /= write_data then
               compare_error <= '1';
            end if;
         end if;
      end if;
   end process check_error;
   
   temp_addr <= std_logic_vector(write_addr) when state = ST_WRITE else std_logic_vector(read_addr);
   ram_addr <= temp_addr;  -- align access to ram burst width
   ram_cmd <= MIG_WRITE when state = ST_WRITE else MIG_READ;
   ram_en <= '1' when state = ST_WRITE else
             '1' when state = ST_READ else
             '0';
             
   write_data <= "0000" & temp_addr;
   count_stl <= std_logic_vector(count(15 downto 0)) & std_logic_vector(count(15 downto 0));
   ram_wdf_data <= count_stl & count_stl & count_stl & count_stl;
   --ram_wdf_data <= write_data & write_data & write_data & write_data;
   iword <= to_integer(unsigned(temp_addr(3 downto 2)));
   
   ram_wdf_wren <= '1' when state = ST_WRITE else '0';
--   ram_wdf_mask <= "1111111111110000" when write_addr(3 downto 0) = 0 else
--                   "1111111100001111" when write_addr(3 downto 0) = 4 else
--                   "1111000011111111" when write_addr(3 downto 0) = 8 else
--                   "0000111111111111" when write_addr(3 downto 0) = 12 else
--                   "----------------";
   ram_wdf_mask <= (others => '0');
   ram_wdf_end <= '1';
end Behavioral;
