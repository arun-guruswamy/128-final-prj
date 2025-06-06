----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 05/23/2025 (Updated)
-- Design Name:
-- Module Name: video_gen_tb - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description: Testbench for video_gen module, using an instantiated VTC
--
-- Dependencies: video_gen.vhd, VTC IP core VHDL files
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity video_gen_tb is
-- No ports for a top-level testbench
end video_gen_tb;

architecture Behavioral of video_gen_tb is

    -- Component Declaration for the Device Under Test (DUT) - video_gen
    component video_gen
        Port (
            pxl_clk         : in  std_logic;
            hblank_i  : in std_logic;
            fsync_i : in STD_LOGIC_VECTOR(0 DOWNTO 0);
            active_video_i  : in  std_logic;
            amplitude : in std_logic_vector(2 downto 0);
            pxl_o           : out std_logic_vector(23 downto 0)
        );
    end component;

    -- =================================================================================
    -- IMPORTANT: Verify this VTC component declaration matches YOUR VTC IP instance!
    -- This is a common structure but port names/widths might vary.
    -- Replace with the one from your Vivado project's IP sources.
    -- =================================================================================
    component v_tc_0 -- Or whatever your VTC IP core is named
        port (
            -- Clocks & Reset
            clk             : in  std_logic; -- Should be PIXEL CLOCK for generator mode
            clken           : in  std_logic; -- Main clock enable (typically '1')
            resetn          : in  std_logic; -- Main reset (Active Low) for generator logic

            -- Generator Enable
            gen_clken       : in  std_logic; -- Generator clock enable (typically '1')
            
            sof_state : in std_logic;
            
            -- Timing Outputs from VTC
            hsync_out       : out std_logic;
            vsync_out       : out std_logic;
            hblank_out      : out std_logic;
            vblank_out      : out std_logic;
            active_video_out: out std_logic;
            fsync_out       : out std_logic_vector(0 downto 0)
            -- Add other VTC outputs if needed (e.g., field_id_out)
        );
    end component;

    -- Inputs for video_gen DUT
    signal tb_pxl_clk         : std_logic := '0';
    signal tb_active_video_i  : std_logic := '0'; -- This will come from the VTC instance
    signal tb_toggle          : std_logic := '1';

    -- Output from video_gen DUT
    signal tb_pxl_o           : std_logic_vector(23 downto 0);

    -- Signals for VTC instance
    signal tb_vtc_resetn      : std_logic := '0'; -- Active low reset for VTC
    signal tb_vtc_clken       : std_logic := '1';
    signal tb_vtc_gen_clken   : std_logic := '1';

    -- Monitored outputs from VTC (optional to add to waveform)
    signal tb_vtc_hsync         : std_logic;
    signal tb_vtc_vsync         : std_logic;
    signal tb_vtc_hblank        : std_logic;
    signal tb_vtc_vblank        : std_logic;
    signal tb_fsync             : std_logic_vector(0 downto 0);
    -- tb_active_video_i will effectively be tb_vtc_active_video

    -- Clock period definition
    constant PXL_CLK_PERIOD : time := 13.468 ns; -- Approx 74.25 MHz

    -- Video Timing Constants (for stimulus wait times, VTC should generate these)
    constant H_TOTAL        : integer := 1650;
    constant V_TOTAL        : integer := 750;

begin

    -- Instantiate the Video Timing Controller (VTC) IP Core
    VTC_INST : v_tc_0
        port map (
            clk             => tb_pxl_clk,
            clken           => tb_vtc_clken,
            resetn          => tb_vtc_resetn,
            
            gen_clken       => tb_vtc_gen_clken,
            
            sof_state => '0',

            hsync_out       => tb_vtc_hsync,
            vsync_out       => tb_vtc_vsync,
            hblank_out      => tb_vtc_hblank,
            vblank_out      => tb_vtc_vblank,
            active_video_out=> tb_active_video_i, -- << KEY: VTC output drives video_gen input
            fsync_out => tb_fsync
        );

    -- Instantiate the Device Under Test (DUT) - video_gen
    dut_video_gen : video_gen
        port map (
            pxl_clk        => tb_pxl_clk,
            hblank_i  => tb_vtc_hblank,
            fsync_i => tb_fsync,
            active_video_i => tb_active_video_i, -- Driven by VTC_INST
            amplitude => "000",

            pxl_o          => tb_pxl_o
        );

    -- Clock process definition
    pxl_clk_process : process
    begin
        tb_pxl_clk <= '0';
        wait for PXL_CLK_PERIOD/2;
        tb_pxl_clk <= '1';
        wait for PXL_CLK_PERIOD/2;
    end process;

    -- Stimulus Process (includes reset for VTC)
    stimulus_process : process
    begin
        -- Apply Reset to VTC
        tb_vtc_resetn <= '0';
        wait for PXL_CLK_PERIOD * 20; -- Hold reset

        tb_vtc_resetn <= '1';
        -- Reset is removed so wait for pattern to display as expected
        wait for V_TOTAL * H_TOTAL * PXL_CLK_PERIOD * 2; -- Wait for 2 full frames

        wait; -- End simulation
    end process;

end Behavioral;