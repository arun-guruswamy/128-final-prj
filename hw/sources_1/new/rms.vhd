----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 05/29/2025
-- Design Name:   Peak Squared Amplitude Detector
-- Module Name:   rms - Behavioral (Note: Entity name kept as rms per user's code)
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:   Finds the peak of the squared audio input samples
--                within a fixed window of 1024 samples.
--                The output is a scaled 3-bit representation of this peak.
--
-- Dependencies:  IEEE.STD_LOGIC_1164.ALL, IEEE.NUMERIC_STD.ALL
--
-- Revision:
-- Revision 0.01 - Original RMS code.
-- Revision 0.02 - Modified for peak absolute amplitude detection (HSync window).
-- Revision 0.03 - Modified to detect peak of s_audio_squared (HSync window).
-- Revision 0.04 - Modified for peak of s_audio_squared over a fixed 1024-sample window.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rms is
  Port (
    clk        : in  std_logic;
    audio_in   : in  std_logic_vector(23 downto 0);
    amplitude  : out std_logic_vector(2 downto 0)  -- 3-bit scaled peak amplitude
  );
end rms;

architecture Behavioral of rms is

  -- Configuration for fixed window
  constant WINDOW_SIZE_BITS   : integer := 16; -- Window size as 2^N (N=10 -> 1024 samples)
  constant WINDOW_SIZE        : integer := 2**WINDOW_SIZE_BITS;

  -- Data widths
  constant INPUT_WIDTH        : integer := 24;
  constant SQUARED_WIDTH      : integer := 48; -- 24 * 2 = 48 bits
  constant SCALED_AMP_WIDTH   : integer := 3;  -- Desired width for the output amplitude

  -- Scaling Configuration
  -- Approx. MSB position of power for a full-scale sine wave (A^2/2) is (2*(INPUT_WIDTH-1)-1) = 45
  -- Or for a full-scale square wave (A^2), it's 2*(INPUT_WIDTH-1) = 46.
  -- Let's use 46 as the max possible bit position for s_audio_squared.
  constant SQUARED_PEAK_MSB_POS : integer := 2 * (INPUT_WIDTH - 1) ; -- Max bit pos for (2^23-1)^2 is bit 46
  constant SHIFT_FOR_SCALING    : integer := SQUARED_PEAK_MSB_POS - (SCALED_AMP_WIDTH - 1);
                                          -- For 3-bit output: 46 - (3-1) = 46 - 2 = 44

  -- Internal Signals
  signal s_audio_signed         : signed(INPUT_WIDTH - 1 downto 0);
  signal s_audio_squared        : unsigned(SQUARED_WIDTH - 1 downto 0);
  signal s_sample_counter       : integer range 0 to WINDOW_SIZE - 1 := 0;
  signal s_current_peak_squared : unsigned(SQUARED_WIDTH - 1 downto 0) := (others => '0'); -- Peak squared value in current window
  signal s_peak_sq_for_output   : unsigned(SQUARED_WIDTH - 1 downto 0) := (others => '0'); -- Registered peak squared from last window
  -- signal s_hsync_prev           : std_logic := '1'; -- Removed

begin

  -- Convert input audio to signed type
  s_audio_signed <= signed(audio_in);

  -- Square the audio sample
  s_audio_squared <= unsigned(s_audio_signed * s_audio_signed);

  -- Peak detection and output update process
  process(clk)
  begin
    if rising_edge(clk) then
      if s_sample_counter = 0 then
        -- Start of a new window
        s_current_peak_squared <= s_audio_squared; -- Initialize peak with the first sample of the window
      else
        -- Continue in the window, update peak if current squared sample is larger
        if s_audio_squared > s_current_peak_squared then
          s_current_peak_squared <= s_audio_squared;
        end if;
      end if;

      if s_sample_counter = WINDOW_SIZE - 1 then
        -- Window just ended
        -- Update the output holding register with the captured peak squared value
        s_peak_sq_for_output <= s_current_peak_squared;
        s_sample_counter <= 0; -- Reset counter for the next window
        -- s_current_peak_squared will be re-initialized on the next cycle when counter is 0
      else
        s_sample_counter <= s_sample_counter + 1;
      end if;
    end if;
  end process;

  -- Scale the registered peak squared value and assign to the output port
  -- This is a continuous assignment based on the latest captured peak.
  amplitude <= std_logic_vector(resize(s_peak_sq_for_output srl SHIFT_FOR_SCALING, SCALED_AMP_WIDTH));

end Behavioral;
