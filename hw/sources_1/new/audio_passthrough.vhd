
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;     
use IEEE.STD_LOGIC_UNSIGNED.ALL;                                    
----------------------------------------------------------------------------
-- Entity definition
entity audio_passthrough is
	generic (
		C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_DATA_WIDTH : integer := 32;
		C_S00_AXI_ADDR_WIDTH : integer := 4);
    Port ( 
		-- Master clock 
		mclk_i : in std_logic;

        -- I2S audio codec ports		
		-- User controls
		mux_select    : in STD_LOGIC; 
		ac_mute_en_i  : in STD_LOGIC;
		
		-- Audio Codec I2S controls
        ac_bclk_o : out STD_LOGIC;
        ac_mclk_o : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC;	-- Active Low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i : in STD_LOGIC;
        ac_adc_lrclk_o : out STD_LOGIC;
        
		-- Axi Responder/Slave Bus Interface S00_AXI
		dds_enable_i    : in std_logic;
        dds_reset_i     : in std_logic;
        s00_axi_aclk	: in std_logic;
        s00_axi_aresetn	: in std_logic;
        s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awprot	: in std_logic_vector(2 downto 0);
        s00_axi_awvalid	: in std_logic;
        s00_axi_awready	: out std_logic;
        s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wvalid	: in std_logic;
        s00_axi_wready	: out std_logic;
        s00_axi_bresp	: out std_logic_vector(1 downto 0);
        s00_axi_bvalid	: out std_logic;
        s00_axi_bready	: in std_logic;
        s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arprot	: in std_logic_vector(2 downto 0);
        s00_axi_arvalid	: in std_logic;
        s00_axi_arready	: out std_logic;
        s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp	: out std_logic_vector(1 downto 0);
        s00_axi_rvalid	: out std_logic;
        s00_axi_rready	: in std_logic;
		
        -- AXI Stream Interface (Tranmitter/Controller)
		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic);
end audio_passthrough;
----------------------------------------------------------------------------
architecture Behavioral of audio_passthrough is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant AC_DATA_WIDTH : integer := 24;

-- Clock forwarding 
signal mclk_fwd_o, bclk_fwd_o, adc_lrclk_fwd_o, dac_lrclk_fwd_o : std_logic := '0';
signal bclk_o, lrclk_o, lrclk_unbuf : std_logic := '0';

-- Active mux inputs 
signal left_input_dds       : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_input_dds      : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal left_input_reciever  : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_input_reciever : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

-- Selected audio data to AXI transmitter
signal left_input_to_axi_transmitter  : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_input_to_axi_transmitter : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Clock generation
component i2s_clock_gen is
    Port (
        -- System clock in
		mclk_i   : in  std_logic;	
		
		-- Forwarded clocks
		mclk_fwd_o		  : out std_logic;	
		bclk_fwd_o        : out std_logic;
		adc_lrclk_fwd_o   : out std_logic;
		dac_lrclk_fwd_o   : out std_logic;

        -- Clocks for I2S components
		bclk_o            : out std_logic;
		lrclk_o           : out std_logic;
		lrclk_unbuf_o     : out std_logic);  
end component;

---------------------------------------------------------------------------- 
-- I2S receiver
component i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		adc_serial_data_i     : in std_logic);  
end component; 
	
---------------------------------------------------------------------------- 
-- I2S transmitter
component i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end component; 

---------------------------------------------------------------------------- 
-- AXI stream transmitter
component axi_transmitter is	
        generic (
            DATA_WIDTH	: integer	:= 32;
            FIFO_DEPTH	: integer	:= 1024
        );
        Port(	
		lrclk_i : in std_logic;
		
		left_audio_data : in std_logic_vector(24-1 downto 0);
		right_audio_data : in std_logic_vector(24-1 downto 0);
		
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;

		m00_axis_tready   : in std_logic;
		
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic
		);		
end component axi_transmitter;
    
----------------------------------------------------------------------------
component engs128_axi_dds is
	generic (
	    ----------------------------------------------------------------------------
		-- Users to add parameters here
		DDS_DATA_WIDTH : integer := 24;         -- DDS data width
        DDS_PHASE_DATA_WIDTH : integer := 12;   -- DDS phase increment data width;;;
        ----------------------------------------------------------------------------

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
	    ----------------------------------------------------------------------------
		-- Users to add ports here
		dds_clk_i     : in std_logic;
		dds_enable_i  : in std_logic;
		dds_reset_i   : in std_logic;
		left_dds_data_o    : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0);
		right_dds_data_o    : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0);
		
		-- Debug ports to send to ILA
		left_dds_phase_inc_dbg_o : out std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);   
		right_dds_phase_inc_dbg_o : out std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);   
		
		----------------------------------------------------------------------------
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Responder/Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end component engs128_axi_dds;
----------------------------------------------------------------------------

begin

----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    
-- Clock generation
clock_gen : i2s_clock_gen 
    port map (			
        mclk_i   => mclk_i,	

        mclk_fwd_o		  => ac_mclk_o,
		bclk_fwd_o        => ac_bclk_o,
		adc_lrclk_fwd_o   => ac_adc_lrclk_o,
		dac_lrclk_fwd_o   => ac_dac_lrclk_o,
		
		bclk_o            => bclk_o,
		lrclk_o           => lrclk_o,
        lrclk_unbuf_o     => lrclk_unbuf);

---------------------------------------------------------------------------- 
-- I2S receiver
audio_receiver: i2s_receiver
    port map (
		mclk_i                => mclk_i,
		bclk_i                => bclk_o,	
		lrclk_i               => lrclk_o,
		
		left_audio_data_o     => left_input_reciever,
		right_audio_data_o    => right_input_reciever,
		adc_serial_data_i => ac_adc_data_i);  
	
---------------------------------------------------------------------------- 
-- I2S transmitter
audio_transmitter: i2s_transmitter 
    port map (			
        mclk_i              => mclk_i,	
        bclk_i              => bclk_o,
        lrclk_i             => lrclk_o,

       left_audio_data_i   => left_input_to_axi_transmitter,
       right_audio_data_i  => right_input_to_axi_transmitter,
	   dac_serial_data_o    => ac_dac_data_o);

---------------------------------------------------------------------------- 
-- AXI stream transmitter
axi_tx : axi_transmitter	
    port map (	
		lrclk_i => lrclk_o,
		
		left_audio_data => left_input_to_axi_transmitter,
		right_audio_data => right_input_to_axi_transmitter,
		
		m00_axis_aclk     => m00_axis_aclk,
		m00_axis_aresetn  => m00_axis_aresetn,

		m00_axis_tready   => m00_axis_tready,
		
		m00_axis_tvalid   => m00_axis_tvalid,
		m00_axis_tdata    => m00_axis_tdata,
		m00_axis_tstrb    => m00_axis_tstrb,
		m00_axis_tlast    => m00_axis_tlast);			

---------------------------------------------------------------------------- 
-- DDS 
axi_dds : engs128_axi_dds
        port map(
            dds_clk_i     => lrclk_o,
            dds_enable_i  => dds_enable_i,
            dds_reset_i   => dds_reset_i,
            left_dds_data_o => left_input_dds,
            right_dds_data_o => right_input_dds,
            
            -- Debug ports to send to ILA
            left_dds_phase_inc_dbg_o    => open,
            right_dds_phase_inc_dbg_o   => open,
            
            ----------------------------------------------------------------------------
            -- User ports ends
            -- Do not modify the ports beyond this line
    
            -- Ports of Axi Responder/Slave Bus Interface S00_AXI
            s00_axi_aclk	=>s00_axi_aclk,
            s00_axi_aresetn	=>s00_axi_aresetn,
            s00_axi_awaddr	=>s00_axi_awaddr,
            s00_axi_awprot	=>s00_axi_awprot,
            s00_axi_awvalid	=>s00_axi_awvalid,
            s00_axi_awready	=>s00_axi_awready,
            s00_axi_wdata	=>s00_axi_wdata,
            s00_axi_wstrb	=>s00_axi_wstrb,
            s00_axi_wvalid	=>s00_axi_wvalid,
            s00_axi_wready	=>s00_axi_wready,
            s00_axi_bresp	=>s00_axi_bresp,
            s00_axi_bvalid	=>s00_axi_bvalid,
            s00_axi_bready	=>s00_axi_bready,
            s00_axi_araddr	=>s00_axi_araddr,
            s00_axi_arprot	=>s00_axi_arprot,
            s00_axi_arvalid	=>s00_axi_arvalid,
            s00_axi_arready	=>s00_axi_arready,
            s00_axi_rdata	=>s00_axi_rdata,
            s00_axi_rresp	=>s00_axi_rresp,
            s00_axi_rvalid	=>s00_axi_rvalid,
            s00_axi_rready	=>s00_axi_rready);
            
---------------------------------------------------------------------------- 
-- Audio data logic
---------------------------------------------------------------------------- 

AudioInput: process(mclk_i)
begin
    if rising_edge(mclk_i) then
        if (mux_select = '0') then
            left_input_to_axi_transmitter <= left_input_dds;
            right_input_to_axi_transmitter <= right_input_dds;
        else
            left_input_to_axi_transmitter <= left_input_reciever;
            right_input_to_axi_transmitter <= right_input_reciever;
        end if;
    end if;
end process AudioInput;


-- Mute enable switch (ACTIVE LOW)
ac_mute_n_o <= not(ac_mute_en_i);


end Behavioral;