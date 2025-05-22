----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: I2S receiver for SSM2603 audio codec
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		adc_serial_data_i     : in std_logic);  
end i2s_receiver;
----------------------------------------------------------------------------
architecture Behavioral of i2s_receiver is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
type state_type is (Wait1, Shift2, Wait2, Shift1);	-- Setup states 
signal current_state, next_state : state_type := Wait1;	-- Setup signals as state types

signal lr_load, load_en, shift_en       : std_logic := '0'; -- FSM --> DP
signal shift_done                       : std_logic := '0'; -- DP --> FSM 

signal b_counter                        : integer := 0; -- Datapath register
signal data_int, left_data, right_data  : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Update the current state (Synchronous):
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
StateUpdate: process(bclk_i)
begin
    if rising_edge(bclk_i) then
        current_state <= next_state;
    end if;
end process StateUpdate;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Next State Logic (Asynchronous):
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NextStateLogic: process(current_state, lrclk_i, shift_done)
begin
    lr_load     <= '0';
    load_en     <= '0';
    shift_en    <= '0';
    next_state  <= current_state;
        
    case current_state is
        when Wait1  =>
            if lrclk_i = '1' then
                next_state <= Shift2;
            end if;
            load_en <= '1';
            lr_load <= '1';
        when Shift2 => 
            if shift_done = '1' then
                next_state <= Wait2;
            end if;
            shift_en <= '1';
        when Wait2  =>
            if lrclk_i = '0' then
                next_state <= Shift1;
            end if;
            load_en <= '1';
            lr_load <= '0';
        when Shift1 =>
            if shift_done = '1' then
                next_state <= Wait1;
            end if;
            shift_en <= '1';
       when others => next_state <= Wait1;                
    end case;
end process NextStateLogic;


Datapath: process(bclk_i, lr_load, load_en, shift_en)
begin
    if rising_edge(bclk_i) then
        -- Shift
        if shift_en = '1' then
            if (integer(b_counter) >= 24) or (shift_done = '1') then
                b_counter <= 0;
                shift_done <= '1';
            else
                b_counter <= b_counter + 1;
                -- Shifting here
                data_int <= data_int(AC_DATA_WIDTH-2 downto 0) & adc_serial_data_i;
            end if;
            
        -- Load 
        elsif load_en = '1' then
            shift_done <= '0';
            if lr_load = '1' then -- Make sure its left or right
                left_data <= data_int;
            else
                right_data <= data_int;
            end if;
        end if;
    end if;
end process Datapath;

right_audio_data_o <= right_data;
left_audio_data_o <= left_data;

---------------------------------------------------------------------------- 
end Behavioral;