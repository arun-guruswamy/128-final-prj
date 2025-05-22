

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity video_transform is
    generic (
        C_VIDEO_DATA_WIDTH : integer := 24;
        C_AUDIO_DATA_WIDTH : integer := 32;
        C_OUTPUT_DATA_WIDTH : integer := 32  -- for amplitude, size unsure rn
    );
    port (
        -- Clock and Reset
        aclk              : in  std_logic;
        aresetn           : in  std_logic;

        -- Video Input
        Video_in  : in  std_logic_vector(C_VIDEO_DATA_WIDTH-1 downto 0);

        -- AXI-Stream Audio Input
        s_axis_audio_aclk       : in std_logic;
        s_axis_audio_aresetn    : in std_logic;
        s_axis_audio_tdata      : in  std_logic_vector(C_AUDIO_DATA_WIDTH-1 downto 0);
        s_axis_audio_tstrb      : out std_logic_vector((C_AUDIO_DATA_WIDTH/8)-1 downto 0);
        s_axis_audio_tvalid     : in  std_logic;
        s_axis_audio_tlast      : in std_logic;
        s_axis_audio_tready     : out std_logic;

        -- AXI-Stream Amplitude Output (e.g., RMS or FFT-derived control)
        m_axis_amp_tdata    : out std_logic_vector(C_OUTPUT_DATA_WIDTH-1 downto 0));

end video_transform;

architecture Behavioral of video_transform is

-------------------- FFT Component --------------------
COMPONENT xfft_0
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tlast : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
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


-- FFT config
type T_CFG_SCALE_SCH is (ZERO, DEFAULT);
signal cfg_scale_sch : T_CFG_SCALE_SCH := DEFAULT;
signal scale_sch : std_logic_vector(9 downto 0) := (others => '0');
signal s_axis_config_tdata : std_logic_vector(15 DOWNTO 0) := (others => '0');
signal s_axis_config_tvalid, s_axis_config_tready, config_done : std_logic := '0';
-- FFT AXI Output
signal m_axis_data_tdata : std_logic_vector(31 DOWNTO 0);
signal m_axis_data_tuser : std_logic_vector(15 DOWNTO 0);
signal m_axis_data_tvalid, m_axis_data_tready, m_axis_data_tlast : std_logic := '0';
-- FFT Status 
signal event_frame_started, event_tlast_unexpected, event_tlast_missing, event_status_channel_halt, event_data_in_channel_halt, event_data_out_channel_halt : std_logic := '0';



begin

-------------------- FFT Port Map --------------------
FFT_Comp : xfft_0
  PORT MAP (
    aclk => aclk,
    s_axis_config_tdata => s_axis_config_tdata,
    s_axis_config_tvalid => s_axis_config_tvalid,
    s_axis_config_tready => s_axis_config_tready,
    s_axis_data_tdata => s_axis_audio_tdata,
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
    
   

FFT_config_process : process(aclk)
begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            s_axis_config_tvalid <= '0';
            config_done <= '0';
        elsif config_done = '0' then
            if cfg_scale_sch = ZERO then
                scale_sch <= (others => '0');
            elsif cfg_scale_sch = DEFAULT then
                scale_sch(1 downto 0) <= "11";  
                scale_sch(3 downto 2) <= "10";  
                scale_sch(5 downto 4) <= "10";  
                scale_sch(7 downto 6) <= "10";  
                scale_sch(9 downto 8) <= "01";  
            end if;

            -- Build config word
            s_axis_config_tdata(0) <= '1'; -- FFT forward
            s_axis_config_tdata(10 downto 1) <= scale_sch;

            -- Begin config transaction
            s_axis_config_tvalid <= '1';
            if s_axis_config_tready = '1' then
                s_axis_config_tvalid <= '0'; -- drop valid once accepted
                config_done <= '1';
            end if;
        end if;
    end if;
end process;


end Behavioral;
