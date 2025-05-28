library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_rgb_transform is
end tb_rgb_transform;

architecture sim of tb_rgb_transform is

-- Constants
constant C_VIDEO_DATA_WIDTH : integer := 24;

-- DUT input signals
signal s_axis_clk    : std_logic := '0';
signal s_axis_resetn : std_logic := '0';
signal peak_bin      : std_logic_vector(8 downto 0) := (others => '0');
signal video_in      : std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0) := (others => '0');
signal active_video_out: std_logic := '0';
signal mute_en_not : std_logic := '1';

-- DUT output
signal video_out     : std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);

-- DUT component 
component rgb_transform
    generic (
        C_VIDEO_DATA_WIDTH : integer := 24
    );
    port (
        s_axis_clk    : IN  STD_LOGIC;
        s_axis_resetn : IN  STD_LOGIC;
        mute_en_not   : IN  STD_LOGIC;
        active_video_out : IN STD_LOGIC;  -- high only when active frame is drawing
        peak_bin      : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        video_in      : IN  STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0);
        video_out     : OUT STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0)
    );
end component;

begin

-- Instantiate the DUT
dut_rgb_transform : rgb_transform
    generic map (
        C_VIDEO_DATA_WIDTH => C_VIDEO_DATA_WIDTH
    )
    port map (
        s_axis_clk    => s_axis_clk,
        s_axis_resetn => s_axis_resetn,
        mute_en_not   => mute_en_not,
        active_video_out => active_video_out,
        peak_bin      => peak_bin,
        video_in      => video_in,
        video_out     => video_out
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


stim_proc : process
begin
    -- 1. Apply reset
    s_axis_resetn <= '0';
    wait for 20 ns;
    s_axis_resetn <= '1';
    wait for 20 ns;

    -- ==== First pattern: 2 black, 1 non-black, 2 black ====
    active_video_out <= '1';
    video_in <= x"000000";
    wait for 80 ns;

    video_in <= x"000000";
    wait for 80 ns;

    peak_bin <= std_logic_vector(to_unsigned(5, 9));
    video_in <= x"112233";
    wait for 80 ns;

    video_in <= x"000000";
    wait for 80 ns;

    video_in <= x"000000";
    wait for 80 ns;
    active_video_out <= '0';
    
    wait for 80 ns;

    -- ==== Second pattern: 1 black, 3 non-black, 1 black ====
    active_video_out <= '1';
    video_in <= x"000000";
    wait for 80 ns;

    peak_bin <= std_logic_vector(to_unsigned(200, 9));
    video_in <= x"445566";
    wait for 40 ns;
    peak_bin <= std_logic_vector(to_unsigned(250, 9));
    wait for 40 ns;

    video_in <= x"778899";
    wait for 40 ns;
    peak_bin <= std_logic_vector(to_unsigned(130, 9));
    wait for 40 ns;

    video_in <= x"99aabb";
    wait for 80 ns;

    video_in <= x"000000";
    wait for 80 ns;
    active_video_out <= '0';

    wait;
end process;






end sim;
