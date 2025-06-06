library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_rgb_transform is
end tb_rgb_transform;

architecture sim of tb_rgb_transform is

-- Constants
constant C_VIDEO_DATA_WIDTH : integer := 24;

-- DUT input signals
signal s_axis_clk       : std_logic := '0';
signal s_axis_resetn    : std_logic := '0';
signal peak_bin         : std_logic_vector(8 downto 0) := (others => '0');
signal video_in         : std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0) := (others => '0');
signal mute_en_not      : std_logic := '1';

-- VTC-driven signals
signal active_video_out : std_logic := '0';
signal fsync            : std_logic_vector(0 downto 0) := (others => '0');
signal vsync            : std_logic := '0';

-- DUT output
signal video_out        : std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);

-- DUT component
component rgb_transform
    generic (
        C_VIDEO_DATA_WIDTH : integer := 24
    );
    port (
        s_axis_clk       : IN  STD_LOGIC;
        s_axis_resetn    : IN  STD_LOGIC;
        mute_en_not      : IN  STD_LOGIC;
        fsync_i          : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        vsync_i          : IN  STD_LOGIC;
        peak_bin         : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        video_in         : IN  STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0);
        video_out        : OUT STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0)
    );
end component;

begin

-- Instantiate the DUT
dut_rgb_transform : rgb_transform
    generic map (
        C_VIDEO_DATA_WIDTH => C_VIDEO_DATA_WIDTH
    )
    port map (
        s_axis_clk       => s_axis_clk,
        s_axis_resetn    => s_axis_resetn,
        mute_en_not      => mute_en_not,
        fsync_i          => fsync,
        vsync_i          => vsync,
        peak_bin         => peak_bin,
        video_in         => video_in,
        video_out        => video_out
    );

-- Clock generation (100 MHz)
clk_proc : process
begin
    while true loop
        s_axis_clk <= '0';
        wait for 5 ns;
        s_axis_clk <= '1';
        wait for 5 ns;
    end loop;
end process;

-- Simulate simplified VTC frame pulses
vtc_gen : process
begin
    wait for 100 ns;
    while true loop
        -- Simulate a frame lasting 5 * 80 ns = 400 ns
        fsync <= "1";
        vsync <= '0';
        active_video_out <= '1';
        wait for 400 ns;
        
        fsync <= "0";
        vsync <= '1';  -- Simulate vertical sync pulse
        active_video_out <= '0';
        wait for 80 ns;
        
        vsync <= '0';
        wait for 120 ns;
    end loop;
end process;

-- Stimulus pattern
stim_proc : process
begin
    -- Apply reset
    s_axis_resetn <= '0';
    wait for 20 ns;
    s_axis_resetn <= '1';
    wait for 20 ns;

    wait until active_video_out = '1';

    -- First frame with one highlight pixel
    video_in <= x"000000"; wait for 80 ns;
    video_in <= x"000000"; wait for 80 ns;

    peak_bin <= std_logic_vector(to_unsigned(5, 9));
    video_in <= x"f63f0f"; wait for 80 ns;

    video_in <= x"000000"; wait for 80 ns;
    video_in <= x"000000"; wait for 80 ns;

    wait until active_video_out = '1';

    -- Second frame with multiple colored pixels
    video_in <= x"000000"; wait for 80 ns;

    peak_bin <= std_logic_vector(to_unsigned(200, 9));
    video_in <= x"f63f0f"; wait for 40 ns;
    peak_bin <= std_logic_vector(to_unsigned(250, 9));
    wait for 40 ns;

    video_in <= x"f63f0f"; wait for 40 ns;
    peak_bin <= std_logic_vector(to_unsigned(130, 9));
    wait for 40 ns;

    video_in <= x"f63f0f"; wait for 80 ns;

    video_in <= x"000000"; wait for 80 ns;

    wait;
end process;

end sim;
