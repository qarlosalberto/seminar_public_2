library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library dsp;

entity adder_wrapper is
    generic (
        g_DATA_WIDTH : positive := 8
    );
    port (
        clk       : in    std_logic;
        data_0_in : in    std_logic_vector(g_DATA_WIDTH - 1 downto 0);
        data_1_in : in    std_logic_vector(g_DATA_WIDTH - 1 downto 0);
        data_out  : out   std_logic_vector(g_DATA_WIDTH downto 0)
    );
end entity adder_wrapper;

architecture rtl of adder_wrapper is
begin

    dsp_inst : entity dsp.adder
        generic map (
            g_data_width => g_DATA_WIDTH
        )
        port map (
            clk      => clk,
            data_in  => (data_0_in, data_1_in),
            data_out => data_out
        );

end architecture rtl;
