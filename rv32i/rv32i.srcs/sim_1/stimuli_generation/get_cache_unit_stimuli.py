
from random import *

# choose what stimuli to generate here
GENERATE_FENCE = True
GENERATE_IFETCH = True
GENERATE_LOAD = True
GENERATE_STORE = True

# choose number of stimuli
N_OPERATIONS = 10000

STIMULI_FILENAME = "cache_unit_stimuli"
MEM_INIT_FILENAME = "mem_init"
MEM_CHECK_FILENAME = "mem_check"

PAGE_SIZE = 2**12
PT1_BASE_ADDR = 0x010000000
PT0_BASE_ADDR = 0x010001000
DATA_PAGE_ADDR = 0x010002000
MEMORY_SIZE = 3 * PAGE_SIZE
PT1_PTE = "0000010000000000000001" + "00" + "00000001"
PT0_PTE = "0000010000000000000010" + "00" + "11011111"

# add desired opcodes to possible stimuli opcodes
OPCODE_FENCE = "00"
OPCODE_IFETCH = "01"
OPCODE_LOAD = "10"
OPCODE_STORE = "11"
opcodes = []
opcode_weights = []
if GENERATE_FENCE:
    opcodes.append(OPCODE_FENCE)
    opcode_weights.append(1)
if GENERATE_IFETCH:
    opcodes.append(OPCODE_IFETCH)
    opcode_weights.append(50)
if GENERATE_LOAD:
    opcodes.append(OPCODE_LOAD)
    opcode_weights.append(50)
if GENERATE_STORE:
    opcodes.append(OPCODE_STORE)
    opcode_weights.append(100)

FUNCT3_LB = "000"
FUNCT3_LH = "001"
FUNCT3_LW = "010"
FUNCT3_LBU = "100"
FUNCT3_LHU = "101"
FUNCT3_SB = "000"
FUNCT3_SH = "001"
FUNCT3_SW = "010"

class CacheUnitMemory:

    def __init__(self):
        self.memory = ["0" * 8 for _ in range(MEMORY_SIZE)]

    def write(self, paddr, width, data):
        write_bytes = [data[i * 8: (i + 1) * 8] for i in reversed(range(4))]
        mem_offset = paddr - PT1_BASE_ADDR
        for i in range(width):
            self.memory[mem_offset + i] = write_bytes[i]

    def read(self, paddr, width, is_unsigned=True):
        result = []
        mem_offset = paddr - PT1_BASE_ADDR
        for i in range(width):
            result.append(self.memory[mem_offset + i])
        if width != 4:
            if is_unsigned:
                ext_bit = "0"
            else:
                ext_bit = result[width - 1][0]
            # fill result with ext_bit
            for i in range(width, 4):
                result.append(ext_bit * 8)
        return "".join(reversed(result))

    def get_memory_state(self):
        res = []
        for byte in self.memory:
            res.append(byte)
            res.append("\n")
        return "".join(res[0:-1])


mem = CacheUnitMemory()

# set both levels of the page table and initialize the data page with random data
mem.write(PT1_BASE_ADDR, 4, PT1_PTE)
mem.write(PT0_BASE_ADDR, 4, PT0_PTE)
for ibyte in range(PAGE_SIZE):
    byte = format(randrange(0, 2**8 - 1), '0>8b')
    mem.write(DATA_PAGE_ADDR + ibyte, 1, "0" * 24 + byte)
init_file = open(MEM_INIT_FILENAME, 'w')
init_file.write(mem.get_memory_state())
init_file.close()

# create stimuli and modify the memory
stim_file = open(STIMULI_FILENAME, 'w')
for _ in range(N_OPERATIONS):
    stimulus = ""
    opcode = choices(opcodes, opcode_weights)[0]
    vaddr = randrange(0x00000000, 0x00000FFC)
    paddr = DATA_PAGE_ADDR + vaddr  # NOTE: this translation is not correct in general
    width = choice([1, 2, 4])
    unsigned_load = choice(['0', '1'])
    if opcode == OPCODE_FENCE:
        sfence_vma = choice(['0', '1'])
        stimulus = opcode + " " + sfence_vma
    elif opcode == OPCODE_IFETCH:
        stimulus = opcode + " " + format(vaddr, '0>8x') + " " + format(int(mem.read(paddr, 4, True), 2), '0>8x')
    elif opcode == OPCODE_LOAD:
        funct3 = ""
        if width == 4:
            funct3 = FUNCT3_LW
        elif width == 2:
            if unsigned_load == '1':
                funct3 = FUNCT3_LHU
            else:
                funct3 = FUNCT3_LH
        else:
            if unsigned_load == '1':
                funct3 = FUNCT3_LBU
            else:
                funct3 = FUNCT3_LB
        if unsigned_load == '1':
            lu = True
        else:
            lu = False
        stimulus = opcode + " " + format(vaddr, '0>8x') + " " + funct3 + " " + format(int(mem.read(paddr, width, lu), 2), '0>8x')
    elif opcode == OPCODE_STORE:
        write_data = format(randrange(0, 2**32 - 1), '0>32b')
        if width == 4:
            funct3 = FUNCT3_SW
        elif width == 2:
            funct3 = FUNCT3_SH
        else:
            funct3 = FUNCT3_SB
        stimulus = opcode + " " + format(vaddr, '0>8x') + " " + funct3 + " " + format(int(write_data, 2), '0>8x')
        mem.write(paddr, width, write_data)
        vaddr_lower = vaddr - vaddr % 4
        paddr_lower = DATA_PAGE_ADDR + vaddr_lower
        check_lower = format(int(mem.read(paddr_lower, 4), 2), '0>8x')
        vaddr_upper = vaddr_lower + 4
        paddr_upper = DATA_PAGE_ADDR + vaddr_upper
        check_upper = format(int(mem.read(paddr_upper, 4), 2), '0>8x')
        stimulus += " " + format(vaddr_lower, '0>8x') + " " + check_lower + " " + format(vaddr_upper, '0>8x') + " " + check_upper

    stim_file.write(stimulus + "\n")
stim_file.close()

# write out final memory state
check_file = open(MEM_CHECK_FILENAME, 'w')
check_file.write(mem.get_memory_state())
check_file.close()
