--Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
--Date        : Tue May 27 18:05:39 2025
--Host        : m210-02 running 64-bit major release  (build 9200)
--Command     : generate_target design_1_wrapper.bd
--Design      : design_1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_wrapper is
  port (
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    TMDS_0_clk_n : out STD_LOGIC;
    TMDS_0_clk_p : out STD_LOGIC;
    TMDS_0_data_n : out STD_LOGIC_VECTOR ( 2 downto 0 );
    TMDS_0_data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
    TMDS_1_clk_n : out STD_LOGIC;
    TMDS_1_clk_p : out STD_LOGIC;
    TMDS_1_data_n : out STD_LOGIC_VECTOR ( 2 downto 0 );
    TMDS_1_data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
    ac_adc_data_i_0 : in STD_LOGIC;
    ac_adc_lrclk_o_0 : out STD_LOGIC;
    ac_bclk_o_0 : out STD_LOGIC;
    ac_dac_data_o_0 : out STD_LOGIC;
    ac_dac_lrclk_o_0 : out STD_LOGIC;
    ac_mclk_o_0 : out STD_LOGIC;
    ac_mute_en_i_0 : in STD_LOGIC;
    ac_mute_n_o_0 : out STD_LOGIC;
    hdmi_out_ddc_scl_io : inout STD_LOGIC;
    hdmi_out_ddc_sda_io : inout STD_LOGIC;
    iic_scl_io : inout STD_LOGIC;
    iic_sda_io : inout STD_LOGIC;
    mux_select_0 : in STD_LOGIC
  );
end design_1_wrapper;

architecture STRUCTURE of design_1_wrapper is
  component design_1 is
  port (
    ac_dac_lrclk_o_0 : out STD_LOGIC;
    ac_dac_data_o_0 : out STD_LOGIC;
    ac_mute_n_o_0 : out STD_LOGIC;
    ac_mclk_o_0 : out STD_LOGIC;
    ac_bclk_o_0 : out STD_LOGIC;
    ac_adc_lrclk_o_0 : out STD_LOGIC;
    ac_adc_data_i_0 : in STD_LOGIC;
    ac_mute_en_i_0 : in STD_LOGIC;
    mux_select_0 : in STD_LOGIC;
    iic_scl_i : in STD_LOGIC;
    iic_scl_o : out STD_LOGIC;
    iic_scl_t : out STD_LOGIC;
    iic_sda_i : in STD_LOGIC;
    iic_sda_o : out STD_LOGIC;
    iic_sda_t : out STD_LOGIC;
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    hdmi_out_ddc_sda_i : in STD_LOGIC;
    hdmi_out_ddc_sda_o : out STD_LOGIC;
    hdmi_out_ddc_sda_t : out STD_LOGIC;
    hdmi_out_ddc_scl_i : in STD_LOGIC;
    hdmi_out_ddc_scl_o : out STD_LOGIC;
    hdmi_out_ddc_scl_t : out STD_LOGIC;
    TMDS_0_clk_p : out STD_LOGIC;
    TMDS_0_clk_n : out STD_LOGIC;
    TMDS_0_data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
    TMDS_0_data_n : out STD_LOGIC_VECTOR ( 2 downto 0 );
    TMDS_1_clk_p : out STD_LOGIC;
    TMDS_1_clk_n : out STD_LOGIC;
    TMDS_1_data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
    TMDS_1_data_n : out STD_LOGIC_VECTOR ( 2 downto 0 )
  );
  end component design_1;
  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;
  signal hdmi_out_ddc_scl_i : STD_LOGIC;
  signal hdmi_out_ddc_scl_o : STD_LOGIC;
  signal hdmi_out_ddc_scl_t : STD_LOGIC;
  signal hdmi_out_ddc_sda_i : STD_LOGIC;
  signal hdmi_out_ddc_sda_o : STD_LOGIC;
  signal hdmi_out_ddc_sda_t : STD_LOGIC;
  signal iic_scl_i : STD_LOGIC;
  signal iic_scl_o : STD_LOGIC;
  signal iic_scl_t : STD_LOGIC;
  signal iic_sda_i : STD_LOGIC;
  signal iic_sda_o : STD_LOGIC;
  signal iic_sda_t : STD_LOGIC;
begin
design_1_i: component design_1
     port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      TMDS_0_clk_n => TMDS_0_clk_n,
      TMDS_0_clk_p => TMDS_0_clk_p,
      TMDS_0_data_n(2 downto 0) => TMDS_0_data_n(2 downto 0),
      TMDS_0_data_p(2 downto 0) => TMDS_0_data_p(2 downto 0),
      TMDS_1_clk_n => TMDS_1_clk_n,
      TMDS_1_clk_p => TMDS_1_clk_p,
      TMDS_1_data_n(2 downto 0) => TMDS_1_data_n(2 downto 0),
      TMDS_1_data_p(2 downto 0) => TMDS_1_data_p(2 downto 0),
      ac_adc_data_i_0 => ac_adc_data_i_0,
      ac_adc_lrclk_o_0 => ac_adc_lrclk_o_0,
      ac_bclk_o_0 => ac_bclk_o_0,
      ac_dac_data_o_0 => ac_dac_data_o_0,
      ac_dac_lrclk_o_0 => ac_dac_lrclk_o_0,
      ac_mclk_o_0 => ac_mclk_o_0,
      ac_mute_en_i_0 => ac_mute_en_i_0,
      ac_mute_n_o_0 => ac_mute_n_o_0,
      hdmi_out_ddc_scl_i => hdmi_out_ddc_scl_i,
      hdmi_out_ddc_scl_o => hdmi_out_ddc_scl_o,
      hdmi_out_ddc_scl_t => hdmi_out_ddc_scl_t,
      hdmi_out_ddc_sda_i => hdmi_out_ddc_sda_i,
      hdmi_out_ddc_sda_o => hdmi_out_ddc_sda_o,
      hdmi_out_ddc_sda_t => hdmi_out_ddc_sda_t,
      iic_scl_i => iic_scl_i,
      iic_scl_o => iic_scl_o,
      iic_scl_t => iic_scl_t,
      iic_sda_i => iic_sda_i,
      iic_sda_o => iic_sda_o,
      iic_sda_t => iic_sda_t,
      mux_select_0 => mux_select_0
    );
hdmi_out_ddc_scl_iobuf: component IOBUF
     port map (
      I => hdmi_out_ddc_scl_o,
      IO => hdmi_out_ddc_scl_io,
      O => hdmi_out_ddc_scl_i,
      T => hdmi_out_ddc_scl_t
    );
hdmi_out_ddc_sda_iobuf: component IOBUF
     port map (
      I => hdmi_out_ddc_sda_o,
      IO => hdmi_out_ddc_sda_io,
      O => hdmi_out_ddc_sda_i,
      T => hdmi_out_ddc_sda_t
    );
iic_scl_iobuf: component IOBUF
     port map (
      I => iic_scl_o,
      IO => iic_scl_io,
      O => iic_scl_i,
      T => iic_scl_t
    );
iic_sda_iobuf: component IOBUF
     port map (
      I => iic_sda_o,
      IO => iic_sda_io,
      O => iic_sda_i,
      T => iic_sda_t
    );
end STRUCTURE;
