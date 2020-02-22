from math import log2
from random import choice

# tlb constants
N_TLB_ENTRIES = 64
N_WAYS = 2
N_TLB_SETS = round(N_TLB_ENTRIES / N_WAYS)
N_INDEX_BITS = round(log2(N_TLB_SETS))
N_VPN_BITS = 20
TAG_LEN = N_VPN_BITS - N_INDEX_BITS
ASID_LEN = 6
PADDR_LEN = 34


class PageTableEntry:
    def __init__(self):
        self.ppn1 = "0" * 12
        self.ppn0 = "0" * 10
        self.rsw = "0" * 2
        self.d = "0"
        self.a = "0"
        self.g = "0"
        self.u = "0"
        self.x = "0"
        self.w = "0"
        self.r = "0"
        self.v = "0"

    def __str__(self):
        return self.ppn1 + self.ppn0 + self.rsw + self.d + self.a + self.g + self.u + self.x + self.w + self.r + self.v

    @staticmethod
    def from_string(pte_string):
        pte = PageTableEntry()
        pte.ppn1 = pte_string[0:12]
        pte.ppn0 = pte_string[12:22]
        pte.rsw = pte_string[22:24]
        pte.d = pte_string[24]
        pte.a = pte_string[25]
        pte.g = pte_string[26]
        pte.u = pte_string[27]
        pte.x = pte_string[28]
        pte.w = pte_string[29]
        pte.r = pte_string[30]
        pte.v = pte_string[31]


class CacheEntry:
    def __init__(self):
        self.valid = "0"
        self.megapage = "0"
        self.asid = "0" * ASID_LEN
        self.tag = "0" * TAG_LEN
        self.pte = PageTableEntry()
        self.paddr = "0" * PADDR_LEN
        self.tag_index = "0" * N_INDEX_BITS


class CacheSet:
    def __init__(self):
        self.lru = 0
        self.entries = [CacheEntry() for _ in range(0, N_WAYS)]


class TranslationLookasideBuffer:
    def __init__(self):
        self.sets = [CacheSet() for _ in range(0, N_TLB_SETS)]
        self.valid_entries = []  # list of all entries with valid = 1 (i_set, i_way)

    def add_entry(self, megapage, asid, vaddr, pte, paddr):
        tag = vaddr[:TAG_LEN]
        tag_index = vaddr[TAG_LEN:N_VPN_BITS]
        i_tag = int(tag_index, 2)
        current_set = self.sets[i_tag]
        lru = current_set.lru
        entry = current_set.entries[lru]

        # fill out entry
        entry.valid = "1"
        entry.megapage = megapage
        entry.asid = asid
        entry.tag = tag
        entry.pte = pte
        entry.paddr = paddr
        current_set.lru = (lru + 1) % 2

        return

    def get_random_valid_entry(self):
        i_set, i_way = choice(self.valid_entries)

        return self.sets[i_set].entries[i_way]
