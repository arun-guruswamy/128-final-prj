----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/22/2025 03:23:12 PM
-- Design Name: 
-- Module Name: video_gen - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity video_gen is
Port ( 
   pxl_clk  : in  std_logic;
   hblank_i  : in std_logic;
   fsync_i : in std_logic;
   active_video_i : in std_logic;
   amplitude : in std_logic_vector(3 downto 0);
   
   pxl_o : out std_logic_vector(23 downto 0));
end video_gen;

architecture Behavioral of video_gen is

constant SQUARE_SIZE : integer := 100;
constant SCREEN_WIDTH : integer := 1280;
constant SCREEN_HEIGHT : integer := 720;

signal pxl_int : std_logic_vector(23 downto 0);
signal shape_x_position, x_coord : integer range 0 to 1279 := 0;
signal shape_y_position, y_coord : integer range 0 to 719 := 0;
signal x_speed, y_speed : integer := 0;
signal status : std_logic := '0';


begin
                                                
pixel_counter : process(pxl_clk)
begin
    if rising_edge(pxl_clk) then
        if fsync_i = '1' then
            x_coord <= 0;
        elsif hblank_i = '0' then
                x_coord <= 0;            
        elsif active_video_i = '1' then
                x_coord <= x_coord + 1;
        end if;
        
        if fsync_i = '1' then
            y_coord <= 0;
        elsif x_coord = 1 then                      
                y_coord <= y_coord + 1;
        end if;  
           
        if fsync_i = '1' then
           if (shape_x_position + 50) = 600 then
              x_speed <= -to_integer(unsigned(amplitude));
           elsif shape_x_position = 0 then
              x_speed <= to_integer(unsigned(amplitude));
           end if;
           shape_x_position <= shape_x_position + x_speed;    
        end if;   
        
        if fsync_i = '1' then
           if (shape_y_position + 50) = 480 then
              y_speed <= -to_integer(unsigned(amplitude));
           elsif shape_y_position = 0 then
              y_speed <= to_integer(unsigned(amplitude));
           end if;
           shape_y_position <= shape_y_position + y_speed;    
        end if;                      
    end if;
end process pixel_counter;

generate_bits: process(pxl_clk) 
begin
    if rising_edge(pxl_clk) then
        if active_video_i = '1' then 
            if x_coord > shape_x_position and x_coord < (shape_x_position + 50) and y_coord > shape_y_position and y_coord < (shape_y_position + 50) then
                pxl_int <= x"f63f0f";
            else 
                pxl_int <= x"000000";  
            end if;
        else 
            pxl_int <= x"000000";  
    end if;
end if;
    
end process generate_bits;

pxl_o <= pxl_int;

end Behavioral;
