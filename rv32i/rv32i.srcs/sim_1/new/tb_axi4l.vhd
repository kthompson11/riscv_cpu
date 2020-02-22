
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.constants_axi4l.all;

entity tb_axi4l is
end tb_axi4l;

architecture Behavioral of tb_axi4l is
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
   
   component axi4l_slave is
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
   end component;
   
   component axi4l_interconnect is
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
   end component;
   
   constant N_SLAVES : integer := 4;
   
   signal clk, reset : std_logic;
   signal m_write_data, s_write_data, m_read_data, s_read_data : std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
   signal m_strobe, s_strobe : std_logic_vector(AXI4L_DATA_WIDTH / 8 - 1 downto 0);
   signal m_address, s_address : std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
   signal m_operation, s_operation : t_axi_op;
   signal m_op_start, s_op_start, m_op_done, s_op_done, m_ready, s_ready : std_logic;
   signal axi_m_out : t_axi4l_master_out;
   signal axi_m_in : t_axi4l_master_in;
   signal s_in : t_axi4l_master_out_array(0 to N_SLAVES - 1);
   signal s_out : t_axi4l_master_in_array(0 to N_SLAVES - 1);
   
   -- slave storage signals
   constant SLAVE_STORAGE_SIZE : integer := 16;  -- number of words
   type t_slave_storage is array(integer range <>) of std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
   signal slave_storage : t_slave_storage(0 to SLAVE_STORAGE_SIZE - 1);
   
   signal test_done : boolean := false;
   
begin
   UUT_master : axi4l_master 
      port map (
         clk,
         reset,
         m_write_data,
         m_strobe,
         m_read_data,
         m_address,
         m_operation,
         m_op_start,
         m_op_done,
         m_ready,
         axi_m_out,
         axi_m_in
      );
   
   UUT_slave : axi4l_slave
      port map (
         clk,
         reset,
         s_write_data,
         s_strobe,
         s_read_data,
         s_address,
         s_operation,
         s_op_start,
         s_op_done,
         s_ready,
         s_out(0),
         s_in(0)
      );
      
   UUT_interconnect : axi4l_interconnect
      generic map (
         N_SLAVES => 4,
         ADDR_STARTS => (X"10000000", X"00000000", X"20000000", X"30000000"),
         ADDR_ENDS => (X"1FFFFFFF", X"0FFFFFFF", X"2FFFFFFF", X"3FFFFFFF")
      )
      port map (
         clk => clk,
         reset => reset,
         m_axi_out => axi_m_out,
         m_axi_in => axi_m_in,
         s_axi_out => s_out,
         s_axi_in => s_in
      );
      
   test_master : process
   begin
      reset <= '1';
      wait until rising_edge(clk);
      reset <= '0';
      wait until rising_edge(clk);
      
      wait until rising_edge(clk) and (m_ready = '1');
      m_address <= X"0000000A";
      m_operation <= AXI_WRITE;
      m_write_data <= X"ABABABAB";
      m_strobe <= "0101";
      m_op_start <= '1';
      wait until rising_edge(clK);
      m_op_start <= '0';
      wait until rising_edge(clk) and (m_op_done = '1');
      
      m_operation <= AXI_READ;
      m_op_start <= '1';
      wait until rising_edge(clk);
      m_op_start <= '0';
      wait until rising_edge(clk) and (m_op_done = '1');
      
      test_done <= true;
      wait;
   end process test_master;
   
   slave_devices : process (clk, reset)
      variable iEntry : integer;
   begin
      if reset = '1' then
         for i in 0 to SLAVE_STORAGE_SIZE - 1 loop
            slave_storage(i) <= (others => '0');
            s_op_done <= '0';
            s_ready <= '1';
         end loop;
      elsif rising_edge(clk) then
         if s_op_start = '1' and (s_ready = '1') then
            s_op_done <= '1';
            s_ready <= '0';
            if s_operation = AXI_READ then
               s_read_data <= slave_storage(to_integer(unsigned(s_address)));
            else  -- AXI_WRITE
               iEntry := to_integer(unsigned(s_address));
               for i in 0 to AXI4L_DATA_WIDTH - 1 loop
                  if s_strobe(i / 8) = '1' then
                     slave_storage(iEntry)(i) <= s_write_data(i);
                  else
                     slave_storage(iEntry)(i) <= slave_storage(iEntry)(i);
                  end if;
               end loop;
            end if;
         elsif s_op_done = '1' then
            s_op_done <= '0';
            s_ready <= '1';
         end if;
      end if;
   end process slave_devices;
   
   clk_proc : process
   begin
      if not test_done then
         clk <= '1';
         wait for 5 ns;
         clk <= '0';
         wait for 5 ns;
      else
         wait;
      end if;
   end process clk_proc;
   
--   s_in(3 downto 1) <= (others => AXI4L_DUMMY_MASTER_OUT);
--   s_out(3 downto 1) <= (others => AXI4L_DUMMY_MASTER_IN);

end Behavioral;
