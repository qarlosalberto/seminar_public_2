from vunit import VUnit
import os

os.environ["VUNIT_SIMULATOR"] = "ghdl"

vu = VUnit.from_argv(compile_builtins=True)
vu.add_vhdl_builtins()

src_lib = vu.add_library("src_lib")
src_lib.add_source_files("../../src/common_blocks/memory.vhd")

tb_lib = vu.add_library("tb_lib")
tb_lib.add_source_files("*.vhd")

if vu.get_simulator_name() == "ghdl":
    vu.set_compile_option("ghdl.a_flags", ["--std=08"])
    vu.set_sim_option("ghdl.sim_flags", ["--wave=./wave.ghw"])

test = tb_lib.test_bench("memory_vunit_tb").test("simple_test")

tb_path = os.path.dirname(os.path.realpath(__file__))

test.add_config(
    name="test with RTL arch",
    generics=dict(
        g_TB_PATH = tb_path,
        g_IS_RTL = True,
        g_RAM_STYLE = "BLOCK",
    ),
)

test.add_config(
    name="test bram_mem arch and BLOCK",
    generics=dict(
        g_TB_PATH = tb_path,
        g_IS_RTL = False,
        g_RAM_STYLE = "BLOCK",
    ),
)

test.add_config(
    name="test with bram_mem arch and DISTRIBUTED",
    generics=dict(
        g_TB_PATH = tb_path,
        g_IS_RTL = False,
        g_RAM_STYLE = "DISTRIBUTED",
    ),
)

vu.main()