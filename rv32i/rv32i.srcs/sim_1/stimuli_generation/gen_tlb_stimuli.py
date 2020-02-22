#!/usr/bin/python3

from random import randint, seed
from tlb_classes import *

# stimuli generation constants
N_STIMULI = 1000

MEMORY_SIZE = 2**20  # 1 MB
PAGE_SIZE = 2**12
MEGAPAGE_SIZE = 2**22
N_PAGES = MEMORY_SIZE // PAGE_SIZE
PTE_SIZE = 4
PTE_PER_PAGE = PAGE_SIZE // PTE_SIZE
MEMORY_ADDR_START = 0x010000000
PT1_PAGE_BASE = 0x010000  # physical page where the first level page table is
PT0_PAGE_BASE = 0x010001  # physical page where second level page tables start
N_PT0 = 15  # number of second level page tables

init_filename = "mem_init"
stim_filename = "tlb_stimuli"
init_file = open(init_filename, 'w')
stim_file = open(stim_filename, 'w')

avail_pte1 = set(range(0, PTE_PER_PAGE))
avail_pte0 = [set(range(0, PTE_PER_PAGE)) for _ in range(0, N_PT0)]


if __name__ == "__main__":

    #seed(123)
    cache = TranslationLookasideBuffer()

    for _ in range(0, N_STIMULI):
        n_levels = randint(1, 2)
        megapage = choice(['1', '0'])
        pt1_offset = choice(tuple(avail_pte1))
        next_pt0 = randint(0, N_PT0 - 1)
        pt0_offset = choice(tuple(avail_pte0[next_pt0]))
        offset = format(randint(0, PAGE_SIZE - 1), '0>12b')
        asid = format(randint(1, 2), '0>6b')
        priv = choice(["USER", "SUPERVISOR", "MACHINE"])

        d_bit = '0'
        a_bit = '0'
        g_bit = choice(['0', '1'])
        u_bit = choice(['0', '1', '1'])
        xwr_bits = choice(['001', '011', '100', '101', '111'])
        v_bit = '1'

        # get a random valid operation
        ops = []
        if (xwr_bits[2] == '1') or (xwr_bits[0] == '1'):
            ops.append("LOAD")
        if xwr_bits[0] == '1':
            ops.append("IFETCH")
        if xwr_bits[1] == '1':
            ops.append("STORE")
        #if len(ops) == 0:
        #    ops.append("LOAD")
        op = choice(ops)

        # get a random valid privilege
        privs = []
        if u_bit == '1':
            privs.append("USER")
        if (u_bit != '1') or (xwr_bits[0] != '1'):
            privs.append("SUPERVISOR")
        privs.append("MACHINE")
        priv = choice(privs)

        # decide whether to use an entry in the cache or create a new entry
        use_cache_entry = choice([True, False])
        if len(cache.valid_entries) == 0:
            use_cache_entry = False

        if use_cache_entry:
            entry = cache.get_random_valid_entry()
            if g_bit == '0':
                asid = entry.asid
            pte = entry.pte

            # get a random valid operation
            ops = []
            if (pte.r == '1') or (pte.x == '1'):
                ops.append("LOAD")
            if pte.x == '1':
                ops.append("IFETCH")
            if pte.w == '1':
                ops.append("STORE")
            op = choice(ops)

            # get a random valid privilege
            privs = []
            if pte.u == '1':
                privs.append("USER")
            if (pte.u != '1') or (pte.x != '1'):
                privs.append("SUPERVISOR")
            privs.append("MACHINE")
            priv = choice(privs)

            vaddr = entry.tag + entry.tag_index + offset
            paddr = pte.ppn1 + pte.ppn0 + offset
        else:
            vaddr = format(pt1_offset, '0>10b') + format(pt0_offset, '0>10b') + offset
            megaoffset = int(vaddr[10:32], 2)

            pte1_paddr = format(PT1_PAGE_BASE * PAGE_SIZE + pt1_offset * PTE_SIZE, '0>34b')

            if megapage == '0':
                pte1_ppn = PT0_PAGE_BASE + next_pt0
                pte1 = format(pte1_ppn, '0>22b') + "0000000001"
                pte0_paddr = format(pte1_ppn * PAGE_SIZE + pt0_offset * PTE_SIZE, '0>34b')
                pte0_ppn = (PT0_PAGE_BASE + N_PT0 + randint(0, N_PAGES - N_PT0 - 1))
                pte0 = format(pte0_ppn, '0>22b') + "00" + str(d_bit) + str(a_bit) + str(g_bit)
                pte0 = pte0 + str(u_bit) + xwr_bits + str(v_bit)
                paddr = format(pte0_ppn * PAGE_SIZE + int(offset, 2), '0>34b')
            else:
                pte1_ppn = MEMORY_ADDR_START + randint(0, 2**6 - 1) * MEGAPAGE_SIZE
                pte1_ppn = pte1_ppn // 2**12
                pte1 = format(pte1_ppn, '0>22b') + "00" + str(d_bit) + str(a_bit) + str(g_bit) + str(u_bit) + xwr_bits + str(v_bit)
                paddr = format(pte1_ppn * PAGE_SIZE + megaoffset, '0>34b')

            # remove used PTE
            avail_pte1.remove(pt1_offset)
            if megapage == '0':
                avail_pte0[next_pt0].remove(pt0_offset)

            if megapage == '0':
                cache.add_entry(megapage, asid, vaddr, PageTableEntry.from_string(pte0), pte0_paddr)
            else:
                cache.add_entry(megapage, asid, vaddr, PageTableEntry.from_string(pte1), pte1_paddr)

            init_file.write(pte1_paddr + " " + pte1 + "\n")
            if megapage == '0':
                init_file.write(pte0_paddr + " " + pte0 + "\n")

        stim_file.write(format(op, ' <7') + " " + format(priv, ' <10') + " " + asid + " " + vaddr + " " + paddr + "\n")
