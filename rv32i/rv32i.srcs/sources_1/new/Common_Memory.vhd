-- Common_Memory.vhd --
-- Contains constants common to memory devices.

-- TODO: automate generating PMA entries

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.all;


package Common_Memory is
   constant PHYS_ADDR_WIDTH    : integer := 34;
   constant VIRT_ADDR_WIDTH    : integer := 32;
   
   constant SATP_MODE          : integer := 31;
   constant SATP_ASID_HIGH     : integer := 30;
   constant SATP_ASID_LOW      : integer := 22;
   constant SATP_PPN_HIGH      : integer := 21;
   constant SATP_PPN_LOW       : integer := 0;
   constant SATP_ASID_LEN      : integer := SATP_ASID_HIGH - SATP_ASID_LOW + 1;
   constant SATP_PPN_LEN       : integer := SATP_PPN_HIGH - SATP_PPN_LOW + 1;

   -- page file constants
   constant SV32_OFFSET_BITS   : integer := 12;
   constant SV32_PAGE_SIZE     : integer := 2**SV32_OFFSET_BITS;
   constant SV32_LEVELS        : integer := 2;
   constant SV32_PTESIZE       : integer := 4;
   constant SV32_ASID_LEN      : integer := 6;
   -- pte fields
   constant SV32_PTE_PPN1_HIGH : integer := 31;
   constant SV32_PTE_PPN1_LOW  : integer := 20;
   constant SV32_PTE_PPN0_HIGH : integer := 19;
   constant SV32_PTE_PPN0_LOW  : integer := 10;
   constant SV32_PTE_RSW_HIGH  : integer := 9;
   constant SV32_PTE_RSW_LOW   : integer := 8;
   constant SV32_PTE_D         : integer := 7;
   constant SV32_PTE_A         : integer := 6;
   constant SV32_PTE_G         : integer := 5;
   constant SV32_PTE_U         : integer := 4;
   constant SV32_PTE_X         : integer := 3;
   constant SV32_PTE_W         : integer := 2;
   constant SV32_PTE_R         : integer := 1;
   constant SV32_PTE_V         : integer := 0;
   constant SV32_PTE_PPN1_LEN  : integer := SV32_PTE_PPN1_HIGH - SV32_PTE_PPN1_LOW + 1;
   constant SV32_PTE_PPN0_LEN  : integer := SV32_PTE_PPN0_HIGH - SV32_PTE_PPN0_LOW + 1;
   constant SV32_PTE_RSW_LEN   : integer := SV32_PTE_RSW_HIGH - SV32_PTE_RSW_LOW - 1;
   
   -- virtual address indices and lengths
   constant SV32_VA_VPN1_HIGH   : integer := 31;
   constant SV32_VA_VPN1_LOW    : integer := 22;
   constant SV32_VA_VPN0_HIGH   : integer := 21;
   constant SV32_VA_VPN0_LOW    : integer := 12;
   constant SV32_VA_OFFSET_HIGH : integer := 11;
   constant SV32_VA_OFFSET_LOW  : integer := 0;
   constant SV32_VA_VPN1_LEN    : integer := SV32_VA_VPN1_HIGH - SV32_VA_VPN1_LOW + 1;
   constant SV32_VA_VPN0_LEN    : integer := SV32_VA_VPN0_HIGH - SV32_VA_VPN0_LOW + 1;
   constant SV32_VA_OFFSET_LEN  : integer := SV32_VA_OFFSET_HIGH - SV32_VA_OFFSET_LOW + 1;

   -- cache types and constants
   type t_tlb_op is (TLB_STORE, TLB_LOAD, TLB_IFETCH);
   type t_mem_op_width is (MEM_WIDTH_WORD, MEM_WIDTH_HALF, MEM_WIDTH_BYTE);

   type T_MEM_REGION is (MEM_MAIN, MEM_IO, MEM_EMPTY);  -- main=rwx, io=rw (some writes may be ignored), empty=no rw
   type T_MEM_ACCESS is (MEM_8BIT, MEM_16BIT, MEM_32BIT);  -- NOTE: not used, all access types are supported
   type T_MEM_ATOMICITY is (AMO_LRSC, AMO_NONE, AMO_SWAP, AMO_LOGICAL, AMO_ARITHMETIC);  -- NOTE: no atomic operations for now
   type T_MEM_CACHEABILITY is (MEM_CACHEABLE, MEM_NOTCACHEABLE);
   
   type pma_checker_entry is record
      address_start     : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
      address_end       : std_logic_vector(PHYS_ADDR_WIDTH - 1 downto 0);
      region_type       : T_MEM_REGION;
      cacheability      : T_MEM_CACHEABILITY;
   end record pma_checker_entry;
   
   constant PMA_REGION_MAIN_MEMORY : pma_checker_entry := (address_start => "00" & X"10000000",
                                                           address_end   => "00" & X"1FFFFFFF",
                                                           region_type   => MEM_MAIN,
                                                           cacheability  => MEM_CACHEABLE);
   constant PMA_REGION_ONBOARD_FLASH : pma_checker_entry := (address_start => "00" & X"40000000",
                                                             address_end   => "00" & X"40FFFFFF",
                                                             region_type   => MEM_IO,
                                                             cacheability  => MEM_NOTCACHEABLE);
   constant PMA_REGION_UART : pma_checker_entry := (address_start => "00" & X"41000000",
                                                    address_end   => "00" & X"41FFFFFF",
                                                    region_type   => MEM_IO,
                                                    cacheability  => MEM_NOTCACHEABLE);                                        
   
   constant N_PMA_ENTRIES : integer := 3;
   type t_pma_entries is array (0 to N_PMA_ENTRIES - 1) of pma_checker_entry;                            
   constant PMA_ENTRIES : t_pma_entries := (PMA_REGION_MAIN_MEMORY,
                                            PMA_REGION_ONBOARD_FLASH,
                                            PMA_REGION_UART);
end Common_Memory;


package body Common_Memory is
end Common_Memory;
