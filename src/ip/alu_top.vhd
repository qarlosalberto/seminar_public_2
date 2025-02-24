library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library common;
    use common.type_declaration_pkg.all;

library dsp;

library axi_interface;
    use axi_interface.example_dsp_regs_pkg.all;

entity alu_top is
    generic (
        g_DATA_WIDTH : positive := 8;
        AXI_ADDR_WIDTH : integer := 32
    );
    port (
        clk            : in    std_logic;
        data_valid_in  : in    std_logic;
        data_in        : in    t_data(data_0(g_DATA_WIDTH - 1 downto 0), data_1(g_DATA_WIDTH - 1 downto 0));
        data_valid_out : out   std_logic;
        data_out       : out   std_logic_vector(g_DATA_WIDTH downto 0);
        -- Clock and Reset
        axi_aclk    : in    std_logic;
        axi_aresetn : in    std_logic;
        -- AXI Write Address Channel
        s_axi_awaddr  : in    std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot  : in    std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_awvalid : in    std_logic;
        s_axi_awready : out   std_logic;
        -- AXI Write Data Channel
        s_axi_wdata  : in    std_logic_vector(31 downto 0);
        s_axi_wstrb  : in    std_logic_vector(3 downto 0);
        s_axi_wvalid : in    std_logic;
        s_axi_wready : out   std_logic;
        -- AXI Read Address Channel
        s_axi_araddr  : in    std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot  : in    std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_arvalid : in    std_logic;
        s_axi_arready : out   std_logic;
        -- AXI Read Data Channel
        s_axi_rdata  : out   std_logic_vector(31 downto 0);
        s_axi_rresp  : out   std_logic_vector(1 downto 0);
        s_axi_rvalid : out   std_logic;
        s_axi_rready : in    std_logic;
        -- AXI Write Response Channel
        s_axi_bresp  : out   std_logic_vector(1 downto 0);
        s_axi_bvalid : out   std_logic;
        s_axi_bready : in    std_logic
    );
end entity alu_top;

architecture rtl of alu_top is
    signal user2regs : user2regs_t;
    signal regs2user : regs2user_t;

    signal operation_in : std_logic;
begin

    user2regs.version_version <= x"FFBBCAFE";
    example_dsp_regs_inst : entity axi_interface.example_dsp_regs
        port map (
            axi_aclk      => axi_aclk,
            axi_aresetn   => axi_aresetn,
            s_axi_awaddr  => s_axi_awaddr,
            s_axi_awprot  => s_axi_awprot,
            s_axi_awvalid => s_axi_awvalid,
            s_axi_awready => s_axi_awready,
            s_axi_wdata   => s_axi_wdata,
            s_axi_wstrb   => s_axi_wstrb,
            s_axi_wvalid  => s_axi_wvalid,
            s_axi_wready  => s_axi_wready,
            s_axi_araddr  => s_axi_araddr,
            s_axi_arprot  => s_axi_arprot,
            s_axi_arvalid => s_axi_arvalid,
            s_axi_arready => s_axi_arready,
            s_axi_rdata   => s_axi_rdata,
            s_axi_rresp   => s_axi_rresp,
            s_axi_rvalid  => s_axi_rvalid,
            s_axi_rready  => s_axi_rready,
            s_axi_bresp   => s_axi_bresp,
            s_axi_bvalid  => s_axi_bvalid,
            s_axi_bready  => s_axi_bready,
            user2regs     => user2regs,
            regs2user     => regs2user
        );

    op_proc : process (clk) is
    begin
        if rising_edge(clk) then
            if (regs2user.operation_mode_strobe = '1') then
                operation_in <= regs2user.operation_mode_select_operation_mode(0);
            end if;
        end if;
    end process op_proc;

    alu_inst : entity dsp.alu
        generic map (
            g_data_width => g_DATA_WIDTH
        )
        port map (
            clk            => clk,
            operation_in   => operation_in,
            data_valid_in  => data_valid_in,
            data_in        => data_in,
            data_valid_out => data_valid_out,
            data_out       => data_out
        );

end architecture rtl;
