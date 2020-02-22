
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.Common.all;
use work.Common_Memory.all;

entity pma_checker is
   port (
      enable               : in     std_logic;
      address              : in     std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
      tlb_op               : in     t_tlb_op;
      cacheable            : out    std_logic;
      
      except_load          : out    std_logic;
      except_store         : out    std_logic;
      except_ifetch        : out    std_logic
   );
end pma_checker;

architecture Behavioral of pma_checker is
   signal matched_entry : pma_checker_entry;
   signal match_found : boolean;
   signal reads_allowed, writes_allowed, exec_allowed : boolean;
   signal access_exception : boolean;
begin
   -- Find a pma entry that matches the address, if one exists.
   -- There should only be at most one PMA entry for any address.
   find_match : process (address)
      variable entry : pma_checker_entry;
   begin
      match_found <= false;
      matched_entry <= PMA_REGION_MAIN_MEMORY;
      for i in 0 to N_PMA_ENTRIES - 1 loop
         entry := PMA_ENTRIES(i);
         if (unsigned(address) >= unsigned(entry.address_start)) and (unsigned(address) <= unsigned(entry.address_end)) then
            matched_entry <= entry;
            match_found <= true;
            exit;
         end if;
      end loop;
   end process find_match;
   
   -- check for PMA violations
   -- for now, check only access type and valid memory region
   check_violations : process (all)
   begin
      -- set default value to prevent latches
      except_load <= '0';
      except_store <= '0';
      except_ifetch <= '0';
      
      if enable = '1' then
         if (tlb_op = TLB_STORE) and ((writes_allowed = false) or (match_found = false)) then  -- check if writes allowed
            except_load <= '1';
         elsif (tlb_op = TLB_LOAD) and ((reads_allowed = false) or (match_found = false)) then  -- check if reads allowed
            except_store <= '1';
         elsif (tlb_op = TLB_IFETCH) and ((exec_allowed = false) or (match_found = false)) then  -- TODO: check that this is correct
            except_ifetch <= '1';
         end if;
      end if;
   end process check_violations;
   
   cacheable <= '1' when matched_entry.cacheability = MEM_CACHEABLE else
                '0';
   reads_allowed <= true when matched_entry.region_type = MEM_MAIN else
                    true when matched_entry.region_type = MEM_IO else
                    false;
   writes_allowed <= true when matched_entry.region_type = MEM_MAIN else
                     true when matched_entry.region_type = MEM_IO else
                     false;
   exec_allowed <= true when matched_entry.region_type = MEM_MAIN else
                   false;
end Behavioral;
