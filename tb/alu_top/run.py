# pip install vunit_helpers
from vunit import VUnit
import os
from vunit_helpers import add_uvvm_sources, set_ghdl_flags_for_UVVM

UVVM_PATH = "/home/carlos/repo/UVVM/"

os.environ["VUNIT_SIMULATOR"] = "ghdl"

vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()


dsp_lib = vu.add_library("common")
dsp_lib.add_source_files("../../src/common/type_declaration_pkg.vhd")

dsp_lib = vu.add_library("common_blocks")
dsp_lib.add_source_files("../../src/common_blocks/shift_reg.vhd")

dsp_lib = vu.add_library("dsp")
dsp_lib.add_source_files("../../src/dsp/adder.vhd")
dsp_lib.add_source_files("../../src/dsp/sub.vhd")
dsp_lib.add_source_files("../../src/dsp/alu.vhd")

dsp_lib = vu.add_library("axi_interface")
dsp_lib.add_source_files("../../src/ip/example_dsp_regs_pkg.vhd")
dsp_lib.add_source_files("../../src/ip/example_dsp_regs.vhd")

src_lib = vu.add_library("src_lib")
src_lib.add_source_files("../../src/ip/alu_top.vhd")

add_uvvm_sources(vu, UVVM_PATH)

tb_lib = vu.add_library("tb_lib")
tb_lib.add_source_files("*.vhd")

if vu.get_simulator_name() == "ghdl":
    vu.set_sim_option("ghdl.sim_flags", ["--wave=./wave.ghw"])
    set_ghdl_flags_for_UVVM(vu)

vu.main()