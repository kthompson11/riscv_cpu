-- axi4-lite slave
-- 32-bit data and address lines

library ieee;
use ieee.std_logic_1164.all;

use work.constants_axi4l.all;


entity axi4l_slave is
   port (
      clk         : in     std_logic;  -- ACLK
      reset       : in     std_logic;  -- RESETn (except active high)
      write_data  : out    std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);      -- data to write
      strobe      : out    std_logic_vector(AXI4L_DATA_WIDTH / 8 - 1 downto 0);
      read_data   : in     std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);      -- data read
      address     : out    std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);  -- address to access
      operation   : out    t_axi_op;
      op_start    : out    std_logic;
      op_done     : in     std_logic;
      ready       : in     std_logic;
      
      axi_out     : out    t_axi4l_master_in;
      axi_in      : in     t_axi4l_master_out
   );
end axi4l_slave;


architecture Behavioral of axi4l_slave is
   type t_slave_state is (ST_RESET, ST_READY, ST_READ_WAIT_DONE, ST_WRITE_WAIT_DONE, ST_READ_RESP, ST_WRITE_RESP, ST_READ_WAIT_READY, ST_WRITE_WAIT_READY);
   signal state : t_slave_state;
   signal next_state : t_slave_state;
   signal read_hs : boolean;
   signal write_hs : boolean;
begin
   read_hs <= (axi_out.arready = '1') and (axi_in.arvalid = '1');
   write_hs <= (axi_out.awready = '1') and (axi_in.awvalid = '1') and (axi_out.wready = '1') and (axi_in.wvalid = '1');
   write_data <= axi_in.wdata;
   strobe <= axi_in.wstrobe;
   address <= axi_in.araddr when read_hs else axi_in.awaddr;
   operation <= AXI_READ when state = ST_READ_WAIT_READY else
                AXI_READ when (state = ST_READY) and read_hs else
                AXI_WRITE;
   op_start <= '1' when state = ST_READ_WAIT_READY else
               '1' when state = ST_WRITE_WAIT_READY else
               '1' when (state = ST_READY) and (next_state /= ST_READY) else
               '0';
   axi_out.bresp <= "00";
   axi_out.rresp <= "00";
   axi_out.awready <= '1' when state = ST_READY else '0';
   axi_out.wready <= '1' when state = ST_READY else '0';
   axi_out.arready <= '1' when state = ST_READY else '0';
   axi_out.rvalid <= '1' when state = ST_READ_RESP else '0';
   axi_out.bvalid <= '1' when state = ST_WRITE_RESP else '0';

   get_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            next_state <= ST_READY;
         when ST_READY =>
            if read_hs then
               if ready = '1' then
                  next_state <= ST_READ_WAIT_DONE;
               else
                  next_state <= ST_READ_WAIT_READY;
               end if;
            elsif write_hs then
               if ready = '1' then
                  next_state <= ST_WRITE_WAIT_DONE;
               else
                  next_state <= ST_WRITE_WAIT_READY;
               end if;
            else
               next_state <= ST_READY;
            end if;
         when ST_READ_WAIT_READY =>
            if ready = '1' then
               next_state <= ST_READ_WAIT_DONE;
            else
               next_state <= ST_READ_WAIT_READY;
            end if;
         when ST_WRITE_WAIT_READY =>
            if ready = '1' then
               next_state <= ST_WRITE_WAIT_DONE;
            else
               next_state <= ST_WRITE_WAIT_READY;
            end if;
         when ST_READ_WAIT_DONE =>
            if op_done = '1' then
               next_state <= ST_READ_RESP;
            else
               next_state <= ST_READ_WAIT_DONE;
            end if;
         when ST_WRITE_WAIT_DONE =>
            if op_done = '1' then
               next_state <= ST_WRITE_RESP;
            else
               next_state <= ST_WRITE_WAIT_DONE;
            end if;
         when ST_READ_RESP =>
            if (axi_in.rready = '1') and (axi_out.rvalid = '1') then
               next_state <= ST_READY;
            else
               next_state <= ST_READ_RESP;
            end if;
         when ST_WRITE_RESP =>
            if (axi_in.bready = '1') and (axi_out.bvalid = '1') then
               next_state <= ST_READY;
            else
               next_state <= ST_WRITE_RESP;
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
   
   lock_read_data : process (clk)
   begin
      if rising_edge(clk) then
         if (state = ST_READ_WAIT_DONE) and (next_state = ST_READ_RESP) then
            axi_out.rdata <= read_data;
         end if;
      end if;
   end process lock_read_data;

end Behavioral;
