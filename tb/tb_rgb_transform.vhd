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

-- DUT output
signal video_out     : std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);

-- DUT component 
component rgb_transform
    generic (
        C_VIDEO_DATA_WIDTH : integer := 24
    );
    port (
        s_axis_clk    : in  std_logic;
        s_axis_resetn : in  std_logic;
        peak_bin      : in  std_logic_vector(8 downto 0);
        video_in      : in  std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);
        video_out     : out std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0)
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

    -- ==== Second pattern: 1 black, 3 non-black, 1 black ====
    video_in <= x"000000";
    wait for 80 ns;

    peak_bin <= std_logic_vector(to_unsigned(200, 9));
    video_in <= x"445566";
    wait for 80 ns;

    video_in <= x"778899";
    wait for 80 ns;

    video_in <= x"99aabb";
    wait for 80 ns;

    video_in <= x"000000";
    wait for 80 ns;

    wait;
end process;






end sim;
