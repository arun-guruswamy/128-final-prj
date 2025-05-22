----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/25/2025 03:23:02 PM
-- Design Name: 
-- Module Name: axi_transmitter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axi_transmitter is	
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
end axi_transmitter;

architecture Behavioral of axi_transmitter is

-- AXI stream receiver
component double_flip_flop is
        Port(	
		clk_i   : in   std_logic;
        async_data_i    : in std_logic_vector(24-1 downto 0);
        sync_data_o     : out std_logic_vector(24-1 downto 0));
end component double_flip_flop;

component double_flip_flop_clk is
        Port(	
		clk_i   : in   std_logic;
        async_data_i    : in std_logic;
        sync_data_o     : out std_logic);
end component double_flip_flop_clk;

signal data_out : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal valid_int : std_logic := '0';
signal left_data_int, right_data_int : std_logic_vector(24-1 downto 0) := (others => '0');
type state_type is (idle1, load1, idle2, load2);	-- Setup states 
signal current_state, next_state : state_type := idle1;	-- Setup signals as state types';

begin

-- AXI stream clk syncronizer
axi_ff_right : double_flip_flop 	
        port map (	
            clk_i           => m00_axis_aclk,
            async_data_i    => right_audio_data,
            sync_data_o     => right_data_int);
 
 axi_ff_left : double_flip_flop 	
        port map (	
            clk_i           => m00_axis_aclk,
            async_data_i    => left_audio_data,
            sync_data_o     => left_data_int);

StateUpdate: process(m00_axis_aclk)
begin
    if rising_edge(m00_axis_aclk) then
        current_state <= next_state;
    end if;
end process StateUpdate;
    
NextStateLogic: process(current_state, m00_axis_aresetn, lrclk_i, m00_axis_tready, right_data_int, left_data_int)
begin
    next_state  <= current_state;
        
    case current_state is
        when idle1 =>
            if m00_axis_aresetn = '1' and lrclk_i = '1' then
                next_state <= load1;
            end if;
            valid_int <= '0';
        when load1 => 
            valid_int <= '1';
            if m00_axis_tready = '1' then
                data_out <= right_data_int & "00000001";
                next_state <= idle2;
            end if;
        when idle2  =>
            if m00_axis_aresetn = '1' and lrclk_i = '0' then
                next_state <= load2;
            end if;
            valid_int <= '0';
        when load2 =>
            valid_int <= '1';
            if m00_axis_tready = '1' then
                data_out <= left_data_int & "00000000";
                next_state <= idle1;
            end if;
       when others => next_state <= idle1;                
    end case;
end process NextStateLogic;


m00_axis_tdata <= data_out;
m00_axis_tvalid <= valid_int;
m00_axis_tstrb  <= "1111";
m00_axis_tlast <= '1';


end Behavioral;
