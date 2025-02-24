from vunit import VUnit
from pathlib import Path
from utils.vivado_utils import add_vivado_ip
import os
import numpy as np
from fxpmath import Fxp

os.environ["VUNIT_SIMULATOR"] = "modelsim"

VIVADO_LIB_PATH = Path("/home/carlos/bin/questa_libs")
ROOT = Path(__file__).parent / "utils"
CURRENT_DIR = Path(__file__).resolve().parent

NOF_VECTOR_TEST = 10
INPUT_TOTAL_BITS = 16
INPUT_FRAC_BITS = 13


def make_pre_config(testname):
    def pre_config(output_path):
        random_array_np = np.random.uniform(-np.pi, np.pi, NOF_VECTOR_TEST)
        random_array = Fxp(random_array_np, signed=True, n_word=INPUT_TOTAL_BITS,n_frac=INPUT_FRAC_BITS).base_repr(10)

        data_input_file_path = CURRENT_DIR  / f"{testname}_data_input.csv"

        new_int_array = np.zeros((NOF_VECTOR_TEST), dtype=int)
        for i in range(0, NOF_VECTOR_TEST):
            new_int_array[i] = random_array[i]

        np.savetxt(data_input_file_path, new_int_array, delimiter=",", fmt='%d')
        return True
    return pre_config



vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()

dsp_lib = vu.add_library("dsp")
dsp_lib.add_source_files("../../src/dsp/sincos.vhd")

for library_name in ["unisim", "unimacro", "unifast", "secureip", "xpm"]:
    path = str(Path(VIVADO_LIB_PATH) / library_name)
    if Path(path).exists():
        vu.add_external_library(library_name, path)
    else:
        print(f"ERROR: {path} not found")
        exit(1)

tb_lib = vu.add_library("tb_lib")
tb_lib.add_source_files("*.vhd")

vu.add_array_util()

add_vivado_ip(
    vu,
    output_path=ROOT / "vivado_libs",
    project_file=ROOT / "myproject" / "myproject.xpr",
)

test_name = "test_cordic"
test_checker = tb_lib.test_bench("sincos_tb").test(test_name)
test_checker.set_generic("g_TB_PATH", CURRENT_DIR)
test_checker.set_generic("g_TEST_NAME", test_name)

test_checker.set_pre_config(make_pre_config(test_name))


vu.main()