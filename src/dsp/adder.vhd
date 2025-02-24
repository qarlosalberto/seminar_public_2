library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library common;
    use common.type_declaration_pkg.all;

entity adder is
    generic (
        g_DATA_WIDTH : positive := 8
    );
    port (
        clk      : in    std_logic;
        data_in  : in    t_data(data_0(g_DATA_WIDTH - 1 downto 0), data_1(g_DATA_WIDTH - 1 downto 0));
        data_out : out   std_logic_vector(g_DATA_WIDTH downto 0)
    );
end entity adder;

architecture rtl of adder is
begin

    dsp_inst : process (clk) is
    begin
        if rising_edge(clk) then
            data_out <= std_logic_vector(
                                         resize(signed(data_in.data_0), data_out'length)
                                         + resize(signed(data_in.data_1), data_out'length));
        end if;
    end process dsp_inst;

end architecture rtl;
