library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library xil_defaultlib;

entity sincos is
    port (
        aclk                : in    std_logic;
        s_axis_phase_tvalid : in    std_logic;
        s_axis_phase_tdata  : in    std_logic_vector(15 downto 0);
        m_axis_dout_tvalid  : out   std_logic;
        m_axis_dout_tdata   : out   std_logic_vector(31 downto 0)
    );
end entity sincos;

architecture rtl of sincos is

begin

    cordic_inst : entity xil_defaultlib.cordic_0
        port map (
            aclk                => aclk,
            s_axis_phase_tvalid => s_axis_phase_tvalid,
            s_axis_phase_tdata  => s_axis_phase_tdata,
            m_axis_dout_tvalid  => m_axis_dout_tvalid,
            m_axis_dout_tdata   => m_axis_dout_tdata
        );

end architecture rtl;
