
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Common.all;

entity instruction_decoder is
   port (
      instruction    : in     std_logic_vector(INSTRUCTION_LENGTH - 1 downto 0);
      priv_mode      : in     std_logic_vector(1 downto 0);
      
      -- instruction fields
      RS1            : out    std_logic_vector(INSTRUCTION_RS1_LENGTH - 1 downto 0);
      RS2            : out    std_logic_vector(INSTRUCTION_RS2_LENGTH - 1 downto 0);
      RD             : out    std_logic_vector(INSTRUCTION_RD_LENGTH - 1 downto 0);
      
      csr_enable     : out    std_logic;
      
      -- alu control signals
      alu_op         : out    t_alu_op;
      cmp_op         : out    t_cmp_op;
      
      -- write enables
      regfile_we     : out    std_logic;  -- register file write enable
      
      
      -- memory signals
      mem_we         : out    std_logic;
      mem_enable     : out    std_logic;
      iflush         : out    std_logic;
      dflush         : out    std_logic;
      tlbflush       : out    std_logic;
      
      wd_src         : out    t_wd_src;
      op1_src        : out    t_op1_mux_src;
      op2_src        : out    t_op2_mux_src;
      imm_type       : out    t_imm_type;
      
      sret           : out    std_logic;
      mret           : out    std_logic;
      
      except_ecall_from_u  : out    std_logic;
      except_ecall_from_s  : out    std_logic;
      except_ecall_from_m  : out    std_logic;
      except_illegal_instr : out    std_logic;
      except_breakpoint    : out    std_logic
   );
end instruction_decoder;

architecture Behavioral of instruction_decoder is
   signal opcode : std_logic_vector(INSTRUCTION_OPCODE_LENGTH - 1 downto 0);
   signal funct3 : std_logic_vector(INSTRUCTION_FUNCT3_LENGTH - 1 downto 0);
   signal funct12 : std_logic_vector(11 downto 0);  -- TODO: constant
   signal toggle_subsra : std_logic;
   
   -- opcodes
   constant OPCODE_LOAD       : std_logic_vector(6 downto 0) := "0000011";
   constant OPCODE_LOAD_FP    : std_logic_vector(6 downto 0) := "0000111";
   constant OPCODE_CUSTOM_0   : std_logic_vector(6 downto 0) := "0001011";
   constant OPCODE_MISC_MEM   : std_logic_vector(6 downto 0) := "0001111";
   constant OPCODE_OP_IMM     : std_logic_vector(6 downto 0) := "0010011";
   constant OPCODE_AUIPC      : std_logic_vector(6 downto 0) := "0010111";
   constant OPCODE_OP_IMM_32  : std_logic_vector(6 downto 0) := "0011011";
   constant OPCODE_48B0       : std_logic_vector(6 downto 0) := "0011111";
   constant OPCODE_STORE      : std_logic_vector(6 downto 0) := "0100011";
   constant OPCODE_STORE_FP   : std_logic_vector(6 downto 0) := "0100111";
   constant OPCODE_CUSTOM_1   : std_logic_vector(6 downto 0) := "0101011";
   constant OPCODE_AMO        : std_logic_vector(6 downto 0) := "0101111";
   constant OPCODE_OP         : std_logic_vector(6 downto 0) := "0110011";
   constant OPCODE_LUI        : std_logic_vector(6 downto 0) := "0110111";
   constant OPCODE_OP_32      : std_logic_vector(6 downto 0) := "0111011";
   constant OPCODE_64B        : std_logic_vector(6 downto 0) := "0111111";
   constant OPCODE_MADD       : std_logic_vector(6 downto 0) := "1000011";
   constant OPCODE_MSUB       : std_logic_vector(6 downto 0) := "1000111";
   constant OPCODE_NMSUB      : std_logic_vector(6 downto 0) := "1001011";
   constant OPCODE_NMADD      : std_logic_vector(6 downto 0) := "1001111";
   constant OPCODE_OP_FP      : std_logic_vector(6 downto 0) := "1010011";
   constant OPCODE_RESERVED1  : std_logic_vector(6 downto 0) := "1010111";
   constant OPCODE_CUSTOM_2   : std_logic_vector(6 downto 0) := "1011011";
   constant OPCODE_48B1       : std_logic_vector(6 downto 0) := "1011111";
   constant OPCODE_BRANCH     : std_logic_vector(6 downto 0) := "1100011";
   constant OPCODE_JALR       : std_logic_vector(6 downto 0) := "1100111";
   constant OPCODE_RESERVED2  : std_logic_vector(6 downto 0) := "1101011";
   constant OPCODE_JAL        : std_logic_vector(6 downto 0) := "1101111";
   constant OPCODE_SYSTEM     : std_logic_vector(6 downto 0) := "1110011";
   constant OPCODE_RESERVED3  : std_logic_vector(6 downto 0) := "1110111";
   constant OPCODE_CUSTOM_3   : std_logic_vector(6 downto 0) := "1111011";
   constant OPCODE_GT_80B     : std_logic_vector(6 downto 0) := "1111111";
   
   -- alu operation decode constants
   constant ALU_FUNCT3_ADDSUB : std_logic_vector(2 downto 0) := "000";
   constant ALU_FUNCT3_SLT    : std_logic_vector(2 downto 0) := "010";
   constant ALU_FUNCT3_SLTU   : std_logic_vector(2 downto 0) := "011";
   constant ALU_FUNCT3_AND    : std_logic_vector(2 downto 0) := "111";
   constant ALU_FUNCT3_OR     : std_logic_vector(2 downto 0) := "110";
   constant ALU_FUNCT3_XOR    : std_logic_vector(2 downto 0) := "100";
   constant ALU_FUNCT3_SLL    : std_logic_vector(2 downto 0) := "001";
   constant ALU_FUNCT3_SRLSRA : std_logic_vector(2 downto 0) := "101";
begin
   opcode <= instruction(INSTRUCTION_OPCODE_HIGH downto INSTRUCTION_OPCODE_LOW);
   funct3 <= instruction(INSTRUCTION_FUNCT3_HIGH downto INSTRUCTION_FUNCT3_LOW);
   funct12 <= instruction(31 downto 20);
   
   decode : process (all)
   begin
      -- set all outputs to default values to prevent latches
      except_illegal_instr <= '0';
      except_ecall_from_u <= '0';
      except_ecall_from_s <= '0';
      except_ecall_from_m <= '0';
      except_breakpoint <= '0';
      
      sret <= '0';
      mret <= '0';
   
      RS1 <= instruction(INSTRUCTION_RS1_HIGH downto INSTRUCTION_RS1_LOW);
      RS2 <= instruction(INSTRUCTION_RS2_HIGH downto INSTRUCTION_RS2_LOW);
      RD <= instruction(INSTRUCTION_RD_HIGH downto INSTRUCTION_RD_LOW);
      
      -- assign default alu operation
      toggle_subsra <= instruction(30);
      if (funct3 = ALU_FUNCT3_ADDSUB) and (toggle_subsra = '0') then
         alu_op <= ALU_OP_ADD;
      elsif (funct3 = ALU_FUNCT3_ADDSUB) and (toggle_subsra = '1') then
         alu_op <= ALU_OP_SUB;
      elsif (funct3 = ALU_FUNCT3_SLT) then
         alu_op <= ALU_OP_SLT;
      elsif (funct3 = ALU_FUNCT3_SLTU) then
         alu_op <= ALU_OP_SLTU;
      elsif (funct3 = ALU_FUNCT3_AND) then
         alu_op <= ALU_OP_AND;
      elsif (funct3 = ALU_FUNCT3_OR) then
         alu_op <= ALU_OP_OR;
      elsif (funct3 = ALU_FUNCT3_XOR) then
         alu_op <= ALU_OP_XOR;
      elsif (funct3 = ALU_FUNCT3_SLL) then
         alu_op <= ALU_OP_SLL;
      elsif (funct3 = ALU_FUNCT3_SRLSRA) and (toggle_subsra = '0') then
         alu_op <= ALU_OP_SRL;
      elsif (funct3 = ALU_FUNCT3_SRLSRA) and (toggle_subsra = '1') then
         alu_op <= ALU_OP_SRA;
      else
         alu_op <= ALU_OP_ADD;
      end if;
      cmp_op <= CMP_OP_FALSE;  -- do not take branch
                        
      wd_src <= WD_SRC_ALU_OUT;
      op1_src <= OP1_SRC_D1;
      op2_src <= OP2_SRC_D2;
      imm_type <= IMM_TYPE_I;
      mem_enable <= '0';
      csr_enable <= '0';
      regfile_we <= '0';
      mem_we <= '0';
      regfile_we <= '0';
      iflush <= '0';
      dflush <= '0';
      tlbflush <= '0';
      
      -- enable specific outputs here
      case opcode is
         when OPCODE_LUI =>
            -- add zero to U-type immediate and store in register file
            alu_op <= ALU_OP_ADD;
            RS1 <= REGISTER_0;
            imm_type <= IMM_TYPE_U;
            wd_src <= WD_SRC_ALU_OUT;
            op1_src <= OP1_SRC_D1;
            op2_src <= OP2_SRC_IMM;
            regfile_we <= '1';
         when OPCODE_AUIPC =>
            -- add pc to U-type immediate and store in register file
            alu_op <= ALU_OP_ADD;
            imm_type <= IMM_TYPE_U;
            wd_src <= WD_SRC_ALU_OUT;
            op1_src <= OP1_SRC_PC;
            op2_src <= OP2_SRC_IMM;
            regfile_we <= '1';
         when OPCODE_JAL =>
            -- add pc to J-type immediate and store in pc
            alu_op <= ALU_OP_ADD;
            imm_type <= IMM_TYPE_J;
            op1_src <= OP1_SRC_PC;
            op2_src <= OP2_SRC_IMM;
            cmp_op <= CMP_OP_TRUE;
            -- additionally, store the next pc into the register file
            wd_src <= WD_SRC_PCPRIME;
            regfile_we <= '1';
         when OPCODE_JALR =>
            if funct3 = "000" then  -- illegal instruction checks
               except_illegal_instr <= '1';
            else
               -- add RS1 to I-type immediate and store in pc
               alu_op <= ALU_OP_ADD;
               imm_type <= IMM_TYPE_I;
               op1_src <= OP1_SRC_D1;
               op2_src <= OP2_SRC_IMM;
               cmp_op <= CMP_OP_TRUE;
               -- additionally, store the next pc into the register file
               wd_src <= WD_SRC_PCPRIME;
               regfile_we <= '1';
            end if;
         when OPCODE_BRANCH =>
            if (funct3 = CMP_FUNCT3_INVALID1) or (funct3 = CMP_FUNCT3_INVALID2) then  -- illegal instruction checks
               except_illegal_instr <= '1';
            else
               -- add pc to B-type immediate and store in pc if cmp_out = '1'
               alu_op <= ALU_OP_ADD;
               op1_src <= OP1_SRC_PC;
               op2_src <= OP2_SRC_IMM;
               imm_type <= IMM_TYPE_B;
               case funct3 is
                  when CMP_FUNCT3_BEQ => cmp_op <= CMP_OP_BEQ;
                  when CMP_FUNCT3_BNE => cmp_op <= CMP_OP_BNE;
                  when CMP_FUNCT3_BLT => cmp_op <= CMP_OP_BLT;
                  when CMP_FUNCT3_BLTU => cmp_op <= CMP_OP_BLTU;
                  when CMP_FUNCT3_BGE => cmp_op <= CMP_OP_BGE;
                  when CMP_FUNCT3_BGEU => cmp_op <= CMP_OP_BGEU;
                  when others => null;  -- this should never be reached
               end case;
            end if;
         when OPCODE_LOAD =>
            case funct3 is
               when LOAD_FUNCT3_LB | LOAD_FUNCT3_LH | LOAD_FUNCT3_LW | LOAD_FUNCT3_LBU | LOAD_FUNCT3_LHU =>  -- illegal instruction check
                  -- add D1 to I-type immediate and use as address in load
                  alu_op <= ALU_OP_ADD;
                  op1_src <= OP1_SRC_D1;
                  op2_src <= OP2_SRC_IMM;
                  imm_type <= IMM_TYPE_I;
                  mem_enable <= '1';
                  -- store result of load into register file
                  wd_src <= WD_SRC_MEM_RD;
                  regfile_we <= '1';
               when others =>
                  except_illegal_instr <= '1';
            end case;
         when OPCODE_STORE =>
            case funct3 is
               when STORE_FUNCT3_SB | STORE_FUNCT3_SH | STORE_FUNCT3_SW =>  -- illegal instruction check
                  -- add D1 to S-type immediate and use as address in store
                  alu_op <= ALU_OP_ADD;
                  op1_src <= OP1_SRC_D1;
                  op2_src <= OP2_SRC_IMM;
                  imm_type <= IMM_TYPE_S;
                  mem_enable <= '1';
                  mem_we <= '1';
               when others => 
                  except_illegal_instr <= '1';
            end case;
         when OPCODE_OP_IMM =>
            -- perform requested alu operation on D1 and an I-type immediate
            imm_type <= IMM_TYPE_I;
            op1_src <= OP1_SRC_D1;
            op2_src <= OP2_SRC_IMM;
            case funct3 is
               when ALU_FUNCT3_ADDSUB =>
                  alu_op <= ALU_OP_ADD;
               when ALU_FUNCT3_SLT =>
                  alu_op <= ALU_OP_SLT;
               when ALU_FUNCT3_SLTU =>
                  alu_op <= ALU_OP_SLTU;
               when ALU_FUNCT3_XOR =>
                  alu_op <= ALU_OP_XOR;
               when ALU_FUNCT3_OR =>
                  alu_op <= ALU_OP_OR;
               when ALU_FUNCT3_AND =>
                  alu_op <= ALU_OP_AND;
               when ALU_FUNCT3_SLL =>
                  alu_op <= ALU_OP_SLL;
               when ALU_FUNCT3_SRLSRA =>
                  if toggle_subsra = '0' then
                     alu_op <= ALU_OP_SRL;
                  else
                     alu_op <= ALU_OP_SRA;
                  end if;
               when others =>
                  alu_op <= ALU_OP_ADD;  -- never reached
                  report "Error - This case should never be taken." severity error;
            end case;
            -- store result in the register file
            regfile_we <= '1';
            wd_src <= WD_SRC_ALU_OUT;
         when OPCODE_OP =>
            -- perform requested alu operation on D1 and D2
            op1_src <= OP1_SRC_D1;
            op2_src <= OP2_SRC_D2;
            case funct3 is
               when ALU_FUNCT3_ADDSUB =>
                  if toggle_subsra = '0' then
                     alu_op <= ALU_OP_ADD;
                  else
                     alu_op <= ALU_OP_SUB;
                  end if;
               when ALU_FUNCT3_SLT =>
                  alu_op <= ALU_OP_SLT;
               when ALU_FUNCT3_SLTU =>
                  alu_op <= ALU_OP_SLTU;
               when ALU_FUNCT3_XOR =>
                  alu_op <= ALU_OP_XOR;
               when ALU_FUNCT3_OR =>
                  alu_op <= ALU_OP_OR;
               when ALU_FUNCT3_AND =>
                  alu_op <= ALU_OP_AND;
               when ALU_FUNCT3_SLL =>
                  alu_op <= ALU_OP_SLL;
               when ALU_FUNCT3_SRLSRA =>
                  if toggle_subsra = '0' then
                     alu_op <= ALU_OP_SRL;
                  else
                     alu_op <= ALU_OP_SRA;
                  end if;
               when others =>
                  alu_op <= ALU_OP_ADD;  -- never reached
                  report "Error - This case should never be taken." severity error;
            end case;
            -- store result in the register file
            regfile_we <= '1';
            wd_src <= WD_SRC_ALU_OUT;
         when OPCODE_MISC_MEM =>
            case funct3 is
               when MISC_MEM_FUNCT3_FENCE =>
                  -- physically tagged cache, single core; no fence needed?
                  -- NOP
                  null;
               when MISC_MEM_FUNCT3_FENCEI =>
                  -- as a simple but slow implementation, just flush both caches
                  iflush <= '1';
                  dflush <= '1';
               when others =>
                  except_illegal_instr <= '1';
            end case;
         when OPCODE_SYSTEM =>
            case funct3 is
               when SYSTEM_FUNCT3_PRIV =>
                  -- find out which privileged operation
                  case funct12 is 
                     when SYSTEM_PRIV_ECALL =>
                        if priv_mode = PRIVILEGE_USER then
                           except_ecall_from_u <= '1';
                        elsif priv_mode = PRIVILEGE_SUPERVISOR then
                           except_ecall_from_s <= '1';
                        elsif priv_mode = PRIVILEGE_MACHINE then
                           except_ecall_from_m <= '1';
                        end if;
                     when SYSTEM_PRIV_EBREAK =>
                        except_breakpoint <= '1';
                     when SYSTEM_PRIV_SRET =>
                        if unsigned(priv_mode) >= unsigned(PRIVILEGE_SUPERVISOR) then
                           sret <= '1';
                        else
                           except_illegal_instr <= '1';  -- TODO: determine if this is the correct exception
                        end if;
                     when SYSTEM_PRIV_MRET =>
                        if priv_mode = PRIVILEGE_MACHINE then
                           mret <= '1';
                        else
                           except_illegal_instr <= '1';  -- TODO: dtermine if this is the correct exception
                        end if;
                     when SYSTEM_PRIV_WFI =>
                        null;  -- NOP
--                     when SYSTEM_PRIV_SFENCEVMA =>
--                        tlbflush <= '1';
                     when others =>
                        if funct12(11 downto 6) = SYSTEM_PRIV_SFENCEVMA then
                           tlbflush <= '1';
                        else
                           except_illegal_instr <= '1';
                        end if;
                  end case;
               when SYSTEM_FUNCT3_INVALID =>
                  except_illegal_instr <= '1';
               when others =>  -- csr operation
                  csr_enable <= '1';
            end case;
         when others =>
            except_illegal_instr <= '1';  -- unsupported opcode
      end case;
   end process decode;


end Behavioral;
