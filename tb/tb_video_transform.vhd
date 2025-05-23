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
signal s_axis_audio_tstrb   : std_logic_vector((C_AUDIO_DATA_WIDTH/8)-1 downto 0);
signal s_axis_audio_tvalid  : std_logic := '0';
signal s_axis_audio_tlast   : std_logic := '0';
signal s_axis_audio_tready  : std_logic;
signal m_axis_amp_tdata     : std_logic_vector(C_OUTPUT_DATA_WIDTH-1 downto 0);

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
        s_axis_audio_aclk    : in  std_logic;
        s_axis_audio_aresetn : in  std_logic;
        s_axis_audio_tdata   : in  std_logic_vector(C_AUDIO_DATA_WIDTH-1 downto 0);
        s_axis_audio_tstrb   : out std_logic_vector((C_AUDIO_DATA_WIDTH/8)-1 downto 0);
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

stim_proc_video : process
begin
    -- Hold reset
    s_axis_audio_aresetn <= '0';
    wait for 50 ns;
    s_axis_audio_aresetn <= '1';
    wait for 50 ns;
    
    -- Frame 1: black
    Video_in <= x"000000";
    wait for 80 ns;
    
    -- Frame 2: black
    Video_in <= x"000000";
    wait for 80 ns;
    
    -- Frame 3: non-black (should trigger color change)
    Video_in <= x"112233";
    wait for 80 ns;
    
    -- Frame 4: black
    Video_in <= x"000000";
    wait for 80 ns;
    
    -- Frame 5: black
    Video_in <= x"000000";
    wait for 80 ns;
    
    -- Frame 6: black
    Video_in <= x"000000";
    wait for 80 ns;
    
    -- Frame 7: non-black
    Video_in <= x"334455";
    wait for 80 ns;
    
    -- Frame 8: non-black
    Video_in <= x"556677";
    wait for 80 ns;
    
    -- Frame 9: non-black
    Video_in <= x"778899";
    wait for 80 ns;
    
    -- Frame 10: black
    Video_in <= x"000000";
    wait;
end process;

stim_proc_audio : process
    constant FRAME_SIZE : integer := 16;
    constant AMP1 : integer := 2**22;  -- Full magnitude
    constant AMP2 : integer := 2**21;  -- Half magnitude
    variable val_real : integer;
    variable theta : real;
begin
    -- Wait for FFT config to complete (worst case: 3-4 cycles + handshake time)
    wait for 100 ns;
    
    for i in 0 to FRAME_SIZE - 1 loop
    theta := 2.0 * MATH_PI * real(i) / real(FRAME_SIZE);
    
    if i < FRAME_SIZE / 2 then
      val_real := integer(AMP1 * cos(theta));
    else
      val_real := integer(AMP2 * cos(theta));
    end if;
    
    -- Real = lower 24 bits, Imag = upper 24 bits (0)
    s_axis_audio_tdata <= std_logic_vector(to_signed(val_real, 24)) & (7 downto 0 => '0');
    s_axis_audio_tvalid <= '1';
    
    if i = FRAME_SIZE - 1 then
      s_axis_audio_tlast <= '1';
    else
      s_axis_audio_tlast <= '0';
    end if;
    
    wait until rising_edge(s_axis_audio_aclk) and s_axis_audio_tready = '1';
    s_axis_audio_tvalid <= '0';
    
    wait until rising_edge(s_axis_audio_aclk);
    end loop;
    
    wait;
end process;


end Behavioral;