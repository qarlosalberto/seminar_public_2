
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.textio.all;

library src_lib;
    use src_lib.memory;

library vunit_lib;
    context vunit_lib.vunit_context;

entity memory_vunit_tb is
    generic (
        g_TB_PATH   : string;
        -- vsg_off generic_020
        RUNNER_CFG  : string;
        g_IS_RTL    : boolean;
        g_RAM_STYLE : string
    );
end entity memory_vunit_tb;

architecture bench of memory_vunit_tb is
    -- Clock period
    constant cnt_CLK_PERIOD : time := 5 ns;
    -- Generics
    constant cnt_G_DATA_WIDTH : positive := 8;
    constant cnt_G_ADDR_WIDTH : positive := 4;
    -- Ports
    signal clk             : std_logic := '0';
    signal write_enable_in : std_logic := '0';

    signal write_address_in : std_logic_vector(cnt_G_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal data_in          : std_logic_vector(cnt_G_DATA_WIDTH - 1 downto 0) := (others => '0');

    signal read_enable_in : std_logic := '0';

    signal read_address_in : std_logic_vector(cnt_G_ADDR_WIDTH - 1 downto 0) := (others => '0');

    signal data_out        : std_logic_vector(cnt_G_DATA_WIDTH - 1 downto 0);
    signal read_enable_out : std_logic;
begin

    main_proc : process is
        constant cnt_FILE_NAME : string := g_TB_PATH & "/mem_data.dat";

        file     input_file      : text;
        variable line_buffer     : line;
        variable data_value      : std_logic_vector(cnt_G_DATA_WIDTH - 1 downto 0);
        variable current_address : unsigned(cnt_G_ADDR_WIDTH - 1 downto 0) := (others => '0');

        constant cnt_READ_ID     : id_t     := get_id("memory:read");
        constant cnt_READ_LOGGER : logger_t := get_logger(cnt_READ_ID);

        constant cnt_WRITE_ID     : id_t     := get_id("memory:write");
        constant cnt_WRITE_LOGGER : logger_t := get_logger(cnt_WRITE_ID);

        variable cnt_log_handler_rd : log_handler_t;
        variable cnt_log_handler_wr : log_handler_t;

    begin

        test_runner_setup(runner, RUNNER_CFG);
        while test_suite loop
            if run("simple_test") then
                cnt_log_handler_rd := new_log_handler(running_test_case & "log_rd.log", format => verbose, use_color => false);
                cnt_log_handler_wr := new_log_handler(running_test_case & "log_wr.log", format => verbose, use_color => false);

                show_all(cnt_READ_LOGGER, cnt_log_handler_rd);
                show_all(cnt_WRITE_LOGGER, cnt_log_handler_wr);

                set_log_handlers(cnt_READ_LOGGER, (display_handler, cnt_log_handler_rd));
                set_log_handlers(cnt_WRITE_LOGGER, (display_handler, cnt_log_handler_wr));

                wait for 20 * cnt_CLK_PERIOD;

                -- Write data to memory
                file_open(input_file, cnt_FILE_NAME);
                while not endfile(input_file) loop
                    readline(input_file, line_buffer);
                    read(line_buffer, data_value);

                    write_enable_in  <= '1';
                    write_address_in <= std_logic_vector(current_address);
                    data_in          <= std_logic_vector(data_value);

                    info(cnt_READ_LOGGER,
                         "Writing data " & to_string(to_integer(unsigned(data_value))) &
                         " to address " & to_string(to_integer(unsigned(current_address)))
                     );

                    current_address := current_address + 1;

                    wait for cnt_CLK_PERIOD;
                end loop;
                write_enable_in <= '0';
                current_address := (others => '0');
                file_close(input_file);

                -- Read data from memory
                file_open(input_file, cnt_FILE_NAME);
                while not endfile(input_file) loop
                    read_enable_in  <= '1';
                    read_address_in <= std_logic_vector(current_address);

                    wait until rising_edge(read_enable_out);
                    read_enable_in <= '0';

                    readline(input_file, line_buffer);
                    read(line_buffer, data_value);

                    info(cnt_WRITE_LOGGER,
                         "Reading data from address " & to_string(to_integer(unsigned(current_address)))
                     );

                    assert data_out = data_value
                        report "Data mismatch: " & to_string(to_integer(unsigned(data_value))) & " /= "
                               & to_string(to_integer(unsigned(data_out))) & " in address "
                               & to_string(to_integer(unsigned(current_address)))
                        severity error;

                    current_address := current_address + 1;
                    wait until rising_edge(clk);
                end loop;
                file_close(input_file);
                read_enable_in <= '0';

                wait for 20 * cnt_CLK_PERIOD;

                test_runner_cleanup(runner);
            end if;
        end loop;

    end process main_proc;

    arch_selector_gen : if g_IS_RTL generate
        memory_inst : entity memory(rtl_mem)
            generic map (
                g_data_width => cnt_g_DATA_WIDTH,
                g_addr_width => cnt_g_ADDR_WIDTH
            )
            port map (
                clk              => clk,
                write_enable_in  => write_enable_in,
                write_address_in => write_address_in,
                data_in          => data_in,
                read_enable_in   => read_enable_in,
                read_address_in  => read_address_in,
                data_out         => data_out,
                read_enable_out  => read_enable_out
            );

    else generate
        memory_inst : entity memory(bram_mem)
            generic map (
                g_data_width => cnt_g_DATA_WIDTH,
                g_addr_width => cnt_g_ADDR_WIDTH,
                g_ram_style  => g_RAM_STYLE
            )
            port map (
                clk              => clk,
                write_enable_in  => write_enable_in,
                write_address_in => write_address_in,
                data_in          => data_in,
                read_enable_in   => read_enable_in,
                read_address_in  => read_address_in,
                data_out         => data_out,
                read_enable_out  => read_enable_out
            );

    end generate arch_selector_gen;

    clk <= not clk after cnt_CLK_PERIOD / 2;

end architecture bench;
