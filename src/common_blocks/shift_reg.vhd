library ieee;
    use ieee.std_logic_1164.all;

entity shift_reg is
    generic (
        g_SIZE       : positive := 20;
        g_DATA_WIDTH : positive := 8
    );
    port (
        clk      : in    std_logic;
        data_in  : in    std_logic_vector(g_DATA_WIDTH - 1 downto 0);
        data_out : out   std_logic_vector(g_DATA_WIDTH - 1 downto 0)
    );
end entity shift_reg;

architecture rtl of shift_reg is
    type   a_reg is array (natural range 0 to g_SIZE - 1) of std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    signal shift_reg : a_reg;
begin

    shift_proc : process (clk) is
    begin
        if rising_edge(clk) then
            for i in g_SIZE - 1 downto 1 loop
                shift_reg(i) <= shift_reg(i - 1);
            end loop;
            shift_reg(0) <= data_in;
        end if;
    end process shift_proc;
    data_out <= shift_reg(g_SIZE - 1);

end architecture rtl;
