library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity tb_all is
end tb_all;

architecture Behavioral of tb_all is

constant CLK_PERIOD : time := 10 ns;
constant AUDIO_DATA_WIDTH : integer := 24;
signal sine_data : std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0);
--signal data_in   : std_logic;
signal bit_count : integer range 0 to AUDIO_DATA_WIDTH-1 := 0;
constant SINE_FREQ   : real := 440.0;             -- Hz (A4 note)
constant SINE_AMPL   : real := 2.0**22;           -- match your audio amplitude
constant T_SAMPLE    : real := 1.0 / 48000.0;      -- 48kHz sample rate


-- Clock and reset
signal aclk         : std_logic := '0';
signal aresetn      : std_logic := '0';

-- I2S passthrough signals
signal mux_select       : std_logic := '1';
signal ac_mute_en_i     : std_logic := '0';
signal dds_enable_i     : std_logic := '1';
signal dds_reset_i      : std_logic := '0';
signal ac_adc_data_i    : std_logic := '0';
signal ac_dac_data_o    : std_logic;
signal ac_bclk_o        : std_logic;
signal ac_mclk_o        : std_logic;
signal ac_mute_n_o      : std_logic;
signal ac_dac_lrclk_o   : std_logic;
signal ac_adc_lrclk_o   : std_logic;

-- AXI signals
signal tvalid, tready, tlast : std_logic := '0';
signal tdata  : std_logic_vector(31 downto 0);
signal tstrb  : std_logic_vector(3 downto 0);

-- Video data
signal video_in   : std_logic_vector(23 downto 0) := x"FF0000";
signal video_out  : std_logic_vector(23 downto 0);

-- Output from video transform
signal amp_tdata  : std_logic_vector(31 downto 0);

signal clk, mclk           : std_logic := '0';
signal resetn              : std_logic := '0';
signal mute_en_not         : std_logic := '1';
signal constant_red_pixel  : std_logic_vector(23 downto 0) := x"FF0000";

-- AXIS internal
signal axis_tx_valid, axis_tx_ready, axis_tx_last : std_logic;
signal axis_tx_data : std_logic_vector(31 downto 0);
signal axis_tx_strb : std_logic_vector(3 downto 0);
signal axis_rx_valid, axis_rx_ready, axis_rx_last : std_logic;
signal axis_rx_data : std_logic_vector(31 downto 0);
signal axis_rx_strb : std_logic_vector(3 downto 0);


component audio_passthrough
    generic (
        C_AXI_STREAM_DATA_WIDTH : integer := 32;
        C_S00_AXI_DATA_WIDTH    : integer := 32;
        C_S00_AXI_ADDR_WIDTH    : integer := 4
    );
    port (
        mclk_i           : in std_logic;
        mux_select       : in std_logic;
        ac_mute_en_i     : in std_logic;
        ac_bclk_o        : out std_logic;
        ac_mclk_o        : out std_logic;
        ac_mute_n_o      : out std_logic;
        ac_dac_data_o    : out std_logic;
        ac_dac_lrclk_o   : out std_logic;
        ac_adc_data_i    : in std_logic;
        ac_adc_lrclk_o   : out std_logic;
        dds_enable_i     : in std_logic;
        dds_reset_i      : in std_logic;
        s00_axi_aclk     : in std_logic;
        s00_axi_aresetn  : in std_logic;
        s00_axi_awaddr   : in std_logic_vector(3 downto 0);
        s00_axi_awprot   : in std_logic_vector(2 downto 0);
        s00_axi_awvalid  : in std_logic;
        s00_axi_awready  : out std_logic;
        s00_axi_wdata    : in std_logic_vector(31 downto 0);
        s00_axi_wstrb    : in std_logic_vector(3 downto 0);
        s00_axi_wvalid   : in std_logic;
        s00_axi_wready   : out std_logic;
        s00_axi_bresp    : out std_logic_vector(1 downto 0);
        s00_axi_bvalid   : out std_logic;
        s00_axi_bready   : in std_logic;
        s00_axi_araddr   : in std_logic_vector(3 downto 0);
        s00_axi_arprot   : in std_logic_vector(2 downto 0);
        s00_axi_arvalid  : in std_logic;
        s00_axi_arready  : out std_logic;
        s00_axi_rdata    : out std_logic_vector(31 downto 0);
        s00_axi_rresp    : out std_logic_vector(1 downto 0);
        s00_axi_rvalid   : out std_logic;
        s00_axi_rready   : in std_logic;
        m00_axis_aclk    : in std_logic;
        m00_axis_aresetn : in std_logic;
        m00_axis_tvalid  : out std_logic;
        m00_axis_tdata   : out std_logic_vector(31 downto 0);
        m00_axis_tstrb   : out std_logic_vector(3 downto 0);
        m00_axis_tlast   : out std_logic;
        m00_axis_tready  : in std_logic
    );
end component;

component axis_fifo
    generic (
        DATA_WIDTH : integer := 32;
        FIFO_DEPTH : integer := 1024
    );
    port (
        s00_axis_aclk     : in std_logic;
        s00_axis_aresetn  : in std_logic;
        s00_axis_tready   : out std_logic;
        s00_axis_tdata    : in std_logic_vector(31 downto 0);
        s00_axis_tlast    : in std_logic;
        s00_axis_tvalid   : in std_logic;
        m00_axis_aclk     : in std_logic;
        m00_axis_aresetn  : in std_logic;
        m00_axis_tvalid   : out std_logic;
        m00_axis_tdata    : out std_logic_vector(31 downto 0);
        m00_axis_tlast    : out std_logic;
        m00_axis_tready   : in std_logic
    );
end component;

component video_transform
    generic (
        C_VIDEO_DATA_WIDTH  : integer := 24;
        C_AUDIO_DATA_WIDTH  : integer := 32;
        C_OUTPUT_DATA_WIDTH : integer := 32
    );
    port (
        Video_in             : in std_logic_vector(23 downto 0);
        Video_out            : out std_logic_vector(23 downto 0);
        mute_en_not          : in std_logic;
        s_axis_audio_aclk    : in std_logic;
        s_axis_audio_aresetn : in std_logic;
        s_axis_audio_tdata   : in std_logic_vector(31 downto 0);
        s_axis_audio_tvalid  : in std_logic;
        s_axis_audio_tlast   : in std_logic;
        s_axis_audio_tready  : out std_logic;
        m_axis_amp_tdata     : out std_logic_vector(31 downto 0)
    );
end component;

begin

-- AUDIO PASSTHROUGH
audio_passthrough_inst : entity work.audio_passthrough
    generic map (
        C_AXI_STREAM_DATA_WIDTH => 32,
        C_S00_AXI_DATA_WIDTH    => 32,
        C_S00_AXI_ADDR_WIDTH    => 4
    )
    port map (
        -- Clocks
        mclk_i            => mclk,
        s00_axi_aclk      => clk,
        s00_axi_aresetn   => resetn,
        m00_axis_aclk     => clk,
        m00_axis_aresetn  => resetn,

        -- I2S I/O (not used in TB)
        mux_select        => mux_select,
        ac_mute_en_i      => ac_mute_en_i,
        ac_adc_data_i     => ac_adc_data_i,
        ac_dac_data_o     => ac_dac_data_o,
        ac_bclk_o         => ac_bclk_o,
        ac_mclk_o         => ac_mclk_o,
        ac_mute_n_o       => mute_en_not,
        ac_adc_lrclk_o    => open,
        ac_dac_lrclk_o    => ac_dac_lrclk_o,

        -- AXI Lite (not used in TB)
        dds_enable_i      => dds_enable_i,
        dds_reset_i       => dds_reset_i,
        s00_axi_awaddr    => (others => '0'),
        s00_axi_awprot    => (others => '0'),
        s00_axi_awvalid   => '0',
        s00_axi_awready   => open,
        s00_axi_wdata     => (others => '0'),
        s00_axi_wstrb     => (others => '0'),
        s00_axi_wvalid    => '0',
        s00_axi_wready    => open,
        s00_axi_bresp     => open,
        s00_axi_bvalid    => open,
        s00_axi_bready    => '0',
        s00_axi_araddr    => (others => '0'),
        s00_axi_arprot    => (others => '0'),
        s00_axi_arvalid   => '0',
        s00_axi_arready   => open,
        s00_axi_rdata     => open,
        s00_axi_rresp     => open,
        s00_axi_rvalid    => open,
        s00_axi_rready    => '0',

        -- AXIS output
        m00_axis_tvalid   => axis_tx_valid,
        m00_axis_tdata    => axis_tx_data,
        m00_axis_tstrb    => axis_tx_strb,
        m00_axis_tlast    => axis_tx_last,
        m00_axis_tready   => axis_tx_ready
    );

-- AXIS FIFO
axis_fifo_inst : entity work.axis_fifo
    generic map (
        DATA_WIDTH => 32,
        FIFO_DEPTH => 1024
    )
    port map (
        -- Slave AXIS (input from transmitter)
        s00_axis_aclk     => clk,
        s00_axis_aresetn  => resetn,
        s00_axis_tvalid   => axis_tx_valid,
        s00_axis_tdata    => axis_tx_data,
        s00_axis_tlast    => axis_tx_last,
        s00_axis_tready   => axis_tx_ready,

        -- Master AXIS (output to video_transform)
        m00_axis_aclk     => clk,
        m00_axis_aresetn  => resetn,
        m00_axis_tvalid   => axis_rx_valid,
        m00_axis_tdata    => axis_rx_data,
        m00_axis_tlast    => axis_rx_last,
        m00_axis_tready   => axis_rx_ready
    );

-- VIDEO TRANSFORM
video_transform_inst : entity work.video_transform
    generic map (
        C_VIDEO_DATA_WIDTH  => 24,
        C_AUDIO_DATA_WIDTH  => 32,
        C_OUTPUT_DATA_WIDTH => 32
    )
    port map (
        Video_in             => constant_red_pixel,
        Video_out            => Video_out,
        mute_en_not          => mute_en_not,
        s_axis_audio_aclk    => clk,
        s_axis_audio_aresetn => resetn,
        s_axis_audio_tdata   => axis_rx_data,
        s_axis_audio_tvalid  => axis_rx_valid,
        s_axis_audio_tlast   => axis_rx_last,
        s_axis_audio_tready  => axis_rx_ready,
        m_axis_amp_tdata     => open
    );

-- AXI system clock (100 MHz)
clk_gen_proc : process
begin
    while true loop
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end loop;
end process;

-- Audio master clock (12.288 MHz ~81.4 ns period)
mclk_gen_proc : process
begin
    while true loop
        mclk <= '0';
        wait for 40.7 ns;
        mclk <= '1';
        wait for 40.7 ns;
    end loop;
end process;

-- Active-low reset pulse
reset_proc : process
begin
    resetn <= '0';
    wait for 100 ns;  -- hold reset low
    resetn <= '1';
    wait;
end process;


generate_audio_data : process
    variable t : real := 0.0;
    variable sample  : integer;
    variable tx_data : std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0);
begin
    wait for 1 us; -- give time for clocks to stabilize

    while true loop
        --------------------------------------------------------------------
        -- Generate sine sample at time t
        sample := integer(SINE_AMPL * sin(2.0 * math_pi * SINE_FREQ * t));
        sine_data <= std_logic_vector(to_signed(sample, AUDIO_DATA_WIDTH));

        -- Format sample to I2S (invert MSB)
        tx_data := not(sine_data(AUDIO_DATA_WIDTH-1)) & sine_data(AUDIO_DATA_WIDTH-2 downto 0);

        --------------------------------------------------------------------
        -- Wait for Right Channel (lrclk = '1')
        wait until rising_edge(ac_bclk_o) and ac_dac_lrclk_o = '1';
        bit_count <= AUDIO_DATA_WIDTH - 1;

        for i in 0 to AUDIO_DATA_WIDTH-1 loop
            wait until falling_edge(ac_bclk_o);
            ac_adc_data_i <= tx_data(bit_count - i);
        end loop;

        ac_adc_data_i <= '0';

        --------------------------------------------------------------------
        -- Wait for Left Channel (lrclk = '0')
        wait until rising_edge(ac_bclk_o) and ac_dac_lrclk_o = '0';
        bit_count <= AUDIO_DATA_WIDTH - 1;

        for i in 0 to AUDIO_DATA_WIDTH-1 loop
            wait until falling_edge(ac_bclk_o);
            ac_adc_data_i <= tx_data(bit_count - i);
        end loop;

        ac_adc_data_i <= '0';

        --------------------------------------------------------------------
        -- Advance time
        t := t + T_SAMPLE;
    end loop;
end process;



end Behavioral;
