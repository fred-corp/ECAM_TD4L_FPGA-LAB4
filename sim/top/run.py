import sys
sys.path.append("~/Documents/ECAM/2024-2025/1MEO/Q2/TD4L_SoC/FPGA_2025/Labs/lab4-8_robot/sim/top/vunit")
from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
# or
# vu.add_verilog_builtins()

# Create library 'lib'
lib = vu.add_library("lib")

vu.add_vhdl_builtins()
vu.add_osvvm()
vu.add_verification_components()

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("*.vhd")
lib.add_source_files("../../rtl/*/*.vhd")
lib.add_source_files("../../open-logic/src/base/vhdl/*.vhd")
lib.add_source_files("../../open-logic/src/intf/vhdl/*.vhd")

# GHDL Flags
vu.set_compile_option("ghdl.a_flags", ["--std=08", "-frelaxed"])
vu.set_sim_option("ghdl.elab_flags", ["-frelaxed"])

# Run vunit function
vu.main()

