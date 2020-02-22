
library ieee;
use ieee.std_logic_1164.all;

package constants_axi4l is
   -- define data width and address length here due to poor generic package support
   constant AXI4L_DATA_WIDTH : integer := 32;
   constant AXI4L_ADDR_LENGTH : integer := 32;

   type t_axi_op is (AXI_READ, AXI_WRITE);
   
   type t_axi4l_master_out is record
      -- write address ports
      awvalid     :    std_logic;
      awaddr      :    std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
      awprot      :    std_logic_vector(2 downto 0); -- unused
      
      -- write data ports
      wvalid      :    std_logic;
      wdata       :    std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
      wstrobe     :    std_logic_vector(AXI4L_DATA_WIDTH / 8 - 1 downto 0);
      
      -- write response ports
      bready      :    std_logic;
      
      -- read address ports
      arvalid     :    std_logic;
      araddr      :    std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
      arprot      :    std_logic_vector(2 downto 0);  -- unsused
      
      -- read data ports
      rready      :    std_logic;
   end record t_axi4l_master_out;
   
   type t_axi4l_master_in is record
      -- write address ports
      awready     :     std_logic;
      
      -- write data ports
      wready      :     std_logic;
      
      -- write response ports
      bvalid      :     std_logic;
      bresp       :     std_logic_vector(1 downto 0);
      
      -- read address ports
      arready     :     std_logic;
      
      -- read data ports
      rvalid      :     std_logic;
      rdata       :     std_logic_vector(AXI4L_DATA_WIDTH - 1 downto 0);
      rresp       :     std_logic_vector(1 downto 0);
   end record t_axi4l_master_in;
   
   constant MAX_INTERCONNECT_SLAVES : integer := 4;  -- maximum number of slaves that can be connected to an interconnect
   type t_axi4l_master_out_array is array(integer range <>) of t_axi4l_master_out;
   type t_axi4l_master_in_array is array(integer range <>) of t_axi4l_master_in;
   type t_axi4l_addr_starts is array(integer range <>) of std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
   type t_axi4l_addr_ends is array(integer range <>) of std_logic_vector(AXI4L_ADDR_LENGTH - 1 downto 0);
   
   constant AXI4L_DUMMY_MASTER_IN : t_axi4l_master_in := (awready => '0',
                                                          wready => '0',
                                                          bvalid => '0',
                                                          bresp => (others => '-'),
                                                          arready => '0',
                                                          rvalid => '0',
                                                          rdata => (others => '-'),
                                                          rresp => (others => '-'));
   constant AXI4L_DUMMY_MASTER_OUT : t_axi4l_master_out := (awvalid => '0',
                                                            awaddr => (others => '-'),
                                                            awprot => (others => '-'),
                                                            wvalid => '0',
                                                            wdata => (others => '-'),
                                                            wstrobe => (others => '-'),
                                                            bready => '0',
                                                            arvalid => '0',
                                                            araddr => (others => '-'),
                                                            arprot => (others => '-'),
                                                            rready => '0');
   
end constants_axi4l;


package body constants_axi4l is
end constants_axi4l;
