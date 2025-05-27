library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity scrap is
end scrap;

architecture sim of scrap is

  constant CLK_PERIOD : time := 10 ns;
  constant FRAME_SIZE : integer := 512;

  signal clk : std_logic := '0';

  -- AXI Stream Data In
  signal s_axis_data_tvalid : std_logic := '0';
  signal s_axis_data_tready : std_logic;
  signal s_axis_data_tdata  : std_logic_vector(47 downto 0) := (others => '0');
  signal s_axis_data_tlast  : std_logic := '0';

  -- AXI Stream Data Out
  signal m_axis_data_tvalid : std_logic;
  signal m_axis_data_tready : std_logic := '1';
  signal m_axis_data_tdata  : std_logic_vector(47 downto 0);
  signal m_axis_data_tlast  : std_logic;

  -- Required dummy config signals
  signal s_axis_config_tready : std_logic;

begin

  -- Clock generation
  clk_process : process
  begin
    while true loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  -- Instantiate the FFT
  fft_inst : entity work.xfft_0
    port map (
      aclk                     => clk,
      s_axis_config_tvalid     => '0',
      s_axis_config_tready     => s_axis_config_tready,
      s_axis_config_tdata      => (others => '0'),
      s_axis_data_tvalid       => s_axis_data_tvalid,
      s_axis_data_tready       => s_axis_data_tready,
      s_axis_data_tdata        => s_axis_data_tdata,
      s_axis_data_tlast        => s_axis_data_tlast,
      m_axis_data_tvalid       => m_axis_data_tvalid,
      m_axis_data_tready       => m_axis_data_tready,
      m_axis_data_tdata        => m_axis_data_tdata,
      m_axis_data_tlast        => m_axis_data_tlast,
      event_frame_started      => open,
      event_tlast_unexpected   => open,
      event_tlast_missing      => open,
      event_status_channel_halt => open,
      event_data_in_channel_halt => open,
      event_data_out_channel_halt => open,
      m_axis_data_tuser        => open
    );

  -- Feed 512-sample cosine wave
  stimulus_proc : process
    variable real_val : real;
    variable int_val  : integer;
    variable real_part : std_logic_vector(23 downto 0);
    constant imag_part : std_logic_vector(23 downto 0) := (others => '0');
  begin
    wait for 5 * CLK_PERIOD;

    for i in 0 to FRAME_SIZE - 1 loop
      real_val := cos(2.0 * MATH_PI * real(i) / real(FRAME_SIZE));
      int_val  := integer(round(real_val * 2.0**13));

      real_part := std_logic_vector(to_signed(int_val, 24));
      s_axis_data_tdata <= real_part & imag_part;

      s_axis_data_tvalid <= '1';
      if i = FRAME_SIZE - 1 then
        s_axis_data_tlast <= '1';
      else
        s_axis_data_tlast <= '0';
      end if;

      wait until rising_edge(clk) and s_axis_data_tready = '1';
    end loop;

    s_axis_data_tvalid <= '0';
    s_axis_data_tlast  <= '0';
    wait;
  end process;

end sim;
