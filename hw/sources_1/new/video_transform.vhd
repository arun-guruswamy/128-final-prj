

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity video_transform is
    generic (
        C_VIDEO_DATA_WIDTH : integer := 24;
        C_AUDIO_DATA_WIDTH : integer := 32;
        C_OUTPUT_DATA_WIDTH : integer := 32  -- for amplitude, size unsure rn
    );
    port (
        -- Video 
        Video_in  : in  std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);
        Video_out  : out  std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);

        -- AXI Stream Audio Input
        s_axis_audio_aclk       : in std_logic;
        s_axis_audio_aresetn    : in std_logic;
        s_axis_audio_tdata      : in std_logic_vector(C_AUDIO_DATA_WIDTH-1 downto 0);
        s_axis_audio_tstrb      : in std_logic_vector((C_AUDIO_DATA_WIDTH/8)-1 downto 0);
        s_axis_audio_tvalid     : in std_logic;
        s_axis_audio_tlast      : in std_logic;
        s_axis_audio_tready     : out std_logic;
        mute_en_not             : in std_logic;

        -- Amplitude
        m_axis_amp_tdata    : out std_logic_vector(C_OUTPUT_DATA_WIDTH-1 downto 0)
    );
end video_transform;

architecture Behavioral of video_transform is

-------------------- FFT Component --------------------
COMPONENT xfft_0
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tlast : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);
    m_axis_data_tuser : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tlast : OUT STD_LOGIC;
    event_frame_started : OUT STD_LOGIC;
    event_tlast_unexpected : OUT STD_LOGIC;
    event_tlast_missing : OUT STD_LOGIC;
    event_status_channel_halt : OUT STD_LOGIC;
    event_data_in_channel_halt : OUT STD_LOGIC;
    event_data_out_channel_halt : OUT STD_LOGIC
  );
END COMPONENT;
-------------------- FFT_AXI_RX Component --------------------
COMPONENT fft_axi_rx
    PORT (
    s_axis_clk          : IN STD_LOGIC;
    s_axis_resetn       : IN STD_LOGIC;
    s_axis_data_tdata   : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    s_axis_data_tuser   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_data_tvalid  : IN STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tlast   : IN STD_LOGIC;
    
    peak_freq_mag       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    peak_bin            : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
    );
end COMPONENT;
-------------------- RGB_TRANSFORM Component --------------------
COMPONENT rgb_transform 
    generic (
        C_VIDEO_DATA_WIDTH : integer := 24
    );
    port (
        s_axis_clk    : IN  STD_LOGIC;
        s_axis_resetn : IN  STD_LOGIC;
        mute_en_not   : IN  STD_LOGIC;
        peak_bin      : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        video_in      : IN  STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0);
        video_out     : OUT STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0)
    );
end COMPONENT;



-- FFT config
--type config_state_type is (IDLE, LOAD_CONFIG, SEND_CONFIG, DONE);
--signal config_state : config_state_type := IDLE;

--type T_CFG_SCALE_SCH is (ZERO, DEFAULT);
--signal cfg_scale_sch : T_CFG_SCALE_SCH := DEFAULT;
--signal scale_sch : std_logic_vector(9 downto 0) := (others => '0');
signal s_axis_config_tdata : std_logic_vector(15 DOWNTO 0) := (others => '0');
--signal s_axis_config_tvalid, s_axis_config_tready, config_done : std_logic := '0';
-- FFT input truncating
signal s_axis_data_tdata_int : std_logic_vector(47 DOWNTO 0) := (others => '0');
-- FFT AXI Output
signal m_axis_data_tdata : std_logic_vector(47 DOWNTO 0) := (others => '0');
signal m_axis_data_tuser : std_logic_vector(15 DOWNTO 0) := (others => '0');
signal m_axis_data_tvalid, m_axis_data_tready, m_axis_data_tlast : std_logic := '0';
-- FFT Status 
signal event_frame_started, event_tlast_unexpected, event_tlast_missing, event_status_channel_halt, event_data_in_channel_halt, event_data_out_channel_halt : std_logic := '0';


-- FFT_AXI_RX
signal peak_bin_int : std_logic_vector(8 DOWNTO 0) := (others => '0');

begin

-------------------- FFT Port Map --------------------
FFT_Comp : xfft_0
  PORT MAP (
    aclk => s_axis_audio_aclk,
    s_axis_config_tdata => s_axis_config_tdata,
    s_axis_config_tvalid => '0',
    s_axis_config_tready => open,
    s_axis_data_tdata => s_axis_data_tdata_int,
    s_axis_data_tvalid => s_axis_audio_tvalid,
    s_axis_data_tready => s_axis_audio_tready,
    s_axis_data_tlast => s_axis_audio_tlast,
    m_axis_data_tdata => m_axis_data_tdata,
    m_axis_data_tuser => m_axis_data_tuser,
    m_axis_data_tvalid => m_axis_data_tvalid,
    m_axis_data_tready => m_axis_data_tready,
    m_axis_data_tlast => m_axis_data_tlast,
    event_frame_started => event_frame_started,
    event_tlast_unexpected => event_tlast_unexpected,
    event_tlast_missing => event_tlast_missing,
    event_status_channel_halt => event_status_channel_halt,
    event_data_in_channel_halt => event_data_in_channel_halt,
    event_data_out_channel_halt => event_data_out_channel_halt);
-------------------- FFT_AXI_RX Port Map --------------------
FFT_AXI : fft_axi_rx
    PORT MAP (
    s_axis_clk => s_axis_audio_aclk,
    s_axis_resetn => s_axis_audio_aresetn,
    s_axis_data_tdata => m_axis_data_tdata,
    s_axis_data_tuser => m_axis_data_tuser,
    s_axis_data_tvalid => m_axis_data_tvalid,
    s_axis_data_tready => m_axis_data_tready,
    s_axis_data_tlast => m_axis_data_tlast,
    
    peak_freq_mag => open,
    peak_bin => peak_bin_int
    );

-------------------- RGB_TRANSFORM Port Map --------------------
RGB : rgb_transform 
    PORT MAP (
    s_axis_clk => s_axis_audio_aclk,
    s_axis_resetn => s_axis_audio_aresetn,
    mute_en_not => mute_en_not,
    peak_bin => peak_bin_int,
    video_in => Video_in,
    video_out => Video_out
    );


--FFT_config_process : process(s_axis_audio_aclk)
--begin
--    if rising_edge(s_axis_audio_aclk) then
--        if s_axis_audio_aresetn = '0' then
--            s_axis_config_tvalid <= '0';
--            s_axis_config_tdata  <= (others => '0');
--            config_done          <= '0';
--            config_state         <= IDLE;
--        else
--            case config_state is
--                when IDLE =>
--                    config_state <= LOAD_CONFIG;

--                when LOAD_CONFIG =>
--                    -- Build config word here
--                    s_axis_config_tdata  <= "0000001101010001"; -- forward FFT + scale schedule
--                    s_axis_config_tvalid <= '1';
--                    config_state         <= SEND_CONFIG;

--                when SEND_CONFIG =>
--                    if s_axis_config_tready = '1' then
--                        s_axis_config_tvalid <= '0';
--                        config_done          <= '1';
--                        config_state         <= DONE;
--                    end if;

--                when DONE =>
--                    -- Stay here
--                    null;
--            end case;
--        end if;
--    end if;
--end process;


s_axis_data_tdata_int(23 downto 0) <= s_axis_audio_tdata(31 downto 8);  -- Real
s_axis_data_tdata_int(47 downto 24) <= (others => '0');    -- Imag



-- For testing
m_axis_amp_tdata <= (others => '0');


end Behavioral;
