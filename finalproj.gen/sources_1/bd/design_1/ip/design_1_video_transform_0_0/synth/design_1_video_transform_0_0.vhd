-- (c) Copyright 1995-2025 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:module_ref:video_transform:1.0
-- IP Revision: 1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY design_1_video_transform_0_0 IS
  PORT (
    Video_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    Video_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axis_audio_aclk : IN STD_LOGIC;
    s_axis_audio_aresetn : IN STD_LOGIC;
    s_axis_audio_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_audio_tvalid : IN STD_LOGIC;
    s_axis_audio_tlast : IN STD_LOGIC;
    s_axis_audio_tready : OUT STD_LOGIC;
    mute_en_not : IN STD_LOGIC;
    m_axis_amp_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END design_1_video_transform_0_0;

ARCHITECTURE design_1_video_transform_0_0_arch OF design_1_video_transform_0_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF design_1_video_transform_0_0_arch: ARCHITECTURE IS "yes";
  COMPONENT video_transform IS
    GENERIC (
      C_VIDEO_DATA_WIDTH : INTEGER;
      C_AUDIO_DATA_WIDTH : INTEGER;
      C_OUTPUT_DATA_WIDTH : INTEGER
    );
    PORT (
      Video_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
      Video_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
      s_axis_audio_aclk : IN STD_LOGIC;
      s_axis_audio_aresetn : IN STD_LOGIC;
      s_axis_audio_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_axis_audio_tvalid : IN STD_LOGIC;
      s_axis_audio_tlast : IN STD_LOGIC;
      s_axis_audio_tready : OUT STD_LOGIC;
      mute_en_not : IN STD_LOGIC;
      m_axis_amp_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
  END COMPONENT video_transform;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF design_1_video_transform_0_0_arch: ARCHITECTURE IS "video_transform,Vivado 2021.2";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF design_1_video_transform_0_0_arch : ARCHITECTURE IS "design_1_video_transform_0_0,video_transform,{}";
  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF design_1_video_transform_0_0_arch: ARCHITECTURE IS "design_1_video_transform_0_0,video_transform,{x_ipProduct=Vivado 2021.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=video_transform,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VHDL,x_ipSimLanguage=MIXED,C_VIDEO_DATA_WIDTH=24,C_AUDIO_DATA_WIDTH=32,C_OUTPUT_DATA_WIDTH=32}";
  ATTRIBUTE IP_DEFINITION_SOURCE : STRING;
  ATTRIBUTE IP_DEFINITION_SOURCE OF design_1_video_transform_0_0_arch: ARCHITECTURE IS "module_ref";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_INFO OF s_axis_audio_tready: SIGNAL IS "xilinx.com:interface:axis:1.0 s_axis_audio TREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s_axis_audio_tlast: SIGNAL IS "xilinx.com:interface:axis:1.0 s_axis_audio TLAST";
  ATTRIBUTE X_INTERFACE_INFO OF s_axis_audio_tvalid: SIGNAL IS "xilinx.com:interface:axis:1.0 s_axis_audio TVALID";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s_axis_audio_tdata: SIGNAL IS "XIL_INTERFACENAME s_axis_audio, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, CLK_DOMAIN design_1_processing_system7_0_0_FCLK_CLK0, LAYERED_METADATA undef, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF s_axis_audio_tdata: SIGNAL IS "xilinx.com:interface:axis:1.0 s_axis_audio TDATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s_axis_audio_aresetn: SIGNAL IS "XIL_INTERFACENAME s_axis_audio_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF s_axis_audio_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 s_axis_audio_aresetn RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s_axis_audio_aclk: SIGNAL IS "XIL_INTERFACENAME s_axis_audio_aclk, ASSOCIATED_BUSIF s_axis_audio, ASSOCIATED_RESET s_axis_audio_aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN design_1_processing_system7_0_0_FCLK_CLK0, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF s_axis_audio_aclk: SIGNAL IS "xilinx.com:signal:clock:1.0 s_axis_audio_aclk CLK";
BEGIN
  U0 : video_transform
    GENERIC MAP (
      C_VIDEO_DATA_WIDTH => 24,
      C_AUDIO_DATA_WIDTH => 32,
      C_OUTPUT_DATA_WIDTH => 32
    )
    PORT MAP (
      Video_in => Video_in,
      Video_out => Video_out,
      s_axis_audio_aclk => s_axis_audio_aclk,
      s_axis_audio_aresetn => s_axis_audio_aresetn,
      s_axis_audio_tdata => s_axis_audio_tdata,
      s_axis_audio_tvalid => s_axis_audio_tvalid,
      s_axis_audio_tlast => s_axis_audio_tlast,
      s_axis_audio_tready => s_axis_audio_tready,
      mute_en_not => mute_en_not,
      m_axis_amp_tdata => m_axis_amp_tdata
    );
END design_1_video_transform_0_0_arch;
