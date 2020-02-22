
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.all;
use work.Common_Memory.all;


entity tb_pma_checker is
end tb_pma_checker;


architecture Behavioral of tb_pma_checker is
   component pma_checker is
      port (
         address              : in     std_logic_vector(XLEN - 1 downto 0);
         funct3               : in     std_logic_vector(2 downto 0);  -- width of load/sore TODO: implement width check
         op_type              : in     T_MEM_OP;
         section_type         : in     T_MEM_SECTION;
         no_cache             : out    std_logic;  -- when '1' indicates that the address should not be cached
         
         except_load          : out    std_logic;
         except_store         : out    std_logic;
         except_ifetch        : out    std_logic
      );
   end component;
   
   signal address : std_logic_vector(XLEN - 1 downto 0);
   signal funct3 : std_logic_vector(2 downto 0);
   signal op_type : T_MEM_OP;
   signal section_type : T_MEM_SECTION;
   signal no_cache : std_logic;
   signal except_load, except_store, except_ifetch : std_logic;
begin
   UUT : pma_checker
      port map (
         address => address,
         funct3 => funct3,
         op_type => op_type,
         section_type => section_type,
         no_cache => no_cache,
         except_load => except_load,
         except_store => except_store,
         except_ifetch => except_ifetch
      );
      
      test_uut : process
      begin
         address <= X"20000000";
         funct3 <= "000";
         op_type <= MEM_STORE;
         section_type <= MEM_DATA;
         wait for 10 ns;
         op_type <= MEM_LOAD;
         wait for 10 ns;
         section_type <= MEM_INSTRUCTION;
         wait for 10 ns;
         address <= X"00000000";
         wait for 10 ns;
         address <= X"40000000";
         wait for 10 ns;
         section_type <= MEM_DATA;
         wait for 10 ns;
         wait;
      end process test_uut;

end Behavioral;
