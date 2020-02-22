-- misa.vhd --
-- Description of the "misa" (Machine ISA) register.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.all;
use work.Common_CSR.all;

entity misa is
   port (
      clk               : in     std_logic;
      reset             : in     std_logic; 
      
      -- CSR bus lines
      csr_address_line  : in     std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
      csr_read_line     : out    std_logic_vector(XLEN - 1 downto 0);
      csr_write_line    : in     std_logic_vector(XLEN - 1 downto 0);
      csr_int_line      : out    std_logic;
      csr_we_line       : in     std_logic
   );
end misa;


architecture Behavioral of misa is
   component csr_generic is
      generic (
         bit_modes         : CSR_BIT_MODE_ARRAY;
         bit_defaults      : std_logic_vector(XLEN - 1 downto 0);
         csr_address       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
         use_address2      : boolean := false;
         csr_address2      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := (others => '-');
         use_address3      : boolean := false;
         csr_address3      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := (others => '-')
      );
      port (
         clk               : in     std_logic;
         reset             : in     std_logic;
         --privilege_level   
         
         -- CSR bus lines
         csr_address_line  : in     std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0);
         csr_read_line     : out    std_logic_vector(XLEN - 1 downto 0);
         csr_write_line    : in     std_logic_vector(XLEN - 1 downto 0);
         csr_int_line      : out    std_logic;
         csr_we_line       : in     std_logic;
         
         -- connections to register read/write unit (if applicable)
         direct_read       : out    std_logic_vector(XLEN - 1 downto 0);
         direct_write      : in     std_logic_vector(XLEN - 1 downto 0);
         direct_we         : in     std_logic_vector(XLEN - 1 downto 0)
      );
   end component;
   
   signal temp_a, temp_b, temp_c : std_logic_vector(XLEN - 1 downto 0);
begin
   csr_io : csr_generic
      generic map (
         bit_modes => (others => CSR_WI),
         bit_defaults => (others => '0'),
         csr_address => "010101010101",
         use_address2 => true,
         csr_address2 => "111111000000"
      )
      port map (
         clk => clk,
         reset => reset,
         csr_address_line => csr_address_line,
         csr_read_line => csr_read_line,
         csr_write_line => csr_write_line,
         csr_int_line => csr_int_line,
         csr_we_line => csr_we_line,
         direct_read => temp_a,
         direct_write => temp_b,
         direct_we => temp_c
      );


end Behavioral;
