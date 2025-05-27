----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: DDS Controller with Block Memory (BROM) for storing the samples
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;             -- required for modulus function
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity dds_controller is
    Generic ( DDS_DATA_WIDTH : integer := 24;       -- DDS data width
            PHASE_DATA_WIDTH : integer := 15);      -- DDS phase increment data width
    Port ( 
      clk_i         : in std_logic;
      enable_i      : in std_logic;
      reset_i       : in std_logic;
      phase_inc_i   : in std_logic_vector(PHASE_DATA_WIDTH-1 downto 0);
      
      data_o        : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0)); 
end dds_controller;
----------------------------------------------------------------------------
architecture Behavioral of dds_controller is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
constant DDS_DataWidth : integer := 12;

signal counter_reg          : integer := 0;
signal counter_address      : std_logic_vector(DDS_DataWidth-1 DOWNTO 0) := (others => '0'); 

COMPONENT blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(DDS_DataWidth-1 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------

block_rom : blk_mem_gen_0
  PORT MAP (
    clka => clk_i,
    ena => '1',
    addra => counter_address,
    douta => data_o);
  

datapath : process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            counter_reg <= 0;
        elsif enable_i = '1' then
            counter_reg <= counter_reg + to_integer(unsigned(phase_inc_i)) + 1;
        end if;
    end if;
    
    counter_address <= std_logic_vector(to_unsigned(counter_reg, counter_address'length));
end process datapath;
----------------------------------------------------------------------------   
end Behavioral;