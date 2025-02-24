
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library common;
    use common.type_declaration_pkg.all;

library axi_interface;
    use axi_interface.example_dsp_regs_pkg.all;

library src_lib;

--

library vunit_lib;
    context vunit_lib.vunit_context;

library bitvis_vip_axilite;
    use bitvis_vip_axilite.axilite_bfm_pkg.all;

entity alu_top_tb is
    generic (
        RUNNER_CFG : string
    );
end entity alu_top_tb;

architecture bench of alu_top_tb is
    -- Clock period
    constant CLK_PERIOD : time := 1 ns;
    -- Generics
    constant AXI_ADDR_WIDTH : integer                       := 32;
    constant BASEADDR       : std_logic_vector(31 downto 0) := x"00000000";
    constant G_DATA_WIDTH   : positive                      := 8;
    -- Ports

    signal data_valid_in  : std_logic                               := '0';
    signal data_in        : t_data(data_0(G_DATA_WIDTH - 1 downto 0), data_1(G_DATA_WIDTH - 1 downto 0));
    signal data_valid_out : std_logic;
    signal data_out       : std_logic_vector(G_DATA_WIDTH downto 0) := (others => '0');

    signal clk           : std_logic := '0';
    signal axi_aclk      : std_logic := '0';
    signal axi_aresetn   : std_logic;
    signal s_axi_awaddr  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
    signal s_axi_awprot  : std_logic_vector(2 downto 0);
    signal s_axi_awvalid : std_logic;
    signal s_axi_awready : std_logic;
    signal s_axi_wdata   : std_logic_vector(31 downto 0);
    signal s_axi_wstrb   : std_logic_vector(3 downto 0);
    signal s_axi_wvalid  : std_logic;
    signal s_axi_wready  : std_logic;
    signal s_axi_araddr  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
    signal s_axi_arprot  : std_logic_vector(2 downto 0);
    signal s_axi_arvalid : std_logic;
    signal s_axi_arready : std_logic;
    signal s_axi_rdata   : std_logic_vector(31 downto 0);
    signal s_axi_rresp   : std_logic_vector(1 downto 0);
    signal s_axi_rvalid  : std_logic;
    signal s_axi_rready  : std_logic;
    signal s_axi_bresp   : std_logic_vector(1 downto 0);
    signal s_axi_bvalid  : std_logic;
    signal s_axi_bready  : std_logic;
    signal user2regs     : user2regs_t;
    signal regs2user     : regs2user_t;

    constant C_AXI_DATA_WIDTH : integer := 32;

    -- axilite_bfm signals
    signal axilite_bfm_config : t_axilite_bfm_config := C_AXILITE_BFM_CONFIG_DEFAULT;
    signal axilite_if         : t_axilite_if(
                                              write_address_channel(
                                                                       awaddr(AXI_ADDR_WIDTH - 1 downto 0)
                                                                   ),
                                              write_data_channel(
                                                                    wdata(AXI_ADDR_WIDTH - 1 downto 0),
                                                                    wstrb(4 - 1 downto 0)
                                                                ),
                                              read_address_channel(
                                                                      araddr(AXI_ADDR_WIDTH - 1 downto 0)
                                                                  ),
                                              read_data_channel(
                                                                   rdata(C_AXI_DATA_WIDTH - 1 downto 0)
                                                               )
                                          );
begin

    clk <= axi_aclk;
    alu_top_inst : entity src_lib.alu_top
        generic map (
            g_data_width => g_DATA_WIDTH
        )
        port map (
            clk            => clk,
            data_valid_in  => data_valid_in,
            data_in        => data_in,
            data_valid_out => data_valid_out,
            data_out       => data_out,
            axi_aclk       => axi_aclk,
            axi_aresetn    => '1',
            s_axi_awaddr   => axilite_if.write_address_channel.awaddr,
            s_axi_awprot   => axilite_if.write_address_channel.awprot,
            s_axi_awvalid  => axilite_if.write_address_channel.awvalid,
            s_axi_awready  => axilite_if.write_address_channel.awready,

            s_axi_wdata  => axilite_if.write_data_channel.wdata,
            s_axi_wstrb  => axilite_if.write_data_channel.wstrb,
            s_axi_wvalid => axilite_if.write_data_channel.wvalid,
            s_axi_wready => axilite_if.write_data_channel.wready,

            s_axi_araddr  => axilite_if.read_address_channel.araddr,
            s_axi_arprot  => axilite_if.read_address_channel.arprot,
            s_axi_arvalid => axilite_if.read_address_channel.arvalid,
            s_axi_arready => axilite_if.read_address_channel.arready,

            s_axi_rdata  => axilite_if.read_data_channel.rdata,
            s_axi_rresp  => axilite_if.read_data_channel.rresp,
            s_axi_rvalid => axilite_if.read_data_channel.rvalid,
            s_axi_rready => axilite_if.read_data_channel.rready,

            s_axi_bresp  => axilite_if.write_response_channel.bresp,
            s_axi_bvalid => axilite_if.write_response_channel.bvalid,
            s_axi_bready => axilite_if.write_response_channel.bready
        );

    main : process is
        constant cnt_ADDR_VALUE_VERSION : unsigned(AXI_ADDR_WIDTH - 1 downto 0) := x"00000000";
        constant cnt_ADDR_VALUE_MODE    : unsigned(AXI_ADDR_WIDTH - 1 downto 0) := x"00000004";
        variable data_value             : std_logic_vector(31 downto 0)         := x"00000000";

    begin
        test_runner_setup(runner, RUNNER_CFG);
        while test_suite loop
            if run("test_alive") then
                axi_aresetn <= '0';
                wait until rising_edge(axi_aclk);
                wait for 20 * CLK_PERIOD;
                axi_aresetn <= '1';
                wait for 20 * CLK_PERIOD;

                axilite_if <= init_axilite_if_signals(32, 32);
                wait for 20 * CLK_PERIOD;

                axilite_read(
                             cnt_ADDR_VALUE_VERSION,
                             data_value,
                             "Reading IP version",
                             axi_aclk,
                             axilite_if
                         );
                wait for 10 * CLK_PERIOD;

                -- Sub mode
                axilite_write(
                              cnt_ADDR_VALUE_MODE,
                              x"00000001",
                              "Writing sub mode",
                              axi_aclk,
                              axilite_if
                          );
                wait for 10 * CLK_PERIOD;

                data_in.data_0 <= std_logic_vector(to_signed(5, data_in.data_0'length));
                data_in.data_1 <= std_logic_vector(to_signed(3, data_in.data_1'length));
                data_valid_in  <= '1';
                wait for 3 * CLK_PERIOD;
                data_valid_in  <= '0';

                check(data_valid_out = '1', "Data valid out");
                check_equal(to_integer(signed(data_out)), 2, "Data out adder = 2");
                wait for 10 * CLK_PERIOD;

                -- Adder mode
                axilite_write(
                              cnt_ADDR_VALUE_MODE,
                              x"00000000",
                              "Writing adder mode",
                              axi_aclk,
                              axilite_if
                          );
                wait for 10 * CLK_PERIOD;

                data_in.data_0 <= std_logic_vector(to_signed(5, data_in.data_0'length));
                data_in.data_1 <= std_logic_vector(to_signed(3, data_in.data_1'length));
                data_valid_in  <= '1';
                wait for 3 * CLK_PERIOD;
                data_valid_in  <= '0';

                check(data_valid_out = '1', "Data valid out");
                check_equal(to_integer(signed(data_out)), 8, "Data out adder = 8");
                wait for 10 * CLK_PERIOD;

                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    axi_aclk <= not axi_aclk after CLK_PERIOD / 2;

end architecture bench;
