----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 05/27/2025 12:11:00 PM
-- Design Name:   Mean Square Amplitude Calculator
-- Module Name:   mean_square_amp - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:   Calculates the Mean Square value of an audio input stream.
--                This provides a measure proportional to the signal power
--                without the complexity of a square root calculation.
--                The output is the average of the squared input samples
--                over a defined window.
--
-- Dependencies:  IEEE.STD_LOGIC_1164.ALL, IEEE.NUMERIC_STD.ALL
--
-- Revision:
-- Revision 0.01 - File Created (Based on RMS, Sqrt removed)
-- Additional Comments:
--                Output is 48 bits wide, representing the squared amplitude.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rms is
  Port (
    clk : in std_logic;
    audio_in : in std_logic_vector(23 downto 0);
    amplitude : out std_logic_vector(47 downto 0) 
  );
end rms;

architecture Behavioral of rms is

  -- Configuration
  constant WINDOW_SIZE_BITS : integer := 10; -- Window size as 2^N (N=10 -> 1024 samples)
  constant WINDOW_SIZE : integer := 2**WINDOW_SIZE_BITS;

  -- Data widths
  constant INPUT_WIDTH : integer := 24;
  constant SQUARED_WIDTH : integer := 48; -- 24 * 2 = 48 bits
  constant ACCUM_WIDTH : integer := SQUARED_WIDTH + WINDOW_SIZE_BITS; -- 48 + 10 = 58 bits

  -- Internal Signals
  signal s_audio_signed : signed(INPUT_WIDTH - 1 downto 0);
  signal s_audio_squared : unsigned(SQUARED_WIDTH - 1 downto 0);
  signal s_accumulator : unsigned(ACCUM_WIDTH - 1 downto 0) := (others => '0');
  signal s_sample_counter : integer range 0 to WINDOW_SIZE - 1 := 0;
  signal s_mean_square_out : unsigned(SQUARED_WIDTH - 1 downto 0) := (others => '0');

begin

  -- Convert input audio to signed type
  s_audio_signed <= signed(audio_in);

  -- Square the audio sample 
  s_audio_squared <= unsigned(s_audio_signed * s_audio_signed);

 process(clk)
  begin
    if rising_edge(clk) then
      if s_sample_counter = WINDOW_SIZE - 1 then -- Window is full - Calculate mean by shifting right (division by WINDOW_SIZE)
        s_mean_square_out <= (s_accumulator + s_audio_squared) srl WINDOW_SIZE_BITS;

        -- Reset accumulator and counter for the next window
        s_accumulator <= (others => '0');
        s_sample_counter <= 0;
      else
        -- Window not full: Add current squared sample to accumulator
        s_accumulator <= s_accumulator + s_audio_squared;
        s_sample_counter <= s_sample_counter + 1;
      end if;
    end if;
  end process;

  amplitude <= std_logic_vector(s_mean_square_out);

end Behavioral;