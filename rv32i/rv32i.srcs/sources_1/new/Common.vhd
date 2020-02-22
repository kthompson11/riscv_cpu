-- Common.vhd --
-- Contains constants/types common to many entities.

library IEEE;
use IEEE.std_logic_1164.all;

package Common is
   constant CLK_FREQUENCY : integer := 100000000;  -- 100 MHz
   

   constant N_REGISTERS : integer := 32;     -- Number of registers in register file.
   constant XLEN : integer := 32;            -- word size
   constant WORD_WIDTH : integer := 32;
   constant HALF_WIDTH : integer := 16;
   constant BYTE_WIDTH : integer := 8;
   constant INSTRUCTION_LENGTH : integer := 32;
   constant COUNTER_SIZE : integer := 64;
  
  
   -- base addresses
   -- TODO: use this or all zeros
   constant MACHINE_INTERRUPT_BASE_ADDRESS : std_logic_vector(XLEN - 1 downto 0) := X"00000000";
   constant MACHINE_INTERRUPT_MODE : std_logic_vector(1 downto 0) := "00";

   type T_MEM_OP is (MEM_LOAD, MEM_STORE);
   type T_MEM_SECTION is (MEM_INSTRUCTION, MEM_DATA);
   
   -- types for mux control signals
   type t_wd_src is (WD_SRC_CSR_RD, WD_SRC_PCPRIME, WD_SRC_MEM_RD, WD_SRC_ALU_OUT);
   type t_op1_mux_src is (OP1_SRC_D1, OP1_SRC_PC);
   type t_op2_mux_src is (OP2_SRC_D2, OP2_SRC_IMM);
   type t_pc_mux_src is (PC_SRC_PCPRIME, PC_SRC_ALU_OUT);

   type t_imm_type is (IMM_TYPE_I, IMM_TYPE_S, IMM_TYPE_B, IMM_TYPE_U, IMM_TYPE_J);
   
   type t_alu_op is (ALU_OP_ADD, ALU_OP_SUB, ALU_OP_SLT, ALU_OP_SLTU, ALU_OP_AND, ALU_OP_OR, ALU_OP_XOR, ALU_OP_SLL, ALU_OP_SRL, ALU_OP_SRA);
   
   type t_cmp_op is (CMP_OP_BEQ, CMP_OP_BNE, CMP_OP_BLT, CMP_OP_BLTU, CMP_OP_BGE, CMP_OP_BGEU, CMP_OP_TRUE, CMP_OP_FALSE);
   constant CMP_FUNCT3_BEQ      : std_logic_vector(2 downto 0) := "000";
   constant CMP_FUNCT3_BNE      : std_logic_vector(2 downto 0) := "001";
   constant CMP_FUNCT3_INVALID1 : std_logic_vector(2 downto 0) := "010";
   constant CMP_FUNCT3_INVALID2 : std_logic_vector(2 downto 0) := "011";
   constant CMP_FUNCT3_BLT      : std_logic_vector(2 downto 0) := "100";
   constant CMP_FUNCT3_BLTU     : std_logic_vector(2 downto 0) := "110";
   constant CMP_FUNCT3_BGE      : std_logic_vector(2 downto 0) := "101";
   constant CMP_FUNCT3_BGEU     : std_logic_vector(2 downto 0) := "111";
   
   -- load funct3
   constant LOAD_FUNCT3_LB  : std_logic_vector(2 downto 0) := "000";
   constant LOAD_FUNCT3_LH  : std_logic_vector(2 downto 0) := "001";
   constant LOAD_FUNCT3_LW  : std_logic_vector(2 downto 0) := "010";
   constant LOAD_FUNCT3_LBU : std_logic_vector(2 downto 0) := "100";
   constant LOAD_FUNCT3_LHU : std_logic_vector(2 downto 0) := "101";
   
   -- store funct3
   constant STORE_FUNCT3_SB : std_logic_vector(2 downto 0) := "000";
   constant STORE_FUNCT3_SH : std_logic_vector(2 downto 0) := "001";
   constant STORE_FUNCT3_SW : std_logic_vector(2 downto 0) := "010";
   
   -- misc_mem_ funct3
   constant MISC_MEM_FUNCT3_FENCE  : std_logic_vector(2 downto 0) := "000";
   constant MISC_MEM_FUNCT3_FENCEI : std_logic_vector(2 downto 0) := "001";
   
   -- constants for registers
   constant REGISTER_0  : std_logic_vector := "00000";
   constant REGISTER_1  : std_logic_vector := "00001";
   constant REGISTER_2  : std_logic_vector := "00010";
   constant REGISTER_3  : std_logic_vector := "00011";
   constant REGISTER_4  : std_logic_vector := "00100";
   constant REGISTER_5  : std_logic_vector := "00101";
   constant REGISTER_6  : std_logic_vector := "00110";
   constant REGISTER_7  : std_logic_vector := "00111";
   constant REGISTER_8  : std_logic_vector := "01000";
   constant REGISTER_9  : std_logic_vector := "01001";
   constant REGISTER_10 : std_logic_vector := "01010";
   constant REGISTER_11 : std_logic_vector := "01011";
   constant REGISTER_12 : std_logic_vector := "01100";
   constant REGISTER_13 : std_logic_vector := "01101";
   constant REGISTER_14 : std_logic_vector := "01110";
   constant REGISTER_15 : std_logic_vector := "01111";
   constant REGISTER_16 : std_logic_vector := "10000";
   constant REGISTER_17 : std_logic_vector := "10001";
   constant REGISTER_18 : std_logic_vector := "10010";
   constant REGISTER_19 : std_logic_vector := "10011";
   constant REGISTER_20 : std_logic_vector := "10100";
   constant REGISTER_21 : std_logic_vector := "10101";
   constant REGISTER_22 : std_logic_vector := "10110";
   constant REGISTER_23 : std_logic_vector := "10111";
   constant REGISTER_24 : std_logic_vector := "11000";
   constant REGISTER_25 : std_logic_vector := "11001";
   constant REGISTER_26 : std_logic_vector := "11010";
   constant REGISTER_27 : std_logic_vector := "11011";
   constant REGISTER_28 : std_logic_vector := "11100";
   constant REGISTER_29 : std_logic_vector := "11101";
   constant REGISTER_30 : std_logic_vector := "11110";
   constant REGISTER_31 : std_logic_vector := "11111";
   
   constant INSTRUCTION_RD_LENGTH     : integer := 5;
   constant INSTRUCTION_RS1_LENGTH    : integer := 5;
   constant INSTRUCTION_RS2_LENGTH    : integer := 5;
   constant INSTRUCTION_FUNCT7_LENGTH : integer := 7;
   constant INSTRUCTION_FUNCT3_LENGTH : integer := 3;
   constant INSTRUCTION_OPCODE_LENGTH : integer := 7;
   
--   -- opcodes
--   constant OPCODE_LOAD       : std_logic_vector := "0000011";
--   constant OPCODE_LOAD_FP    : std_logic_vector := "0000111";
--   constant OPCODE_CUSTOM_0   : std_logic_vector := "0001011";
--   constant OPCODE_MISC_MEM   : std_logic_vector := "0001111";
--   constant OPCODE_OP_IMM     : std_logic_vector := "0010011";
--   constant OPCODE_AUIPC      : std_logic_vector := "0010111";
--   constant OPCODE_OP_IMM_32  : std_logic_vector := "0011011";
--   constant OPCODE_48B0       : std_logic_vector := "0011111";
--   constant OPCODE_STORE      : std_logic_vector := "0100011";
--   constant OPCODE_STORE_FP   : std_logic_vector := "0100111";
--   constant OPCODE_CUSTOM_1   : std_logic_vector := "0101011";
--   constant OPCODE_AMO        : std_logic_vector := "0101111";
--   constant OPCODE_OP         : std_logic_vector := "0110011";
--   constant OPCODE_LUI        : std_logic_vector := "0110111";
--   constant OPCODE_OP_32      : std_logic_vector := "0111011";
--   constant OPCODE_64B        : std_logic_vector := "0111111";
--   constant OPCODE_MADD       : std_logic_vector := "1000011";
--   constant OPCODE_MSUB       : std_logic_vector := "1000111";
--   constant OPCODE_NMSUB      : std_logic_vector := "1001011";
--   constant OPCODE_NMADD      : std_logic_vector := "1001111";
--   constant OPCODE_OP_FP      : std_logic_vector := "1010011";
--   constant OPCODE_RESERVED1  : std_logic_vector := "1010111";
--   constant OPCODE_CUSTOM_2   : std_logic_vector := "1011011";
--   constant OPCODE_48B1       : std_logic_vector := "1011111";
--   constant OPCODE_BRANCH     : std_logic_vector := "1100011";
--   constant OPCODE_JALR       : std_logic_vector := "1100111";
--   constant OPCODE_RESERVED2  : std_logic_vector := "1101011";
--   constant OPCODE_JAL        : std_logic_vector := "1101111";
--   constant OPCODE_SYSTEM     : std_logic_vector := "1110011";
--   constant OPCODE_RESERVED3  : std_logic_vector := "1110111";
--   constant OPCODE_CUSTOM_3   : std_logic_vector := "1111011";
--   constant OPCODE_GT_80B     : std_logic_vector := "1111111";

   -- SYSTEM FUNCT3 operations
   constant SYSTEM_FUNCT3_PRIV     : std_logic_vector(2 downto 0) := "000";
   constant SYSTEM_FUNCT3_CSRRW    : std_logic_vector(2 downto 0) := "001";
   constant SYSTEM_FUNCT3_CSRRS    : std_logic_vector(2 downto 0) := "010";
   constant SYSTEM_FUNCT3_CSRRC    : std_logic_vector(2 downto 0) := "011";
   constant SYSTEM_FUNCT3_INVALID  : std_logic_vector(2 downto 0) := "100";
   constant SYSTEM_FUNCT3_CSRRWI   : std_logic_vector(2 downto 0) := "101";
   constant SYSTEM_FUNCT3_CSRRSI   : std_logic_vector(2 downto 0) := "110";
   constant SYSTEM_FUNCT3_CSRRCI   : std_logic_vector(2 downto 0) := "111";
   
   constant SYSTEM_PRIV_ECALL     : std_logic_vector(11 downto 0) := "000000000000";
   constant SYSTEM_PRIV_EBREAK    : std_logic_vector(11 downto 0) := "000000000001";
   constant SYSTEM_PRIV_URET      : std_logic_vector(11 downto 0) := "000000000010";  -- not supported
   constant SYSTEM_PRIV_SRET      : std_logic_vector(11 downto 0) := "000100000010";
   constant SYSTEM_PRIV_MRET      : std_logic_vector(11 downto 0) := "001100000010";
   constant SYSTEM_PRIV_WFI       : std_logic_vector(11 downto 0) := "000100000101";
   constant SYSTEM_PRIV_SFENCEVMA : std_logic_vector(6 downto 0) := "0001001";  -- TODO: rework instruction decoder to use commented out form below without using "case?"
   --constant SYSTEM_PRIV_SFENCEVMA : std_logic_vector(11 downto 0) := "0001001-----";

   
   -- general operand indices
   constant INSTRUCTION_RD_HIGH     : integer := 11;
   constant INSTRUCTION_RD_LOW      : integer := 7;
   constant INSTRUCTION_RS1_HIGH    : integer := 19;
   constant INSTRUCTION_RS1_LOW     : integer := 15;
   constant INSTRUCTION_RS2_HIGH    : integer := 24;
   constant INSTRUCTION_RS2_LOW     : integer := 20;
   constant INSTRUCTION_FUNCT7_HIGH : integer := 31;
   constant INSTRUCTION_FUNCT7_LOW  : integer := 25;
   constant INSTRUCTION_FUNCT3_HIGH : integer := 14;
   constant INSTRUCTION_FUNCT3_LOW  : integer := 12;
   constant INSTRUCTION_OPCODE_HIGH : integer := 6;
   constant INSTRUCTION_OPCODE_LOW  : integer := 0;
   
   -- privilege modes
   subtype t_hart_priv is std_logic_vector(1 downto 0);
   constant PRIVILEGE_USER       : std_logic_vector(1 downto 0) := "00";
   constant PRIVILEGE_SUPERVISOR : std_logic_vector(1 downto 0) := "01";
   constant PRIVILEGE_RESERVED   : std_logic_vector(1 downto 0) := "10";
   constant PRIVILEGE_MACHINE    : std_logic_vector(1 downto 0) := "11";
   
   -- csr addresses
end Common;


package body Common is

end Common;