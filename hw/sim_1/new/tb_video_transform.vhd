library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity tb_video_transform is
end tb_video_transform;

architecture Behavioral of tb_video_transform is

-- Constants
constant C_VIDEO_DATA_WIDTH  : integer := 24;
constant C_AUDIO_DATA_WIDTH  : integer := 32;
constant C_OUTPUT_DATA_WIDTH : integer := 32;

-- Signals
signal Video_in        : std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0) := (others => '0');
signal Video_out       : std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);
signal s_axis_audio_aclk    : std_logic := '0';
signal s_axis_audio_aresetn : std_logic := '0';
signal s_axis_audio_tdata   : std_logic_vector(C_AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');
signal s_axis_audio_tstrb   : std_logic_vector((C_AUDIO_DATA_WIDTH/8)-1 downto 0) := (others => '0');
signal s_axis_audio_tvalid  : std_logic := '0';
signal s_axis_audio_tlast   : std_logic := '0';
signal s_axis_audio_tready  : std_logic;
signal m_axis_amp_tdata     : std_logic_vector(C_OUTPUT_DATA_WIDTH-1 downto 0);
signal mute_en_not          : std_logic := '1';

-- Component declaration
component video_transform
    generic (
        C_VIDEO_DATA_WIDTH  : integer := 24;
        C_AUDIO_DATA_WIDTH  : integer := 32;
        C_OUTPUT_DATA_WIDTH : integer := 32
    );
    port (
        Video_in             : in  std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);
        Video_out            : out std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);
        mute_en_not          : in std_logic;
        s_axis_audio_aclk    : in  std_logic;
        s_axis_audio_aresetn : in  std_logic;
        s_axis_audio_tdata   : in  std_logic_vector(C_AUDIO_DATA_WIDTH-1 downto 0);
        s_axis_audio_tstrb   : in std_logic_vector((C_AUDIO_DATA_WIDTH/8)-1 downto 0);
        s_axis_audio_tvalid  : in  std_logic;
        s_axis_audio_tlast   : in  std_logic;
        s_axis_audio_tready  : out std_logic;
        m_axis_amp_tdata     : out std_logic_vector(C_OUTPUT_DATA_WIDTH-1 downto 0)
    );
end component;

begin

uut: video_transform
    generic map (
        C_VIDEO_DATA_WIDTH  => C_VIDEO_DATA_WIDTH,
        C_AUDIO_DATA_WIDTH  => C_AUDIO_DATA_WIDTH,
        C_OUTPUT_DATA_WIDTH => C_OUTPUT_DATA_WIDTH
    )
    port map (
        Video_in             => Video_in,
        Video_out            => Video_out,
        mute_en_not          => mute_en_not,
        s_axis_audio_aclk    => s_axis_audio_aclk,
        s_axis_audio_aresetn => s_axis_audio_aresetn,
        s_axis_audio_tdata   => s_axis_audio_tdata,
        s_axis_audio_tstrb   => s_axis_audio_tstrb,
        s_axis_audio_tvalid  => s_axis_audio_tvalid,
        s_axis_audio_tlast   => s_axis_audio_tlast,
        s_axis_audio_tready  => s_axis_audio_tready,
        m_axis_amp_tdata     => m_axis_amp_tdata
    );
    
clk_proc : process
begin
    while true loop
        s_axis_audio_aclk <= '0';
        wait for 5 ns;
        s_axis_audio_aclk <= '1';
        wait for 5 ns;
    end loop;
end process;

reset_driver : process
begin
  s_axis_audio_aresetn <= '0';
  wait for 100 ns;
  s_axis_audio_aresetn <= '1';
  wait;
end process;

stim_proc_video : process
  constant BLACK    : std_logic_vector(23 downto 0) := x"000000";
  constant NONBLACK : std_logic_vector(23 downto 0) := x"112233";
begin
  wait for 200 ns;  -- Let reset and audio settle

  while true loop
    --Video_in <= BLACK;
    --wait for 80 ns;

    Video_in <= NONBLACK;
    wait for 80 ns;
  end loop;
end process;


stim_proc_audio : process
  variable real_val  : real;
  variable int_val   : integer;
  variable real_part : std_logic_vector(23 downto 0);
  constant imag_part : std_logic_vector(23 downto 0) := (others => '0');
begin
  -- Wait for reset to deassert
  wait until rising_edge(s_axis_audio_aclk) and s_axis_audio_aresetn = '1';
  wait for 20 ns;

  -- ========== Bin 1 ==========
  s_axis_audio_tvalid <= '1';
  for i in 0 to 511 loop
    real_val := cos(2.0 * MATH_PI * real(i) * 1.0 / 512.0);
    int_val  := integer(round(real_val * 2.0**13));
    real_part := std_logic_vector(to_signed(int_val, 24));
    s_axis_audio_tdata <= real_part & x"00";

    if i = 511 then
      s_axis_audio_tlast <= '1';
    else
      s_axis_audio_tlast <= '0';
    end if;

    wait until rising_edge(s_axis_audio_aclk) and s_axis_audio_tready = '1';
  end loop;
  s_axis_audio_tvalid <= '0';
  s_axis_audio_tlast  <= '0';

  wait for 500 ns;

  -- ========== Bin 80 ==========
  s_axis_audio_tvalid <= '1';
  for i in 0 to 511 loop
    real_val := cos(2.0 * MATH_PI * real(i) * 80.0 / 512.0);
    int_val  := integer(round(real_val * 2.0**13));
    real_part := std_logic_vector(to_signed(int_val, 24));
    s_axis_audio_tdata <= real_part & x"00";

    if i = 511 then
      s_axis_audio_tlast <= '1';
    else
      s_axis_audio_tlast <= '0';
    end if;

    wait until rising_edge(s_axis_audio_aclk) and s_axis_audio_tready = '1';
  end loop;
  s_axis_audio_tvalid <= '0';
  s_axis_audio_tlast  <= '0';

  wait for 500 ns;

  -- ========== Bin 160 ==========
  s_axis_audio_tvalid <= '1';
  for i in 0 to 511 loop
    real_val := cos(2.0 * MATH_PI * real(i) * 160.0 / 512.0);
    int_val  := integer(round(real_val * 2.0**13));
    real_part := std_logic_vector(to_signed(int_val, 24));
    s_axis_audio_tdata <= real_part & x"00";

    if i = 511 then
      s_axis_audio_tlast <= '1';
    else
      s_axis_audio_tlast <= '0';
    end if;

    wait until rising_edge(s_axis_audio_aclk) and s_axis_audio_tready = '1';
  end loop;
  s_axis_audio_tvalid <= '0';
  s_axis_audio_tlast  <= '0';

  wait;
end process;






end Behavioral;