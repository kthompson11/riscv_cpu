-- Common_CSR.vhd --
-- Contains types common to CSRs.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.Common.all;


package Common_CSR is
   constant N_CSR_ADDRESS_BITS : integer := 12;
   
   -- indices of operands in a CSR instruction
   constant INSTRUCTION_CSR_ADDRESS_HIGH : integer := 31;
   constant INSTRUCTION_CSR_ADDRESS_LOW  : integer := 20;
   constant INSTRUCTION_CSR_UIMM_HIGH    : integer := 19;
   constant INSTRUCTION_CSR_UIMM_LOW     : integer := 15;
   constant INSTRUCTION_CSR_OP_HIGH      : integer := 14;
   constant INSTRUCTION_CSR_OP_LOW       : integer := 12;
   constant INSTRUCTION_CSR_RD_HIGH      : integer := 11;
   constant INSTRUCTION_CSR_RD_LOW       : integer := 7;
   constant INSTRUCTION_CSR_RS_HIGH      : integer := 19;
   constant INSTRUCTION_CSR_RS_LOW       : integer := 15;
   
   -- indices of fields within the CSR address
   constant CSR_ADDRESS_ACCESS_HIGH      : integer := 11;
   constant CSR_ADDRESS_ACCESS_LOW       : integer := 10;
   constant CSR_ADDRESS_PRIV_HIGH        : integer := 9;
   constant CSR_ADDRESS_PRIV_LOW         : integer := 8;
   
   constant CSR_ACCESSIBILITY_RO : std_logic_vector(1 downto 0) := "11";
   
   -- csr counter indices
   constant COUNTER_HIGH   : integer := 31;
   constant COUNTER_LOW    : integer := 0;
   constant COUNTERH_HIGH  : integer := 63;
   constant COUNTERH_LOW   : integer := 32;
   
   
   -------------------------------------------------------------------------------------------------------
   ---------------------------------- CSR register addresses ---------------------------------------------
   -------------------------------------------------------------------------------------------------------
   
   -- machine CSRs
   constant CSR_MVENDORID_ADDRESS          : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"F11";
   constant CSR_MARCHID_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"F12";
   constant CSR_MIMPID_ADDRESS             : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"F13";
   constant CSR_MHARTID_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"F14";
   constant CSR_MSTATUS_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"300";
   constant CSR_MISA_ADDRESS               : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"301";
   constant CSR_MEDELEG_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"302";
   constant CSR_MIDELEG_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"303";
   constant CSR_MIE_ADDRESS                : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"304";
   constant CSR_MTVEC_ADDRESS              : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"305";
   constant CSR_MCOUNTEREN_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"306";
   constant CSR_MSCRATCH_ADDRESS           : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"340";
   constant CSR_MEPC_ADDRESS               : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"341";
   constant CSR_MCAUSE_ADDRESS             : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"342";
   constant CSR_MTVAL_ADDRESS              : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"343";
   constant CSR_MIP_ADDRESS                : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"344";
   constant CSR_MHPMEVENT3_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"323";
   constant CSR_MHPMEVENT4_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"324";
   constant CSR_MHPMEVENT5_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"325";
   constant CSR_MHPMEVENT6_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"326";
   constant CSR_MHPMEVENT7_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"327";
   constant CSR_MHPMEVENT8_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"328";
   constant CSR_MHPMEVENT9_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"329";
   constant CSR_MHPMEVENT10_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"32A";
   constant CSR_MHPMEVENT11_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"32B";
   constant CSR_MHPMEVENT12_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"32C";
   constant CSR_MHPMEVENT13_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"32D";
   constant CSR_MHPMEVENT14_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"32E";
   constant CSR_MHPMEVENT15_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"32F";
   constant CSR_MHPMEVENT16_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"330";
   constant CSR_MHPMEVENT17_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"331";
   constant CSR_MHPMEVENT18_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"332";
   constant CSR_MHPMEVENT19_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"333";
   constant CSR_MHPMEVENT20_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"334";
   constant CSR_MHPMEVENT21_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"335";
   constant CSR_MHPMEVENT22_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"336";
   constant CSR_MHPMEVENT23_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"337";
   constant CSR_MHPMEVENT24_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"338";
   constant CSR_MHPMEVENT25_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"339";
   constant CSR_MHPMEVENT26_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"33A";
   constant CSR_MHPMEVENT27_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"33B";
   constant CSR_MHPMEVENT28_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"33C";
   constant CSR_MHPMEVENT29_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"33D";
   constant CSR_MHPMEVENT30_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"33E";
   constant CSR_MHPMEVENT31_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"33F";
   
   -- machine counter/timers
   constant CSR_MCYCLE_ADDRESS             : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B00";
   constant CSR_MINSTRET_ADDRESS           : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B02";
   constant CSR_MHPMCOUNTER3_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B03";
   constant CSR_MHPMCOUNTER4_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B04";
   constant CSR_MHPMCOUNTER5_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B05";
   constant CSR_MHPMCOUNTER6_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B06";
   constant CSR_MHPMCOUNTER7_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B07";
   constant CSR_MHPMCOUNTER8_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B08";
   constant CSR_MHPMCOUNTER9_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B09";
   constant CSR_MHPMCOUNTER10_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B0A";
   constant CSR_MHPMCOUNTER11_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B0B";
   constant CSR_MHPMCOUNTER12_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B0C";
   constant CSR_MHPMCOUNTER13_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B0D";
   constant CSR_MHPMCOUNTER14_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B0E";
   constant CSR_MHPMCOUNTER15_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B0F";
   constant CSR_MHPMCOUNTER16_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B10";
   constant CSR_MHPMCOUNTER17_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B11";
   constant CSR_MHPMCOUNTER18_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B12";
   constant CSR_MHPMCOUNTER19_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B13";
   constant CSR_MHPMCOUNTER20_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B14";
   constant CSR_MHPMCOUNTER21_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B15";
   constant CSR_MHPMCOUNTER22_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B16";
   constant CSR_MHPMCOUNTER23_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B17";
   constant CSR_MHPMCOUNTER24_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B18";
   constant CSR_MHPMCOUNTER25_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B19";
   constant CSR_MHPMCOUNTER26_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B1A";
   constant CSR_MHPMCOUNTER27_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B1B";
   constant CSR_MHPMCOUNTER28_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B1C";
   constant CSR_MHPMCOUNTER29_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B1D";
   constant CSR_MHPMCOUNTER30_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B1E";
   constant CSR_MHPMCOUNTER31_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B1F";
   constant CSR_MCYCLEH_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B80";
   constant CSR_MINSTRETH_ADDRESS          : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B82";
   constant CSR_MHPMCOUNTER3H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B83";
   constant CSR_MHPMCOUNTER4H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B84";
   constant CSR_MHPMCOUNTER5H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B85";
   constant CSR_MHPMCOUNTER6H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B86";
   constant CSR_MHPMCOUNTER7H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B87";
   constant CSR_MHPMCOUNTER8H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B88";
   constant CSR_MHPMCOUNTER9H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B89";
   constant CSR_MHPMCOUNTER10H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B8A";
   constant CSR_MHPMCOUNTER11H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B8B";
   constant CSR_MHPMCOUNTER12H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B8C";
   constant CSR_MHPMCOUNTER13H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B8D";
   constant CSR_MHPMCOUNTER14H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B8E";
   constant CSR_MHPMCOUNTER15H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B8F";
   constant CSR_MHPMCOUNTER16H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B90";
   constant CSR_MHPMCOUNTER17H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B91";
   constant CSR_MHPMCOUNTER18H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B92";
   constant CSR_MHPMCOUNTER19H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B93";
   constant CSR_MHPMCOUNTER20H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B94";
   constant CSR_MHPMCOUNTER21H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B95";
   constant CSR_MHPMCOUNTER22H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B96";
   constant CSR_MHPMCOUNTER23H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B97";
   constant CSR_MHPMCOUNTER24H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B98";
   constant CSR_MHPMCOUNTER25H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B99";
   constant CSR_MHPMCOUNTER26H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B9A";
   constant CSR_MHPMCOUNTER27H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B9B";
   constant CSR_MHPMCOUNTER28H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B9C";
   constant CSR_MHPMCOUNTER29H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B9D";
   constant CSR_MHPMCOUNTER30H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B9E";
   constant CSR_MHPMCOUNTER31H_ADDRESS     : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"B9F";
   
   -- supervisor CSRs
   constant CSR_SSTATUS_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"100";
   constant CSR_SEDELEG_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"102";
   constant CSR_SIDELEG_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"103";
   constant CSR_SIE_ADDRESS                : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"104";
   constant CSR_STVEC_ADDRESS              : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"105";
   constant CSR_SCOUNTEREN_ADDRESS         : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"106";
   constant CSR_SSCRATCH_ADDRESS           : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"140";
   constant CSR_SEPC_ADDRESS               : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"141";
   constant CSR_SCAUSE_ADDRESS             : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"142";
   constant CSR_STVAL_ADDRESS              : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"143";
   constant CSR_SIP_ADDRESS                : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"144";
   constant CSR_SATP_ADDRESS               : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"180";
   
   -- user CSRs
   
   -- user counters/timers
   constant CSR_CYCLE_ADDRESS              : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C00";
   constant CSR_INSTRET_ADDRESS            : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C02";
   constant CSR_HPMCOUNTER3_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C03";
   constant CSR_HPMCOUNTER4_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C04";
   constant CSR_HPMCOUNTER5_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C05";
   constant CSR_HPMCOUNTER6_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C06";
   constant CSR_HPMCOUNTER7_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C07";
   constant CSR_HPMCOUNTER8_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C08";
   constant CSR_HPMCOUNTER9_ADDRESS        : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C09";
   constant CSR_HPMCOUNTER10_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C0A";
   constant CSR_HPMCOUNTER11_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C0B";
   constant CSR_HPMCOUNTER12_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C0C";
   constant CSR_HPMCOUNTER13_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C0D";
   constant CSR_HPMCOUNTER14_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C0E";
   constant CSR_HPMCOUNTER15_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C0F";
   constant CSR_HPMCOUNTER16_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C10";
   constant CSR_HPMCOUNTER17_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C11";
   constant CSR_HPMCOUNTER18_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C12";
   constant CSR_HPMCOUNTER19_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C13";
   constant CSR_HPMCOUNTER20_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C14";
   constant CSR_HPMCOUNTER21_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C15";
   constant CSR_HPMCOUNTER22_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C16";
   constant CSR_HPMCOUNTER23_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C17";
   constant CSR_HPMCOUNTER24_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C18";
   constant CSR_HPMCOUNTER25_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C19";
   constant CSR_HPMCOUNTER26_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C1A";
   constant CSR_HPMCOUNTER27_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C1B";
   constant CSR_HPMCOUNTER28_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C1C";
   constant CSR_HPMCOUNTER29_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C1D";
   constant CSR_HPMCOUNTER30_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C1E";
   constant CSR_HPMCOUNTER31_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C1F";
   constant CSR_CYCLEH_ADDRESS             : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C80";
   constant CSR_INSTRETH_ADDRESS           : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C82";
   constant CSR_HPMCOUNTER3H_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C83";
   constant CSR_HPMCOUNTER4H_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C84";
   constant CSR_HPMCOUNTER5H_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C85";
   constant CSR_HPMCOUNTER6H_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C86";
   constant CSR_HPMCOUNTER7H_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C87";
   constant CSR_HPMCOUNTER8H_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C88";
   constant CSR_HPMCOUNTER9H_ADDRESS       : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C89";
   constant CSR_HPMCOUNTER10H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C8A";
   constant CSR_HPMCOUNTER11H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C8B";
   constant CSR_HPMCOUNTER12H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C8C";
   constant CSR_HPMCOUNTER13H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C8D";
   constant CSR_HPMCOUNTER14H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C8E";
   constant CSR_HPMCOUNTER15H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C8F";
   constant CSR_HPMCOUNTER16H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C90";
   constant CSR_HPMCOUNTER17H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C91";
   constant CSR_HPMCOUNTER18H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C92";
   constant CSR_HPMCOUNTER19H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C93";
   constant CSR_HPMCOUNTER20H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C94";
   constant CSR_HPMCOUNTER21H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C95";
   constant CSR_HPMCOUNTER22H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C96";
   constant CSR_HPMCOUNTER23H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C97";
   constant CSR_HPMCOUNTER24H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C98";
   constant CSR_HPMCOUNTER25H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C99";
   constant CSR_HPMCOUNTER26H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C9A";
   constant CSR_HPMCOUNTER27H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C9B";
   constant CSR_HPMCOUNTER28H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C9C";
   constant CSR_HPMCOUNTER29H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C9D";
   constant CSR_HPMCOUNTER30H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C9E";
   constant CSR_HPMCOUNTER31H_ADDRESS      : std_logic_vector(N_CSR_ADDRESS_BITS - 1 downto 0) := X"C9F";
   
   
   ---------------------------------------------------------------------------------------------------------
   ----------------------------------- CSR default values --------------------------------------------------
   ---------------------------------------------------------------------------------------------------------
   
   -- counters/timers
   constant CSR_CYCLE_DEFAULT              : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_INSTRET_DEFAULT            : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER3_DEFAULT        : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER4_DEFAULT        : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER5_DEFAULT        : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER6_DEFAULT        : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER7_DEFAULT        : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER8_DEFAULT        : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER9_DEFAULT        : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER10_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER11_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER12_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER13_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER14_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER15_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER16_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER17_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER18_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER19_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER20_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER21_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER22_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER23_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER24_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER25_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER26_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER27_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER28_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER29_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER30_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   constant CSR_HPMCOUNTER31_DEFAULT       : std_logic_vector(COUNTER_SIZE - 1 downto 0) := (others => '0');
   
   -- machine registers
   constant CSR_MVENDORID_DEFAULT          : std_logic_vector(XLEN - 1 downto 0) := (others => '0');  -- not implemented / non-commercial
   constant CSR_MARCHID_DEFAULT            : std_logic_vector(XLEN - 1 downto 0) := (others => '0');  -- not implemented
   constant CSR_MIMPID_DEFAULT             : std_logic_vector(XLEN - 1 downto 0) := (others => '0');  -- not implemented
   constant CSR_MHARTID_DEFAULT            : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   -- TODO: mstatus register default
   --------------------------------------- misa default -----------------------------------------------------
   constant MISA_EXTENSION_A : std_logic_vector(XLEN - 1 downto 0) := X"00000001";
   constant MISA_EXTENSION_B : std_logic_vector(XLEN - 1 downto 0) := X"00000002";
   constant MISA_EXTENSION_C : std_logic_vector(XLEN - 1 downto 0) := X"00000004";
   constant MISA_EXTENSION_D : std_logic_vector(XLEN - 1 downto 0) := X"00000008";
   constant MISA_EXTENSION_E : std_logic_vector(XLEN - 1 downto 0) := X"00000010";
   constant MISA_EXTENSION_F : std_logic_vector(XLEN - 1 downto 0) := X"00000020";
   constant MISA_EXTENSION_G : std_logic_vector(XLEN - 1 downto 0) := X"00000040";
   constant MISA_EXTENSION_H : std_logic_vector(XLEN - 1 downto 0) := X"00000080";
   constant MISA_EXTENSION_I : std_logic_vector(XLEN - 1 downto 0) := X"00000100";
   constant MISA_EXTENSION_J : std_logic_vector(XLEN - 1 downto 0) := X"00000200";
   constant MISA_EXTENSION_K : std_logic_vector(XLEN - 1 downto 0) := X"00000400";
   constant MISA_EXTENSION_L : std_logic_vector(XLEN - 1 downto 0) := X"00000800";
   constant MISA_EXTENSION_M : std_logic_vector(XLEN - 1 downto 0) := X"00001000";
   constant MISA_EXTENSION_N : std_logic_vector(XLEN - 1 downto 0) := X"00002000";
   constant MISA_EXTENSION_O : std_logic_vector(XLEN - 1 downto 0) := X"00004000";
   constant MISA_EXTENSION_P : std_logic_vector(XLEN - 1 downto 0) := X"00008000";
   constant MISA_EXTENSION_Q : std_logic_vector(XLEN - 1 downto 0) := X"00010000";
   constant MISA_EXTENSION_R : std_logic_vector(XLEN - 1 downto 0) := X"00020000";
   constant MISA_EXTENSION_S : std_logic_vector(XLEN - 1 downto 0) := X"00040000";
   constant MISA_EXTENSION_T : std_logic_vector(XLEN - 1 downto 0) := X"00080000";
   constant MISA_EXTENSION_U : std_logic_vector(XLEN - 1 downto 0) := X"00100000";
   constant MISA_EXTENSION_V : std_logic_vector(XLEN - 1 downto 0) := X"00200000";
   constant MISA_EXTENSION_W : std_logic_vector(XLEN - 1 downto 0) := X"00400000";
   constant MISA_EXTENSION_X : std_logic_vector(XLEN - 1 downto 0) := X"00800000";
   constant MISA_EXTENSION_Y : std_logic_vector(XLEN - 1 downto 0) := X"01000000";
   constant MISA_EXTENSION_Z : std_logic_vector(XLEN - 1 downto 0) := X"02000000";
   constant MISA_XLEN_32 : std_logic_vector(XLEN - 1 downto 0) := X"40000000";
   constant CSR_MISA_DEFAULT : std_logic_vector(XLEN - 1 downto 0) := MISA_EXTENSION_I or MISA_EXTENSION_U or MISA_EXTENSION_S or MISA_XLEN_32;
   constant CSR_MEDELEG_DEFAULT     : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_MIDELEG_DEFAULT     : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   -- TODO: mie register default
   constant CSR_MTVEC_DEFAULT       : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_MCOUNTEREN_DEFAULT  : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_MSCRATCH_DEFAULT    : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_MEPC_DEFAULT        : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_MCAUSE_DEFAULT      : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_MTVAL_DEFAULT       : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   -- TODO: mip register default
   
   -- supervisor registers
   -- sstatus shared
   -- no sedeleg (no user mode interrupts)
   -- no sideleg (no user mode interrupts)
   -- sie shared
   constant CSR_STVEC_DEFAULT       : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_SCOUNTEREN_DEFAULT  : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_SSCRATCH_DEFAULT    : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_SEPC_DEFAULT        : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_SCAUSE_DEFAULT      : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   constant CSR_STVAL_DEFAULT       : std_logic_vector(XLEN - 1 downto 0) := (others => '0');
   -- TODO: sip register default
   -- TODO: satp register default
   
   
   
   -----------------------------------------------------------------------------------------------------------
   ---------------------------------------- bit modes --------------------------------------------------------
   -----------------------------------------------------------------------------------------------------------
   
   -- encodes the mode of a bit of a CSR
   type CSR_BIT_MODE is (CSR_RO,    -- read only (illegal instruction exception on write) 
                         CSR_WIRI,  -- writes ignored and reads ignored
                         CSR_WPRI,  -- writes preserve and reads ignored (same effect as CSR_WIRI)
                         CSR_WI,    -- writes ignored and reads allowed
                         CSR_RW);   -- read/write (any reads and writes allowed)
   type CSR_BIT_MODE_ARRAY is array(0 to XLEN - 1) of CSR_BIT_MODE;
   
   -- machine registers
   constant CSR_MVENDORID_BIT_MODES : CSR_BIT_MODE_ARRAY := (others => CSR_WI);
   constant CSR_MARCHID_BIT_MODES   : CSR_BIT_MODE_ARRAY := (others => CSR_WI);
   constant CSR_MIMPID_BIT_MODES    : CSR_BIT_MODE_ARRAY := (others => CSR_WI);
   constant CSR_MHARTID_BIT_MODES   : CSR_BIT_MODE_ARRAY := (others => CSR_WI);
   -- TODO: mstatus register bit mode
   constant CSR_MISA_BIT_MODES      : CSR_BIT_MODE_ARRAY := (XLEN - 1 downto XLEN - 2  => CSR_WI) & (XLEN - 3 downto 26 => CSR_WIRI) & (25 downto 0 => CSR_WI);
   constant CSR_MEDELEG_BIT_MODES   : CSR_BIT_MODE_ARRAY := (XLEN - 1 downto 12 => CSR_RW) & CSR_WI & (10 downto 0 => CSR_RW);
   constant CSR_MIDELEG_BIT_MODES   : CSR_BIT_MODE_ARRAY := (others => CSR_RW);
   -- TODO: mie register bit modes
   constant CSR_MTVEC_BIT_MODES     : CSR_BIT_MODE_ARRAY := (XLEN downto 2 => CSR_RW) & (1 downto 0 => CSR_WI);  -- only mode 0 supported
   constant CSR_MCOUNTEREN          : CSR_BIT_MODE_ARRAY := (XLEN - 1 downto 3 => CSR_WI) & (2 downto 0 => CSR_RW);
   constant CSR_MSCRATCH_BIT_MODES  : CSR_BIT_MODE_ARRAY := (others => CSR_RW);
   constant CSR_MEPC_BIT_MODES      : CSR_BIT_MODE_ARRAY := (XLEN - 1 downto 2 => CSR_RW) & (1 downto 0 => CSR_WI);
   constant CSR_MCAUSE_BIT_MODES    : CSR_BIT_MODE_ARRAY := (others => CSR_RW);  -- allowed to hold even invalid codes
   constant CSR_MTVAL_BIT_MODES     : CSR_BIT_MODE_ARRAY := (others => CSR_RW);
   -- TODO: mip register bit modes
   
   -- supervisor registers
   -- TODO: sstatus bit modes
   -- no sedeleg (no user mode interrupts)
   -- no sideleg (no user mode interrupts)
   -- TODO: sie bit modes
   constant CSR_STVEC_BIT_MODES     : CSR_BIT_MODE_ARRAY := (XLEN downto 2 => CSR_RW) & (1 downto 0 => CSR_WI);  -- only mode 0 supported
   constant CSR_SCOUNTEREN_BIT_MODES   : CSR_BIT_MODE_ARRAY := (XLEN - 1 downto 3 => CSR_WI) & (2 downto 0 => CSR_RW);
   constant CSR_SSCRATCH_BIT_MODES     : CSR_BIT_MODE_ARRAY := (others => CSR_RW);
   constant CSR_SEPC_BIT_MODES         : CSR_BIT_MODE_ARRAY := (XLEN - 1 downto 2 => CSR_RW) & (1 downto 0 => CSR_WI);
   constant CSR_SCAUSE_BIT_MODES       : CSR_BIT_MODE_ARRAY := (others => CSR_RW);
   constant CSR_STVAL_BIT_MODES        : CSR_BIT_MODE_ARRAY := (others => CSR_RW);
   -- TODO: sip register bit modes
   -- TODO: satp register bit modes
   
   
end Common_CSR;


package body Common_CSR is
end Common_CSR;
