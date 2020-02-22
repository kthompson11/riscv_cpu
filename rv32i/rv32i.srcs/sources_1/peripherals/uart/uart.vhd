
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants_axi4l.all;
use work.constants_uart.all;
use work.tools.ceil_log2;

entity uart is
   port (
      clk         : in     std_logic;
      reset       : in     std_logic;
      interrupt   : out    std_logic;  -- TODO: figure out when to send an interrupt
      
      -- axi ports
      axi_out     : out    t_axi4l_master_in;
      axi_in      : in     t_axi4l_master_out;
      
      -- uart ports
      tx          : out    std_logic;
      rx          : in     std_logic
   );
end uart;

architecture Behavioral of uart is

   component axi4l_slave is
      port (
         clk         : in     std_logic;
         reset       : in     std_logic;
         write_data  : out    std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
         strobe      : out    std_logic_vector(AXI4L_DATA_WIDTH / 8 - 1 downto 0);
         read_data   : in     std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
         address     : out    std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
         operation   : out    t_axi_op;
         op_start    : out    std_logic;
         op_done     : in     std_logic;
         ready       : in     std_logic;
         
         axi_out     : out    t_axi4l_master_in;
         axi_in      : in     t_axi4l_master_out
      );
   end component;

   component uart_rx_control is
      port(RX       : in std_logic;
           RX_READY : out std_logic;
           RX_DATA  : out std_logic_vector(7 downto 0);
           CLK      : in std_logic;
           RESET    : in std_logic);
   end component;
   
   component uart_tx_control is
      port(TX       : out std_logic;
           TX_READY : out std_logic;
           TX_START  : in std_logic;
           TX_DATA  : in std_logic_vector(7 downto 0);
           CLK      : in std_logic;
           RESET    : in std_logic);
   end component;
   
   signal write_data : std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
   signal strobe : std_logic_vector(AXI4L_DATA_WIDTH / 8 - 1 downto 0);
   signal read_data : std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
   signal address : std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
   signal operation : t_axi_op;
   signal op_start, op_done, slave_ready : std_logic;
   
   signal rx_ready, tx_ready : std_logic;
   signal tx_start : std_logic;
   signal rx_data, tx_data : std_logic_vector(7 downto 0);
   
   -- uart state
   type t_uart_state is (ST_RESET, ST_READY, ST_WRITE, ST_READ, ST_OP_DONE);
   signal state, next_state : t_uart_state;
   
   -- tx signals
   type t_buffer_storage is array(integer range <>) of std_logic_vector(7 downto 0);
   constant TX_BUFFER_SIZE : integer := 16;  -- bytes
   constant TX_BUFFER_BITS : integer := ceil_log2(TX_BUFFER_SIZE);
   signal tx_buffer : t_buffer_storage(0 to TX_BUFFER_SIZE - 1);
   signal write_bytes_avail : integer range 0 to TX_BUFFER_SIZE - 1;
   signal i_tx_start, i_tx_end : integer range 0 to TX_BUFFER_SIZE - 1;  -- end = 1 after last element
   signal tx_next_byte : std_logic_vector(7 downto 0);
   
   -- rx signals
   constant RX_BUFFER_SIZE : integer := 1024;
   constant RX_BUFFER_BITS : integer := ceil_log2(RX_BUFFER_SIZE);
   signal rx_buffer : t_buffer_storage(0 to RX_BUFFER_SIZE - 1);
   signal read_bytes_avail : integer range 0 to RX_BUFFER_SIZE - 1;
   signal i_rx_start, i_rx_end : integer range 0 to RX_BUFFER_SIZE - 1;
   signal rx_next_byte : std_logic_vector(7 downto 0);
   
   signal address_offset : std_logic_vector(ADDRESS_OFFSET_SIZE - 1 downto 0);
   signal valid_write_address, valid_read_address, valid_status_address : boolean;
   signal op_last_byte : boolean;
   signal i_op, i_op_max : integer range 0 to AXI4L_DATA_WIDTH / 8 - 1;  -- index of current byte to read/write (and the max value)
begin
   axi_slave : axi4l_slave
      port map (clk => clk,
                reset => reset,
                write_data => write_data,
                strobe => strobe,
                read_data => read_data,
                address => address,
                operation => operation,
                op_start => op_start,
                op_done => op_done,
                ready => slave_ready,
                axi_out => axi_out,
                axi_in => axi_in);
                
   uart_rx : uart_rx_control
      port map (RX => rx,
                RX_READY => rx_ready,
                RX_DATA => rx_data,
                CLK => clk,
                RESET => reset);

   uart_tx : uart_tx_control
      port map (TX => tx,
                TX_READY => tx_ready, 
                TX_START => tx_start,
                TX_DATA => tx_data,
                CLK => clk,
                RESET => reset);
                
   get_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            next_state <= ST_READY;
         when ST_READY =>
            if (op_start = '1') and (operation = AXI_WRITE) and valid_write_address then
               next_state <= ST_WRITE;
            elsif (op_start = '1') and (operation = AXI_READ) and valid_read_address then
               next_state <= ST_READ;
            elsif (op_start = '1') and (operation = AXI_READ) and valid_status_address then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_READY;
            end if;
         when ST_WRITE =>
            if op_last_byte then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_WRITE;
            end if;
         when ST_READ =>
            if op_last_byte then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_READ;
            end if;
         when ST_OP_DONE =>
            next_state <= ST_READY;
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
   
   
   write_bytes_avail <= to_integer(to_unsigned(TX_BUFFER_SIZE, TX_BUFFER_BITS) - (to_unsigned(i_tx_end, TX_BUFFER_BITS) - to_unsigned(i_tx_start, TX_BUFFER_BITS)) - 1);
   read_bytes_avail <= to_integer(to_unsigned(i_rx_end, RX_BUFFER_BITS) - to_unsigned(i_rx_start, RX_BUFFER_BITS));   
   read_write : process (reset, clk)
   begin
      if reset = '1' then
         i_tx_end <= 0;
         i_rx_start <= 0;
      elsif rising_edge(clk) then
         if (state = ST_READY) and (next_state = ST_OP_DONE) then  -- status read (available in 1 cycle)
            if address_offset = UART_OFFSET_READ_BYTES_AVAIL then
               read_data <= std_logic_vector(to_unsigned(read_bytes_avail, AXI4L_DATA_WIDTH));
            elsif address_offset = UART_OFFSET_WRITE_BYTES_AVAIL then
               read_data <= std_logic_vector(to_unsigned(write_bytes_avail, AXI4L_DATA_WIDTH));
            end if;
         elsif (state = ST_READY) and (next_state = ST_WRITE) then
            -- set the max write index
            -- strobe assumed to always be valid
            if strobe(3) = '1' then
               i_op_max <= 3;
            elsif strobe(1) = '1' then
               i_op_max <= 1;
            else
               i_op_max <= 0;
            end if;
            
            i_op <= 0;
         elsif (state = ST_READY) and (next_state = ST_READ) then
            -- set the max read index
            if address = UART_OFFSET_READ_WORD then
               i_op_max <= 3;
            elsif address = UART_OFFSET_READ_HALF then
               i_op_max <= 1;
            elsif address_offset = UART_OFFSET_READ_BYTE then
               i_op_max <= 0;
            end if;
            
            -- preload first byte
            rx_next_byte <= rx_buffer(i_rx_start);
            i_rx_start <= i_rx_start + 1;
            
            i_op <= 0;
         elsif state = ST_WRITE then
            -- write out 1 byte at a time to the tx buffer
            if i_op <= i_op_max then
               tx_buffer(i_tx_end) <= write_data((i_op + 1) * 8 - 1 downto i_op * 8);
               if i_tx_end = TX_BUFFER_SIZE - 1 then
                  i_tx_end <= 0;
               else
                  i_tx_end <= i_tx_end + 1;
               end if;
            end if;
            i_op <= i_op + 1;
         elsif state = ST_READ then
            -- read in 1 byte at a time from the rx buffer
            -- read out the next byte
            read_data(((i_op + 1) * 8) - 1 downto i_op * 8) <= rx_next_byte;
            
            if i_op /= i_op_max then  -- preload another byte
               rx_next_byte <= rx_buffer(i_rx_start);
               if i_rx_start = RX_BUFFER_SIZE - 1 then
                  i_rx_start <= 0;
               else
                  i_rx_start <= i_rx_start + 1;
               end if;
            end if;
         end if;
      end if;
   end process read_write;
   
   address_offset <= address(ADDRESS_OFFSET_SIZE - 1 downto 0);
   valid_write_address <= true when address_offset = UART_OFFSET_WRITE else false;
   with address_offset select
      valid_read_address <= true when UART_OFFSET_READ_WORD | UART_OFFSET_READ_HALF | UART_OFFSET_READ_BYTE,
                            false when others;
   valid_status_address <= true when address_offset = UART_OFFSET_READ_BYTES_AVAIL else
                           true when address_offset = UART_OFFSET_WRITE_BYTES_AVAIL else
                           false;
   op_done <= '1' when state = ST_OP_DONE else '0';
   op_last_byte <= true when i_op = i_op_max else false;
   slave_ready <= '1' when state = ST_READY else '0';
   
   
   ----------------------------------------------------------------------------------------------------------------------
   -------------------------------------------------- tx control --------------------------------------------------------
   ----------------------------------------------------------------------------------------------------------------------

   tx_control : process (reset, clk)
   begin
      if reset = '1' then
         i_tx_start <= 0;
      elsif rising_edge(clk) then
         if (tx_ready = '1') and (i_tx_start /= i_tx_end) and (tx_start = '0') then
            tx_data <= tx_buffer(i_tx_start);
            if i_tx_start = TX_BUFFER_SIZE - 1 then
               i_tx_start <= 0;
            else
               i_tx_start <= i_tx_start + 1;
            end if;
            tx_start <= '1';
         else
            tx_start <= '0';
         end if;
      end if;
   end process tx_control;


   ----------------------------------------------------------------------------------------------------------------------
   -------------------------------------------------- rx control --------------------------------------------------------
   ----------------------------------------------------------------------------------------------------------------------
   
   rx_control : process (reset, clk)
   begin
      if reset = '1' then
         i_rx_end <= 0;
      elsif rising_edge(clk) then
         if (rx_ready = '1') and (i_rx_end /= i_rx_start) then
            rx_buffer(i_rx_end) <= rx_data;
            if i_rx_end = RX_BUFFER_SIZE - 1 then
               i_rx_end <= 0;
            else
               i_rx_end <= i_rx_end + 1;
            end if;
         end if;
      end if;
   end process rx_control;
                
end Behavioral;
