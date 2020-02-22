
from vunit import VUnit
from os.path import dirname
import os
from glob import glob

home = os.environ["HOME"]
lib_unisim_path = home + "/bin/ghdl-0.36/lib/ghdl/vendors/xilinx-vivado"
ghdl_path = os.environ["HOME"] + "/bin/ghdl-0.36/bin"
os.environ["VUNIT_GHDL_PATH"] = ghdl_path

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
# add vunit testbenches
tb_files = glob("../sources_1/**/test/vunit/*.vhd", recursive=True)
for path in tb_files:
    lib.add_source_file(path)
# add other source files
src_files = glob("../sources_1/**/*.vhd", recursive=True)
src_files = [x for x in src_files if "/test/" not in x]
src_files = [x for x in src_files if "/tb_" not in x]
src_files = [x for x in src_files if "/dont_compile" not in x]
src_files = [x for x in src_files if "/hardware_tests/" not in x]
src_files = [x for x in src_files if "/ip/" not in x]
for path in src_files:
    print("Adding: " + path)
    lib.add_source_file(path)

# Set compile options
vu.set_compile_option("ghdl.flags", ["--ieee=standard", "-Wno-hide"])
vu.add_external_library("unisim", lib_unisim_path)

# Run vunit function
vu.main()
