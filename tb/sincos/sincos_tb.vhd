
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library dsp;
--

library vunit_lib;
    context vunit_lib.vunit_context;
    use vunit_lib.array_pkg.all;
    use vunit_lib.integer_array_pkg.all;

entity sincos_tb is
    generic (
        g_TEST_NAME : string;
        g_TB_PATH   : string;
        RUNNER_CFG  : string
    );
end entity sincos_tb;

architecture bench of sincos_tb is
    -- Clock period
    constant CLK_PERIOD     : time     := 5 ns;
    constant cnt_DATA_WIDTH : positive := 16;

    -- Generics
    -- Ports
    signal aclk                : std_logic := '0';
    signal s_axis_phase_tvalid : std_logic;
    signal s_axis_phase_tdata  : std_logic_vector(15 downto 0);
    signal m_axis_dout_tvalid  : std_logic;
    signal m_axis_dout_tdata   : std_logic_vector(31 downto 0);

    signal sin_data : std_logic_vector(cnt_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal cos_data : std_logic_vector(cnt_DATA_WIDTH - 1 downto 0) := (others => '0');

    signal finish_test : boolean := false;
begin

    cos_data <= m_axis_dout_tdata(cnt_DATA_WIDTH - 1 downto 0);
    sin_data <= m_axis_dout_tdata(cnt_DATA_WIDTH * 2 - 1 downto cnt_DATA_WIDTH);

    sincos_inst : entity dsp.sincos
        port map (
            aclk                => aclk,
            s_axis_phase_tvalid => s_axis_phase_tvalid,
            s_axis_phase_tdata  => s_axis_phase_tdata,
            m_axis_dout_tvalid  => m_axis_dout_tvalid,
            m_axis_dout_tdata   => m_axis_dout_tdata
        );

    main : process is
        variable data_input : integer_array_t;

    begin
        test_runner_setup(runner, RUNNER_CFG);
        while test_suite loop
            if run("test_cordic") then
                data_input := load_csv(g_TB_PATH & "/" & g_TEST_NAME & "_data_input.csv");

                wait for 100 * CLK_PERIOD;
                wait until rising_edge(aclk);

                for i in 0 to data_input.length - 1 loop
                    s_axis_phase_tvalid <= '1';
                    s_axis_phase_tdata  <= std_logic_vector(to_signed(get(data_input, i), cnt_DATA_WIDTH));
                    wait until (rising_edge(aclk));
                end loop;
                s_axis_phase_tvalid <= '0';

                wait for 100 * CLK_PERIOD;
                finish_test <= true;
                wait until rising_edge(aclk);

                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    process is
        variable data_output_sin_array : integer_array_t := new_1d(length => 0, bit_width => cnt_DATA_WIDTH, is_signed => true);
        variable data_output_cos_array : integer_array_t := new_1d(length => 0, bit_width => cnt_DATA_WIDTH, is_signed => true);

    begin
        if (finish_test = true) then
            info("Test finished");
            save_csv(data_output_sin_array, g_TB_PATH & "/" & g_TEST_NAME & "_sin_output.csv");
            save_csv(data_output_cos_array, g_TB_PATH & "/" & g_TEST_NAME & "_cos_output.csv");
            wait;
        else
            if (m_axis_dout_tvalid = '1') then
                append(data_output_sin_array, to_integer(signed(sin_data)));
                append(data_output_cos_array, to_integer(signed(cos_data)));
            end if;
        end if;
        wait until rising_edge(aclk);
    end process;

    aclk <= not aclk after CLK_PERIOD / 2;

end architecture bench;
