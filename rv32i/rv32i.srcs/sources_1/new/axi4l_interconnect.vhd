
library ieee;
use ieee.std_logic_1164.all;

use work.constants_axi4l.all;


entity axi4l_interconnect is
   generic (
      N_SLAVES   : integer range 2 to 4 := 2;  -- number of slaves to connect to the interconnect
      ADDR_STARTS : t_axi4l_addr_starts(0 to N_SLAVES - 1) := (others => (others => '0'));
      ADDR_ENDS   : t_axi4l_addr_ends(0 to N_SLAVES - 1) := (others => (others => '0'))
   );
   port (
      clk         : in     std_logic;
      reset       : in     std_logic;
      
      -- from master
      m_axi_out   : in     t_axi4l_master_out;
      m_axi_in    : out    t_axi4l_master_in;
      
      -- to slaves
      s_axi_out  : in      t_axi4l_master_in_array(0 to N_SLAVES - 1);
      s_axi_in   : out     t_axi4l_master_out_array(0 to N_SLAVES - 1)
   );
end axi4l_interconnect;


architecture Behavioral of axi4l_interconnect is
   signal address : std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
   signal address_locked : boolean;
   signal read_request, write_request : boolean;
   signal addr_match : boolean;
   signal i_slave : integer range 0 to N_SLAVES - 1;
begin
   read_request <= true when m_axi_out.arvalid = '1' else false;  -- true when the master makes a read request
   write_request <= true when ((m_axi_out.awvalid = '1') and (m_axi_out.wvalid = '1')) else false;  -- true when the master makes a write request

   get_address : process (clk, reset)
   begin
      if reset = '1' then
         address_locked <= false;
      elsif rising_edge(clk) then
         if (address_locked = false) and write_request then
            address_locked <= true;
            address <= m_axi_out.awaddr;
         elsif (address_locked = false) and read_request then
            address_locked <= true;
            address <= m_axi_out.araddr;
         elsif address_locked and addr_match then
            if ((m_axi_out.rready = '1') and (s_axi_out(i_slave).rvalid = '1')) or ((m_axi_out.bready = '1') and (s_axi_out(i_slave).bvalid = '1')) then  -- response received
               address_locked <= false;
            end if;
         end if;
      end if;
   end process get_address;
   
   get_slave : process (all)
   begin
      i_slave <= 0;
      addr_match <= false;
      if address_locked then
         for i in 0 to N_SLAVES - 1 loop
            if (address >= ADDR_STARTS(i)) and (address <= ADDR_ENDS(i)) then
               addr_match <= true;
               i_slave <= i;
               exit;
            end if;
         end loop;
      end if;
   end process get_slave;
   
   -- connect the master to the addressed slave
   -- assumed that a valid address is always given
   m_axi_in <= s_axi_out(i_slave) when addr_match else axi4l_dummy_master_in;
   process (all)
   begin
      for i in 0 to N_SLAVES - 1 loop
         if (i = i_slave) and addr_match then
            s_axi_in(i) <= m_axi_out;
         else
            s_axi_in(i) <= axi4l_dummy_master_out;
         end if;
      end loop;
   end process;

end Behavioral;
