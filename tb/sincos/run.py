from vunit import VUnit
from pathlib import Path
from utils.vivado_utils import add_vivado_ip
import os
import numpy as np
from fxpmath import Fxp

class SinCosModel:
    def sin(self, x: float) -> float:
        return np.sin(x)
    def cos(self, x: float) -> float:
        return np.cos(x)

os.environ["VUNIT_SIMULATOR"] = "modelsim"

VIVADO_LIB_PATH = Path("/home/carlos/bin/questa_libs")
ROOT = Path(__file__).parent / "utils"
CURRENT_DIR = Path(__file__).resolve().parent

NOF_VECTOR_TEST = 10
INPUT_TOTAL_BITS = 16
INPUT_FRAC_BITS = 13

def int_array_to_fixed_point_array(int_array, n_word, n_frac):
    fp_array = []
    for i in range(0, len(int_array)):
        new_val = Fxp(0, signed=True, n_word=n_word,n_frac=n_frac)
        new_val.set_val(int_array[i], raw=True)
        fp_array.append(new_val.get_val())
    return fp_array

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


def make_post_check(testname):
    def post_check(output_path):
        # Get the input data
        arr_phase_in = np.loadtxt(CURRENT_DIR / f"{testname}_data_input.csv", delimiter=",", dtype=int)
        arr_phase_fp_in = int_array_to_fixed_point_array(arr_phase_in, INPUT_TOTAL_BITS, INPUT_FRAC_BITS)

        # Get the output data
        arr_cos = np.loadtxt(CURRENT_DIR / f"{testname}_cos_output.csv", delimiter=",", dtype=int)
        arr_sin = np.loadtxt(CURRENT_DIR / f"{testname}_sin_output.csv", delimiter=",", dtype=int)
        output_arr_cos_fp = int_array_to_fixed_point_array(arr_cos, INPUT_TOTAL_BITS, INPUT_FRAC_BITS+1)
        output_arr_sin_fp = int_array_to_fixed_point_array(arr_sin, INPUT_TOTAL_BITS, INPUT_FRAC_BITS+1)

        golden_model= SinCosModel()
        expected_arr_cos = golden_model.cos(arr_phase_fp_in)
        expected_arr_sin = golden_model.sin(arr_phase_fp_in)

        # compare the results size
        if len(expected_arr_cos) != len(output_arr_cos_fp):
            print(f"ERROR: The size of the expected and output arrays are different. Expected: {len(expected_arr_cos)}, Output: {len(output_arr_cos_fp)}")
            return False
        if len(expected_arr_sin) != len(output_arr_sin_fp):
            print(f"ERROR: The size of the expected and output arrays are different. Expected: {len(expected_arr_sin)}, Output: {len(output_arr_sin_fp)}")
            return False

        # compare the results
        NOF_DECIMAL_TO_COMPARE = 2
        ERROR_MARGIN = 10**(-NOF_DECIMAL_TO_COMPARE)
        for i in range(0, len(expected_arr_cos)):
            if abs(expected_arr_cos[i] - output_arr_cos_fp[i]) > ERROR_MARGIN:
                print(f"ERROR: The expected and output values are different at index {i}. Expected: {expected_arr_cos[i]:.3f}, Output: {output_arr_cos_fp[i]:.{NOF_DECIMAL_TO_COMPARE}f}")
                return False
            if abs(expected_arr_sin[i] - output_arr_sin_fp[i]) > ERROR_MARGIN:
                print(f"ERROR: The expected and output values are different at index {i}. Expected: {expected_arr_sin[i]:.3f}, Output: {output_arr_sin_fp[i]:.{NOF_DECIMAL_TO_COMPARE}f}")
                return False

        return True
    return post_check

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
test_checker.set_post_check(make_post_check(test_name))


vu.main()