library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_video_transform_fft is
end tb_video_transform_fft;

architecture behavior of tb_video_transform_fft is

  -- Clock period
  constant CLOCK_PERIOD : time := 10 ns;
  constant T_HOLD       : time := 2 ns;

  -- Signals
  signal aclk              : std_logic := '0';
  signal s_axis_config_tvalid : std_logic := '0';
  signal s_axis_config_tready : std_logic;
  signal s_axis_config_tdata  : std_logic_vector(15 downto 0) := (others => '0');

  signal s_axis_data_tvalid  : std_logic := '0';
  signal s_axis_data_tready  : std_logic;
  signal s_axis_data_tdata   : std_logic_vector(31 downto 0);
  signal s_axis_data_tlast   : std_logic := '0';

  signal m_axis_data_tvalid  : std_logic;
  signal m_axis_data_tready  : std_logic := '1';
  signal m_axis_data_tdata   : std_logic_vector(31 downto 0);
  signal m_axis_data_tuser   : std_logic_vector(15 downto 0);
  signal m_axis_data_tlast   : std_logic;

  -- FFT status (ignored here)
  signal event_frame_started, event_tlast_unexpected, event_tlast_missing : std_logic;
  signal event_status_channel_halt, event_data_in_channel_halt, event_data_out_channel_halt : std_logic;

begin

  -- Clock process
  clk_proc : process
  begin
    aclk <= '0';
    wait for CLOCK_PERIOD/2;
    loop
      aclk <= not aclk;
      wait for CLOCK_PERIOD/2;
    end loop;
  end process;

  -- Instantiate FFT DUT
  fft_inst : entity work.xfft_0
    port map (
      aclk => aclk,
      s_axis_config_tvalid => s_axis_config_tvalid,
      s_axis_config_tready => s_axis_config_tready,
      s_axis_config_tdata  => s_axis_config_tdata,
      s_axis_data_tvalid => s_axis_data_tvalid,
      s_axis_data_tready => s_axis_data_tready,
      s_axis_data_tdata  => s_axis_data_tdata,
      s_axis_data_tlast  => s_axis_data_tlast,
      m_axis_data_tvalid => m_axis_data_tvalid,
      m_axis_data_tready => m_axis_data_tready,
      m_axis_data_tdata  => m_axis_data_tdata,
      m_axis_data_tuser  => m_axis_data_tuser,
      m_axis_data_tlast  => m_axis_data_tlast,
      event_frame_started => event_frame_started,
      event_tlast_unexpected => event_tlast_unexpected,
      event_tlast_missing => event_tlast_missing,
      event_status_channel_halt => event_status_channel_halt,
      event_data_in_channel_halt => event_data_in_channel_halt,
      event_data_out_channel_halt => event_data_out_channel_halt
    );

  -- Configure FFT once after reset
  config_proc : process
  begin
    wait until rising_edge(aclk);
    wait for T_HOLD;

    -- Default scaling schedule (binary "11 10 10 10 01") and forward transform
    s_axis_config_tdata <= "0000001101010001";  -- [10:1]=scale, [0]=forward
    s_axis_config_tvalid <= '1';

    wait until rising_edge(aclk) and s_axis_config_tready = '1';
    wait for T_HOLD;
    s_axis_config_tvalid <= '0';
  end process;

  -- Provide a basic sinusoid as input (single frame)
  stimulus_proc : process
    variable real_val : real;
    variable int_val  : integer;
    variable i        : integer;
    constant FRAME_SIZE : integer := 16;
  begin
    wait until rising_edge(aclk);
    wait for 10 * CLOCK_PERIOD;

    for i in 0 to FRAME_SIZE-1 loop
      -- Generate cosine wave, no imaginary part
      real_val := cos(2.0 * MATH_PI * real(i) / real(FRAME_SIZE));
      int_val := integer(round(real_val * 2.0**13));  -- 14-bit fixed point

      s_axis_data_tdata(15 downto 0) <= std_logic_vector(to_signed(int_val, 16)); -- Real
      s_axis_data_tdata(31 downto 16) <= (others => '0');                        -- Imag
      if i = FRAME_SIZE - 1 then
        s_axis_data_tlast <= '1';
      else
        s_axis_data_tlast <= '0';
      end if;
      s_axis_data_tvalid <= '1';

      wait until rising_edge(aclk) and s_axis_data_tready = '1';
      wait for T_HOLD;
      s_axis_data_tvalid <= '0';
      wait until rising_edge(aclk);
    end loop;

    wait until m_axis_data_tlast = '1';
    wait for CLOCK_PERIOD * 10;
    report "FFT test complete." severity failure;
  end process;
  
  

end behavior;
