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

entity axi_receiver is	
        generic (
            DATA_WIDTH	: integer	:= 32;
            FIFO_DEPTH	: integer	:= 1024
        );
        
        Port(	
		lrclk_i : in std_logic;
		
		left_audio_data : out std_logic_vector(24-1 downto 0);
		right_audio_data : out std_logic_vector(24-1 downto 0);
		
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;
		
		
		s00_axis_tready   : out std_logic
		);		
end axi_receiver;

architecture Behavioral of axi_receiver is

signal left_data_out, right_data_out : std_logic_vector(24-1 downto 0) := (others => '0');
signal ready_int : std_logic := '0';
type state_type is (idle, read);	-- Setup states 
signal current_state, next_state : state_type := idle;	-- Setup signals as state types';

begin

StateUpdate: process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        current_state <= next_state;
    end if;
end process StateUpdate;
    
NextStateLogic: process(current_state, s00_axis_aresetn, lrclk_i, s00_axis_tvalid)
begin
    next_state  <= current_state;
    ready_int <= '1';
        
    case current_state is
        when idle =>
            ready_int <= '0';
            if s00_axis_aresetn = '1' then
                next_state <= read; 
            end if;
        when read => 
            ready_int <= '1';
            if s00_axis_tvalid = '1' and s00_axis_tdata(0) = '1' then
                right_data_out <= s00_axis_tdata(31 downto 8);
                next_state <= idle;
            elsif s00_axis_tvalid = '1' and s00_axis_tdata(0) = '0' then
                left_data_out <= s00_axis_tdata(31 downto 8);
                next_state <= idle;
            end if;
       when others => next_state <= idle;                
    end case;
end process NextStateLogic;

left_audio_data <= left_data_out;
right_audio_data <= right_data_out;
s00_axis_tready <= ready_int;

end Behavioral;