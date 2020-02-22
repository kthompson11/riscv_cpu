-- axi4-lite master
-- 32-bit data and address lines

library ieee;
use ieee.std_logic_1164.all;

use work.constants_axi4l.all;


entity axi4l_master is
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
end axi4l_master;


architecture Behavioral of axi4l_master is
   type t_master_state is (ST_RESET, ST_READY, ST_WRITE_HS, ST_READ_HS, ST_WRITE_RESP, ST_READ_RESP, ST_OP_DONE);
   signal state : t_master_state;
   signal next_state : t_master_state;
begin
   ready <= '1' when (state = ST_READY) or (state = ST_OP_DONE) else '0';
   op_done <= '1' when state = ST_OP_DONE else '0';
   axi_out.awvalid <= '1' when state = ST_WRITE_HS else '0';
   axi_out.awprot <= "000";
   axi_out.wvalid <= '1' when state = ST_WRITE_HS else '0';
   axi_out.arvalid <= '1' when state = ST_READ_HS else '0';
   axi_out.arprot <= "000";
   axi_out.rready <= '1' when state = ST_READ_RESP else '0';
   axi_out.bready <= '1' when state = ST_WRITE_RESP else '0';


   get_next_state : process (all)
   begin
      case state is
         when ST_RESET =>
            next_state <= ST_READY;
         when ST_READY | ST_OP_DONE =>
            if op_start = '1' then
               if operation = AXI_READ then
                  next_state <= ST_READ_HS;
               else   -- AXI_WRITE
                  next_state <= ST_WRITE_HS;
               end if;
            else
               next_state <= ST_READY;
            end if;
         when ST_READ_HS =>
            if (axi_in.arready = '1') and (axi_out.arvalid = '1') then
               next_state <= ST_READ_RESP;
            else
               next_state <= ST_READ_HS;
            end if;
         when ST_WRITE_HS =>
            if (axi_in.awready = '1') and (axi_out.awvalid = '1') and (axi_in.wready = '1') and (axi_out.wvalid = '1') then
               next_state <= ST_WRITE_RESP;
            else
               next_state <= ST_WRITE_HS;
            end if;
         when ST_READ_RESP =>
            if (axi_out.rready = '1') and (axi_in.rvalid = '1') then
               next_state <= ST_OP_DONE;
            else
               next_state <= ST_READ_RESP;
            end if;
         when ST_WRITE_RESP =>
            if (axi_out.bready = '1') and (axi_in.bvalid = '1') then
               next_state <= ST_OP_DONE;
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
      
   lock_inputs : process (clk)
   begin
      if rising_edge(clk) then
         if (state = ST_READY) and (op_start = '1') and (operation = AXI_READ) then
            axi_out.araddr <= address;
         elsif (state = ST_READY) and (op_start = '1') and (operation = AXI_WRITE) then
            axi_out.awaddr <= address;
            axi_out.wdata <= write_data;
            axi_out.wstrobe <= strobe;
         end if;
      end if;
   end process lock_inputs;
   
   lock_read : process (clk)
   begin
      if rising_edge(clk) then
         if (state = ST_READ_RESP) and (next_state = ST_OP_DONE) then
            read_data <= axi_in.rdata;
         end if;
      end if;
   end process lock_read;

end Behavioral;
