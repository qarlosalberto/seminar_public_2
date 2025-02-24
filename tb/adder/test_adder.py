import cocotb
from cocotb.triggers import Timer, RisingEdge

CLOCK_PERIOD_IN_NS = 5

async def clock_proc(dut):
    while True:
        dut.clk.value = 0
        await Timer(CLOCK_PERIOD_IN_NS/2, units="ns")
        dut.clk.value = 1
        await Timer(CLOCK_PERIOD_IN_NS/2, units="ns")


@cocotb.test()
async def adder_basic_test(dut):
    """Test for 5 + 10"""
    dut.data_0_in.value = 0
    dut.data_1_in.value = 0

    clock = cocotb.create_task(clock_proc(dut))
    cocotb.start_soon(clock)

    await Timer(10*CLOCK_PERIOD_IN_NS, units="ns") # wait for 10*CLOCK_PERIOD_IN_NS
    await RisingEdge(dut.clk)

    data_0 = 5
    data_1 = 10

    dut.data_0_in.value = data_0
    dut.data_1_in.value = data_1

    await Timer(4*CLOCK_PERIOD_IN_NS, units="ns")

    assert dut.data_out.value == data_0 + data_1, (
        f"Adder result is incorrect: {dut.data_out.value} != 15"
    )

    await Timer(20*CLOCK_PERIOD_IN_NS, units="ns")

@cocotb.test()
async def adder_basic_test_2(dut):
    """Test for 5 + 11"""
    dut.data_0_in.value = 0
    dut.data_1_in.value = 0

    clock = cocotb.create_task(clock_proc(dut))
    cocotb.start_soon(clock)

    await Timer(10*CLOCK_PERIOD_IN_NS, units="ns") # wait for 10*CLOCK_PERIOD_IN_NS
    await RisingEdge(dut.clk)

    data_0 = 5
    data_1 = 11

    dut.data_0_in.value = data_0
    dut.data_1_in.value = data_1

    await Timer(4*CLOCK_PERIOD_IN_NS, units="ns")

    assert dut.data_out.value == data_0 + data_1, (
        f"Adder result is incorrect: {dut.data_out.value} != 16"
    )

    await Timer(20*CLOCK_PERIOD_IN_NS, units="ns")


