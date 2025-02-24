TOPLEVEL_LOANG = vhdl

PWD=$(shell pwd)

VHDL_SOURCES_COMMON = $(PWD)/../../src/common/type_declaration_pkg.vhd
VHDL_SOURCES_DSP = $(PWD)/../../src/dsp/adder.vhd
VHDL_SOURCES = $(PWD)/adder_wrapper.vhd

EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

include $(shell cocotb-config --makefiles)/Makefile.sim