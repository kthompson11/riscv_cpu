-- minimal SDSC host using SPI
-- TODO: move most of sd_host implementation to software (bootloader in built-in flash?)
-- TODO: sck should be put on the clock fabric and (maybe) use a PLL

library ieee;
use ieee.std_logic_1164.all;

use work.Common.all;
use work.constants_axi4l.all;
use work.common_sd.all;


entity sd_host is
   generic (
      SD_SCK_FREQ    : integer := 10000000
   );
   port (
      clk            : in     std_logic;
      reset          : in     std_logic;
      
      -- sd card ports
      sd_sck         : out    std_logic;
      sd_cs_n        : out    std_logic;
      sd_mosi        : out    std_logic;
      sd_miso        : in     std_logic;
      
      -- axi ports
      axi_out        : out    t_axi4l_master_in;
      axi_in         : in     t_axi4l_master_out
   );
end sd_host;

architecture Behavioral of sd_host is
   component sd_tx is
      port (
         sck            : in     std_logic;
         sck_align      : in     std_logic;
         reset          : in     std_logic;
         
         ready          : out    std_logic;
         enable         : in     std_logic;
         
         tx_type        : in     t_tx_type;
         cmd_index      : in     integer range 0 to 2**SD_CMD_INDEX_LEN - 1;
         argument       : in     std_logic_vector(SD_ARG_LEN - 1 downto 0);
         data           : in     std_logic_vector(SD_BLOCK_LEN * 8 - 1 downto 0);
         
         mosi           : out    std_logic
      );
   end component;

   constant SCK_COUNT_MAX : integer := CLK_FREQUENCY / SD_SCK_FREQ - 1;  -- data transfer clock frequency
   constant SCK_DOWN_COUNT : integer := (SCK_COUNT_MAX + 1) / 2;
   signal sck, sck_align : std_logic;
   signal sck_align_count : integer range 0 to 7;
   signal sck_count : integer range 0 to SCK_COUNT_MAX;
   signal sck_rising : boolean;
   
   type t_sd_host_state is (ST_RESET, ST_INIT, ST_READY, ST_BUSY, ST_IO_DONE);
   signal host_state : t_sd_host_state;
   
   -- initialization signals
   signal init_spi_reset : boolean;
   signal init_desired_voltage : boolean;
   signal init_compat_voltage : boolean;
   signal init_hcs : boolean;
   signal init_ccs : boolean;
   signal init_crc : boolean;
   signal init_blk_len : boolean;
   
   -- command signals/flags
   signal pre_wait_done : boolean;
   signal post_wait_done : boolean;
   signal app_cmd_sent : boolean;
   signal cmd_sent : boolean;
   signal resp_received : boolean;
   signal awaiting_resp : boolean;
   
   -- sd_tx unit signals
   signal tx_ready : std_logic;
   signal tx_enable : std_logic;
   signal tx_type : t_tx_type;
   signal tx_cmd_index : integer range 0 to 2**SD_CMD_INDEX_LEN - 1;
   signal tx_argument : std_logic_vector(SD_ARG_LEN - 1 downto 0);
   signal tx_data : std_logic_vector(SD_BLOCK_LEN * 8 - 1 downto 0);
   
   -- sd_rx unit signals
   signal rx_ready : std_logic;
   signal rx_enable : std_logic;
--   signal rx_resp : std_logic_vector(SD_RESP_LEN - 1 downto 0);
--   signal rx_data : std_logic_vector(SD_RX_DATA_LEN - 1 downto 0);
--   signal rx_crc_error : std_logic;
   
   -- sd operation signals
   type t_sd_op is (SD_WRITE, SD_READ);
   signal pending_op : boolean;
   signal op_type : t_sd_op;
   
   -- io state machine signals
   type t_io_handler_state is (ST_REQ_TX_RX, ST_WAIT_RESP, ST_REQ_DBLOCK, ST_WAIT_DBLOCK, ST_REQ_DATA_SEND_AND_RESP, ST_WAIT_DATA_RESP);
   signal io_handler_state : t_io_handler_state;
   signal io_cmd_index     : std_logic_vector(SD_CMD_INDEX_LEN - 1 downto 0);
   signal io_app_cmd          : boolean;
   signal io_argument      : std_logic_vector(SD_ARG_LEN - 1 downto 0);
   signal io_resp_type     : t_rx_type;
   signal io_resp          : std_logic_vector(RX_RESP_MAX_LEN - 1 downto 0);
   signal io_wdata         : std_logic_vector(SD_BLOCK_LEN * 8 - 1 downto 0);
   signal io_rdata         : std_logic_vector(RX_MAX_LEN - 1 downto 0);
   signal io_block_len     : integer range 0 to 255;  -- TODO: replace this literal
   
   signal executing_command : boolean;
begin
   main_proc : process (reset, clk)
      variable command : t_sd_command;
   begin
      if reset = '1' then
         host_state <= ST_RESET;
      elsif rising_edge(clk) then
         rx_enable <= '0';
         tx_enable <= '0';
      
         case host_state is
            when ST_RESET =>
               host_state <= ST_READY;
               init_spi_reset <= false;
               init_desired_voltage <= false;
               init_compat_voltage <= false;
               init_hcs <= false;
               init_ccs <= false;
               init_crc <= false;
               init_blk_len <= false;
            when ST_INIT =>
               if not init_spi_reset then
                  command := SD_CMD0;
               elsif not init_desired_voltage then
                  command := SD_CMD8;
               elsif not init_compat_voltage then
                  command := SD_CMD58;
               elsif not init_hcs then
                  command := SD_ACMD41;
               elsif not init_ccs then
                  command := SD_CMD58;
               elsif not init_crc then
                  command := SD_CMD59;
               elsif not init_blk_len then
                  command := SD_CMD16;
               else
                  host_state <= ST_READY;
               end if;
            when ST_READY =>
               null;
            when ST_BUSY =>
               case io_handler_state is
                  when others =>
                     null;
               end case;
            when ST_IO_DONE =>  -- interpret results of io
               null;
            when others =>
               host_state <= ST_RESET;
         end case;
      end if;
   end process main_proc;

   ---------------------------------------------------------------------------------------------------------------------
   ----------------------------------- SCK generation ------------------------------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
   
   -- generate a continuous serial clock of the specified frequency
   gen_sck : process (reset, clk)
   begin
      if reset = '1' then
         sck_count <= 0;
         sck_align_count <= 0;
      elsif rising_edge(clk) then
         -- modify sck
         if sck_count = 0 then
            sck <= '1';
            
            -- increment sck_align_count
            if sck_align_count = 7 then
               sck_align_count <= 0;
            else
               sck_align_count <= sck_align_count + 1;
            end if;
         elsif sck_count = SCK_DOWN_COUNT then
            sck <= '0';
         end if;
      
         -- increment sck_count
         if sck_count = SCK_COUNT_MAX then
            sck_count <= 0;
         else
            sck_count <= sck_count + 1;
         end if;
      end if;
   end process gen_sck;
   
   sck_align <= '1' when sck_align_count = 0 else '0';
   sd_sck <= sck;
   sck_rising <= true when sck_count = 0 else false;
   
   -- TODO: temporary - remove this
   rx_ready <= '1';

   ---------------------------------------------------------------------------------------------------------------------
   ------------------------------------------------ component instantiation --------------------------------------------
   ---------------------------------------------------------------------------------------------------------------------
   
   tx_unit : sd_tx
   port map (
      sck => sck,
      sck_align => sck_align,
      reset => reset,
      ready => tx_ready,
      enable => tx_enable,
      tx_type => tx_type,
      cmd_index => tx_cmd_index,
      argument => tx_argument,
      data => tx_data,
      mosi => sd_mosi
   );

end Behavioral;
