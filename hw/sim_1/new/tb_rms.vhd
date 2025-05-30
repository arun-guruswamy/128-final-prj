library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all; -- For to_hstring

entity tb_rms is
end entity;

architecture sim of tb_rms is

    component audio_passthrough is
        generic (
            C_AXI_STREAM_DATA_WIDTH : integer := 32;
            C_S00_AXI_DATA_WIDTH    : integer := 32;
            C_S00_AXI_ADDR_WIDTH    : integer := 4
        );
        Port (
            -- Master clock
            mclk_i : in std_logic;

            -- User controls
            mux_select   : in STD_LOGIC; -- Task 2
            ac_mute_en_i : in STD_LOGIC; -- Task 1

            -- Audio Codec I2S controls
            ac_bclk_o      : out STD_LOGIC;
            ac_mclk_o      : out STD_LOGIC;
            ac_mute_n_o    : out STD_LOGIC; -- Active Low

            -- Audio Codec DAC (audio out)
            ac_dac_data_o  : out STD_LOGIC;
            ac_dac_lrclk_o : out STD_LOGIC;

            -- Audio Codec ADC (audio in)
            ac_adc_data_i  : in STD_LOGIC;
            ac_adc_lrclk_o : out STD_LOGIC;

            amplitude_o : out std_logic_vector(2 downto 0);

            -- Axi Responder/Slave Bus Interface S00_AXI
            dds_enable_i    : in std_logic;
            dds_reset_i     : in std_logic;
            s00_axi_aclk    : in std_logic;
            s00_axi_aresetn : in std_logic;
            s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
            s00_axi_awprot  : in std_logic_vector(2 downto 0);
            s00_axi_awvalid : in std_logic;
            s00_axi_awready : out std_logic;
            s00_axi_wdata   : in std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
            s00_axi_wstrb   : in std_logic_vector((C_S00_AXI_DATA_WIDTH / 8) - 1 downto 0);
            s00_axi_wvalid  : in std_logic;
            s00_axi_wready  : out std_logic;
            s00_axi_bresp   : out std_logic_vector(1 downto 0);
            s00_axi_bvalid  : out std_logic;
            s00_axi_bready  : in std_logic;
            s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
            s00_axi_arprot  : in std_logic_vector(2 downto 0);
            s00_axi_arvalid : in std_logic;
            s00_axi_arready : out std_logic;
            s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
            s00_axi_rresp   : out std_logic_vector(1 downto 0);
            s00_axi_rvalid  : out std_logic;
            s00_axi_rready  : in std_logic;

            -- AXI Stream Interface (Tranmitter/Controller)
            m00_axis_aclk    : in std_logic;
            m00_axis_aresetn : in std_logic;
            m00_axis_tvalid  : out std_logic;
            m00_axis_tdata   : out std_logic_vector(C_AXI_STREAM_DATA_WIDTH - 1 downto 0);
            m00_axis_tlast   : out std_logic;
            m00_axis_tready  : in std_logic
        );

    end component;


    -- Define constants
    constant CLOCK_PERIOD    : time   := 8 ns;      -- define clock period, 8ns = 125 MHz
    constant MCLK_PERIOD     : time   := 81.38 ns;  -- 12.288 MHz MCLK
    constant SAMPLING_FREQ   : real   := 48000.00;  -- 48 kHz sampling rate
    constant T_SAMPLE        : real   := 1.0 / SAMPLING_FREQ;

    constant C_AXI_STREAM_DATA_WIDTH : integer := 32; -- Added for consistency
    constant C_S00_AXI_DATA_WIDTH    : integer := 32;
    constant C_S00_AXI_ADDR_WIDTH    : integer := 4;

    -- Input waveform
    constant AUDIO_DATA_WIDTH : integer := 24;
    constant SINE_FREQ        : real   := 2000.0;
    constant SINE_AMPL        : real   := real(2**(AUDIO_DATA_WIDTH - 1) - 1);

    -- New signal for varying amplitude
    signal current_sine_ampl : real := SINE_AMPL * 0.25; -- Start at 25%

    ----------------------------------------------------------------------------------
    -- AXI signals
    signal S_AXI_ACLK    : std_logic;
    signal S_AXI_ARESETN : std_logic;
    signal S_AXI_AWADDR  : std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
    signal S_AXI_AWVALID : std_logic;
    signal S_AXI_WDATA   : std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
    signal S_AXI_WSTRB   : std_logic_vector((C_S00_AXI_DATA_WIDTH / 8) - 1 downto 0);
    signal S_AXI_WVALID  : std_logic;
    signal S_AXI_BREADY  : std_logic;
    signal S_AXI_ARADDR  : std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
    signal S_AXI_ARVALID : std_logic;
    signal S_AXI_RREADY  : std_logic;
    signal S_AXI_ARREADY : std_logic;
    signal S_AXI_RDATA   : std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
    signal S_AXI_RRESP   : std_logic_vector(1 downto 0);
    signal S_AXI_RVALID  : std_logic;
    signal S_AXI_WREADY  : std_logic;
    signal S_AXI_BRESP   : std_logic_vector(1 downto 0);
    signal S_AXI_BVALID  : std_logic;
    signal S_AXI_AWREADY : std_logic;
    signal S_AXI_AWPROT  : std_logic_vector(2 downto 0);
    signal S_AXI_ARPROT  : std_logic_vector(2 downto 0);

    -- I2S and Control signals
    signal clk, m_clk                        : std_logic := '0';
    signal mute_en_sw                        : std_logic;
    signal mux_select                        : std_logic;
    signal mute_n, bclk, mclk, data_in, data_out, lrclk : std_logic := '0';
    -- AXI Stream
    signal M_AXIS_TDATA, S_AXIS_TDATA        : std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
    signal M_AXIS_TSTRB, S_AXIS_TSTRB        : std_logic_vector((C_S00_AXI_DATA_WIDTH / 8) - 1 downto 0);
    signal M_AXIS_TVALID, S_AXIS_TVALID      : std_logic := '0';
    signal M_AXIS_TREADY, S_AXIS_TREADY      : std_logic := '0';
    signal M_AXIS_TLAST, S_AXIS_TLAST        : std_logic := '0';
    -- Testbench signals
    signal bit_count                         : integer;
    signal sine_data, sine_data_tx           : std_logic_vector(AUDIO_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal reset_n                           : std_logic := '1';
    signal enable_stream                     : std_logic := '0';
    signal test_num                          : integer   := 0;

    -- FIFO signals (keep if needed, otherwise remove)
    signal fifo0_tdata_out  : std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
    signal fifo0_tvalid_out : std_logic;
    signal fifo0_tstrb_out  : std_logic_vector((C_S00_AXI_DATA_WIDTH / 8) - 1 downto 0);
    signal fifo0_tlast_out  : std_logic;
    signal fifo0_tready     : std_logic;

    -- DDS input
    signal enable_send, enable_read : std_logic;
    signal axi_data_out             : std_logic_vector(4 - 1 downto 0);
    signal axi_data_write           : std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
    signal data_select              : std_logic_vector(C_S00_AXI_ADDR_WIDTH - 3 downto 0);
    signal axi_reg                  : integer := 0;

    -- RMS output signal
    signal amplitude_int : std_logic_vector(2 downto 0);

    ----------------------------------------------------------------------------
    -- Procedures for driving the AXI bus (Unchanged)
    ----------------------------------------------------------------------------
    procedure master_write_axi_reg(
        signal S_AXI_AWADDR : out std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
        signal S_AXI_WDATA  : out std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
        signal S_AXI_WSTRB  : out std_logic_vector((C_S00_AXI_DATA_WIDTH / 8) - 1 downto 0);
        signal enable_send  : out std_logic;
        signal axi_register : in integer;
        signal write_data   : in std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
        signal S_AXI_BVALID : in std_logic) is
    begin
        S_AXI_AWADDR                              <= (others => '0');
        S_AXI_AWADDR(C_S00_AXI_ADDR_WIDTH - 1 downto 2) <= std_logic_vector(to_unsigned(axi_register, C_S00_AXI_ADDR_WIDTH - 2));
        S_AXI_WSTRB                               <= (others => '1');
        S_AXI_WDATA                               <= std_logic_vector(resize(unsigned(write_data), C_S00_AXI_DATA_WIDTH));
        enable_send                               <= '1'; --Start AXI Write to responder
        wait for 1 ns;
        enable_send <= '0';                      --Clear Start Send Flag

        wait until S_AXI_BVALID = '1';
        wait until S_AXI_BVALID = '0';           --AXI Write finished
        S_AXI_WSTRB <= (others => '0');
        wait for CLOCK_PERIOD;

    end procedure master_write_axi_reg;

    procedure master_read_axi_reg(
        signal S_AXI_ARADDR : out std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
        signal enable_read  : out std_logic;
        signal axi_register : in integer;
        signal S_AXI_RVALID : in std_logic) is
    begin
        S_AXI_ARADDR                              <= (others => '0');
        S_AXI_ARADDR(C_S00_AXI_ADDR_WIDTH - 1 downto 2) <= std_logic_vector(to_unsigned(axi_register, C_S00_AXI_ADDR_WIDTH - 2));
        enable_read                               <= '1'; --Start AXI Read from responder
        wait for 1 ns;
        enable_read <= '0';                      --Clear "Start Read" Flag
        wait until S_AXI_RVALID = '1';
        wait until S_AXI_RVALID = '0';
        wait for CLOCK_PERIOD;

    end procedure master_read_axi_reg;

begin
    ----------------------------------------------------------------------------
    -- Instantiate the Unit Under Test (UUT)
    ----------------------------------------------------------------------------
    i2s_wrapper : audio_passthrough
        generic map(
            C_AXI_STREAM_DATA_WIDTH => C_AXI_STREAM_DATA_WIDTH, -- Added generic
            C_S00_AXI_DATA_WIDTH    => C_S00_AXI_DATA_WIDTH,
            C_S00_AXI_ADDR_WIDTH    => C_S00_AXI_ADDR_WIDTH
        )
        port map(
            mclk_i => m_clk,
            mux_select => mux_select,
            ac_mute_en_i => mute_en_sw,

            ac_bclk_o => bclk,
            ac_mclk_o => mclk,
            ac_mute_n_o => mute_n,
            ac_dac_data_o => data_out,
            ac_dac_lrclk_o => open,       -- Connect if needed, or check UUT
            ac_adc_data_i => data_in,
            ac_adc_lrclk_o => lrclk,

            amplitude_o => amplitude_int,

            -- AXI Lite (Slave) Interface
            dds_enable_i    => '1',
            dds_reset_i     => '0',
            s00_axi_aclk    => S_AXI_ACLK,
            s00_axi_aresetn => S_AXI_ARESETN,
            s00_axi_awaddr  => S_AXI_AWADDR,
            s00_axi_awprot  => S_AXI_AWPROT,
            s00_axi_awvalid => S_AXI_AWVALID,
            s00_axi_awready => S_AXI_AWREADY,
            s00_axi_wdata   => S_AXI_WDATA,
            s00_axi_wstrb   => S_AXI_WSTRB,
            s00_axi_wvalid  => S_AXI_WVALID,
            s00_axi_wready  => S_AXI_WREADY,
            s00_axi_bresp   => S_AXI_BRESP,
            s00_axi_bvalid  => S_AXI_BVALID,
            s00_axi_bready  => S_AXI_BREADY,
            s00_axi_araddr  => S_AXI_ARADDR,
            s00_axi_arprot  => S_AXI_ARPROT,
            s00_axi_arvalid => S_AXI_ARVALID,
            s00_axi_arready => S_AXI_ARREADY,
            s00_axi_rdata   => S_AXI_RDATA,
            s00_axi_rresp   => S_AXI_RRESP,
            s00_axi_rvalid  => S_AXI_RVALID,
            s00_axi_rready  => S_AXI_RREADY,

            -- AXI Stream Master (Output) - Connect if needed, else tie off
            m00_axis_aclk    => clk,
            m00_axis_aresetn => reset_n,
            m00_axis_tvalid  => M_AXIS_TVALID,
            m00_axis_tdata   => M_AXIS_TDATA,
            m00_axis_tlast   => M_AXIS_TLAST,
            m00_axis_tready  => M_AXIS_TREADY
        );

    ----------------------------------------------------------------------------
    -- Default Settings
    ----------------------------------------------------------------------------
    mute_en_sw <= '0';
    mux_select <= '1'; -- Ensure this selects the I2S input path to RMS
    S_AXIS_TDATA <= (others => '0'); -- Tie off unused inputs
    S_AXIS_TSTRB <= (others => '0');
    S_AXIS_TVALID <= '0';
    S_AXIS_TLAST <= '0';
    M_AXIS_TREADY <= '1'; -- Ready to accept output data

    ----------------------------------------------------------------------------
    -- Clock Generation Processes
    ----------------------------------------------------------------------------
    sysclk_gen : process
    begin
        while true loop
            clk        <= '0';
            S_AXI_ACLK <= '0';
            wait for CLOCK_PERIOD / 2;
            clk        <= '1';
            S_AXI_ACLK <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process;

    mclk_gen : process
    begin
        while true loop
            m_clk <= '0';
            wait for MCLK_PERIOD / 2; -- Corrected to use MCLK_PERIOD
            m_clk <= '1';
            wait for MCLK_PERIOD / 2; -- Corrected to use MCLK_PERIOD
        end loop;
    end process;

    ----------------------------------------------------------------------------
    -- Stimulus: Generate I2S Audio with Varying Amplitude
    ----------------------------------------------------------------------------
    generate_audio_data : process
        variable t : real := 0.0;
    begin
        loop
            -- Calculate sine wave data based on current amplitude
            if current_sine_ampl = 0.0 then
                sine_data <= (others => '0');
            else
                sine_data <= std_logic_vector(to_signed(integer(current_sine_ampl * sin(math_2_pi * SINE_FREQ * t)), AUDIO_DATA_WIDTH));
            end if;

            -- Invert MSB (assuming this is needed for I2S format/UUT input)
            sine_data_tx <= std_logic_vector(unsigned(not(sine_data(AUDIO_DATA_WIDTH - 1)) & sine_data(AUDIO_DATA_WIDTH - 2 downto 0)));

            -- Wait for Left Channel (assuming LRCLK=1 is Left)
            wait until lrclk = '1';

            -- Transmit sample (Right Channel - assumed based on original code waiting for LRCLK=1 first)
            bit_count <= AUDIO_DATA_WIDTH - 1; -- Initialize bit counter, send MSB first
            for i in 0 to AUDIO_DATA_WIDTH - 1 loop
                wait until bclk = '0';
                data_in <= sine_data_tx(bit_count - i); -- Set input data
                wait until bclk = '1'; -- Wait for clock edge (typical I2S)
            end loop;
            data_in <= '0';

            -- Wait for Right Channel (assuming LRCLK=0 is Right)
            wait until lrclk = '0';

            -- Transmit sample (Left Channel)
            bit_count <= AUDIO_DATA_WIDTH - 1; -- Reset bit counter to MSB
            for i in 0 to AUDIO_DATA_WIDTH - 1 loop
                wait until bclk = '0';
                data_in <= sine_data_tx(bit_count - i); -- Set input data
                wait until bclk = '1'; -- Wait for clock edge
            end loop;
            data_in <= '0';

            -- Increment time by one sample period
            t := t + T_SAMPLE;
        end loop;
    end process generate_audio_data;

    ----------------------------------------------------------------------------
    -- AXI Master Simulation Processes (Unchanged)
    ----------------------------------------------------------------------------
    send : PROCESS
    BEGIN
        S_AXI_AWVALID <= '0';
        S_AXI_WVALID  <= '0';
        S_AXI_BREADY  <= '0';
        S_AXI_AWPROT  <= "000"; -- Set protection bits
        loop
            wait until enable_send = '1';
            wait until S_AXI_ACLK = '0';
            S_AXI_AWVALID <= '1';
            S_AXI_WVALID  <= '1';
            wait until (S_AXI_AWREADY and S_AXI_WREADY) = '1'; --Client ready to read address/data
            S_AXI_BREADY <= '1';
            wait until S_AXI_BVALID = '1';                     -- Write result valid
            assert S_AXI_BRESP = "00" report "AXI data not written" severity failure;
            S_AXI_AWVALID <= '0';
            S_AXI_WVALID  <= '0';
            S_AXI_BREADY  <= '1';
            wait until S_AXI_BVALID = '0';                     -- All finished
            S_AXI_BREADY <= '0';
        end loop;
    END PROCESS send;

    read : PROCESS
    BEGIN
        S_AXI_ARVALID <= '0';
        S_AXI_RREADY  <= '0';
        S_AXI_ARPROT  <= "000"; -- Set protection bits
        loop
            wait until enable_read = '1';
            wait until S_AXI_ACLK = '0';
            S_AXI_ARVALID <= '1';
            S_AXI_RREADY  <= '1';
            wait until (S_AXI_RVALID and S_AXI_ARREADY) = '1'; --Client provided data
            assert S_AXI_RRESP = "00" report "AXI data not read" severity failure; -- Corrected report
            S_AXI_ARVALID <= '0';
            S_AXI_RREADY  <= '0';
        end loop;
    END PROCESS read;

    ----------------------------------------------------------------------------
    -- Testbench Stimulus and Control
    ----------------------------------------------------------------------------
    stimulus : PROCESS
    BEGIN
        -- Initialize, reset
        S_AXI_ARESETN <= '0';
        reset_n       <= '0';
        enable_send   <= '0';
        enable_read   <= '0';
        data_select   <= (others => '0');
        axi_data_write <= (others => '0');
        axi_reg       <= 0;

        wait for 200 ns; -- Increase reset time
        S_AXI_ARESETN <= '1';
        reset_n       <= '1';

        wait until rising_edge(S_AXI_ACLK);
        wait for CLOCK_PERIOD;

        -- Optional: write data to AXI registers
        axi_reg       <= 0;
        axi_data_write <= std_logic_vector(to_unsigned(11, axi_data_write'LENGTH)); -- Data Sending
        master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
        wait for 50 ns;

        axi_reg       <= 1;
        axi_data_write <= std_logic_vector(to_unsigned(89, axi_data_write'LENGTH));
        master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
        wait for 1 ms;

        -- === Start RMS Amplitude Test Sequence ===
        report "Starting RMS test. Initial 25% amplitude.";
        current_sine_ampl <= SINE_AMPL * 0.25;
        wait for 1 ms; -- Allow time for RMS to settle

        report "Changing amplitude to 100%.";
        current_sine_ampl <= SINE_AMPL * 1.0;
        wait for 1 ms;

        report "Changing amplitude to 50%.";
        current_sine_ampl <= SINE_AMPL * 0.5;
        wait for 1 ms;

        report "Changing amplitude to 0%.";
        current_sine_ampl <= 0.0;
        wait for 1 ms;

        report "Test sequence finished.";
        std.env.stop; -- Stop the simulation
    END PROCESS stimulus;


--    ----------------------------------------------------------------------------
--    -- NEW: Process to Check RMS Amplitude Output
--    ----------------------------------------------------------------------------
--    check_amplitude : process
--        -- Approximate expected MSB positions for A^2/2
--        -- O1 (25% ampl) ~ 2^41. Expect bit 41 = '1', bits 47-42 = '0'.
--        -- O2 (100% ampl) ~ 2^45. Expect bit 45 = '1', bits 47-46 = '0'.
--        -- O3 (50% ampl) ~ 2^43. Expect bit 43 = '1', bits 47-44 = '0'.
--        constant ZERO_THRESHOLD : unsigned(47 downto 0) := to_unsigned(1000, 48); -- Small threshold for zero
--        variable ampl_val       : std_logic_vector(47 downto 0);
--    begin
--        -- Wait until after reset and initial AXI writes
--        wait until S_AXI_ARESETN = '1';
--        wait for 20 ms;

--        -- Check 25% amplitude
--        wait for 80 ms; -- Total ~100ms after start
--        ampl_val := amplitude_int;
--        report "Checking 25% amplitude. Value = 0x" & to_hstring(ampl_val);
--        assert (ampl_val(47 downto 42) = "000000" and ampl_val(41) = '1')
--            report "Amplitude (25%) check failed!" severity warning;

--        -- Check 100% amplitude
--        wait for 100 ms; -- Total ~200ms
--        ampl_val := amplitude_int;
--        report "Checking 100% amplitude. Value = 0x" & to_hstring(ampl_val);
--        assert (ampl_val(47 downto 46) = "00" and ampl_val(45) = '1')
--            report "Amplitude (100%) check failed!" severity warning;

--        -- Check 50% amplitude
--        wait for 100 ms; -- Total ~300ms
--        ampl_val := amplitude_int;
--        report "Checking 50% amplitude. Value = 0x" & to_hstring(ampl_val);
--        assert (ampl_val(47 downto 44) = "0000" and ampl_val(43) = '1')
--            report "Amplitude (50%) check failed!" severity warning;

--        -- Check 0% amplitude
--        wait for 100 ms; -- Total ~400ms
--        ampl_val := amplitude_int;
--        report "Checking 0% amplitude. Value = 0x" & to_hstring(ampl_val);
--        assert (unsigned(ampl_val) < ZERO_THRESHOLD)
--            report "Amplitude (0%) check failed!" severity warning;

--        wait; -- Wait indefinitely until stimulus stops
--    end process check_amplitude;


end architecture sim;