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
   fsync_i : in STD_LOGIC_VECTOR(0 DOWNTO 0);
   active_video_i : in std_logic;
   amplitude : in std_logic_vector(2 downto 0);
   
   pxl_o : out std_logic_vector(23 downto 0));
end video_gen;

architecture Behavioral of video_gen is

constant SQUARE_SIZE : integer := 100;
constant SCREEN_WIDTH : integer := 1280;
constant SCREEN_HEIGHT : integer := 720;

-- Circle properties
constant CIRCLE_RADIUS      : integer := 25; -- Radius of the circle (similar to half of old square size 50)
constant CIRCLE_RADIUS_SQ   : integer := CIRCLE_RADIUS * CIRCLE_RADIUS; -- Radius squared for efficient calculation

-- Movement boundaries for the circle's EDGE (consistent with original square's edge boundaries)
constant X_RIGHT_BOUNDARY_EDGE  : integer := 600;
constant X_LEFT_BOUNDARY_EDGE   : integer := 0;
constant Y_BOTTOM_BOUNDARY_EDGE : integer := 460;
constant Y_TOP_BOUNDARY_EDGE    : integer := 0;

-- Calculate movement boundaries for the CENTER of the circle
constant MAX_CENTER_X       : integer := X_RIGHT_BOUNDARY_EDGE - CIRCLE_RADIUS;
constant MIN_CENTER_X       : integer := X_LEFT_BOUNDARY_EDGE  + CIRCLE_RADIUS;
constant MAX_CENTER_Y       : integer := Y_BOTTOM_BOUNDARY_EDGE - CIRCLE_RADIUS;
constant MIN_CENTER_Y       : integer := Y_TOP_BOUNDARY_EDGE   + CIRCLE_RADIUS;


signal pxl_int : std_logic_vector(23 downto 0);
signal shape_x_position, x_coord : integer range 0 to 1279 := 0;
signal shape_y_position, y_coord : integer range 0 to 719 := 0;
signal x_speed, y_speed : integer := 0;
signal status : std_logic := '0';


-- Circle center position
-- Initialize center at a starting boundary position
signal shape_center_x       : integer range 0 to SCREEN_WIDTH - 1 := MIN_CENTER_X; 
signal shape_center_y       : integer range 0 to SCREEN_HEIGHT - 1 := MIN_CENTER_Y;


begin
                                                
pixel_counter : process(pxl_clk)
begin
    if rising_edge(pxl_clk) then
        if fsync_i = "1" then
            x_coord <= 0;
        elsif hblank_i = '0' then -- '1' for sim, '0' for hardware
                x_coord <= 0;            
        elsif active_video_i = '1' then
                x_coord <= x_coord + 1;
        end if;
        
        if fsync_i = "1" then
            y_coord <= 0;
        elsif x_coord = 1 then                      
                y_coord <= y_coord + 1;
        end if;  
           
        if fsync_i = "1" then
           if (shape_x_position + 50) = 640 then
              x_speed <= -1;
--              if to_integer(unsigned(amplitude)) = 0 then
--                x_speed <= -1;
--              else 
--                x_speed <= -to_integer(unsigned(amplitude)); 
--              end if;
           elsif shape_x_position = 0 then
              x_speed <= 1;
--              if to_integer(unsigned(amplitude)) = 0 then
--                x_speed <= 1;
--              else 
--                x_speed <= to_integer(unsigned(amplitude)); 
--              end if;
           end if;
           shape_x_position <= shape_x_position + x_speed;    
        end if;   
        
        if fsync_i = "1" then
           if (shape_y_position + 50) = 360 then
              y_speed <= -1;
--              if to_integer(unsigned(amplitude)) = 0 then
--                y_speed <= -1;
--              else 
--                y_speed <= -to_integer(unsigned(amplitude)); 
--              end if;
           elsif shape_y_position = 0 then
              y_speed <= 1;
--              if to_integer(unsigned(amplitude)) = 0 then
--                y_speed <= 1;
--              else 
--                y_speed <= to_integer(unsigned(amplitude)); 
--              end if;
           end if;
           shape_y_position <= shape_y_position + y_speed;    
        end if;  
        
--    -- Update circle position and speed once per frame (on fsync)
--        if fsync_i = '1' then
--            -- X Speed decision (for next frame's movement)
--            -- Based on current position, determines speed for the movement that will occur in this frame update
--            if shape_center_x >= MAX_CENTER_X then
--                x_speed <= -1; 
--            elsif shape_center_x <= MIN_CENTER_X then
--                x_speed <= 1; 
--            end if;
--        shape_center_x <= shape_center_x + x_speed; 
--        end if;
        
--        if fsync_i = '1' then
--            -- Y Speed decision (for next frame's movement)
--            if shape_center_y >= MAX_CENTER_Y then
--                y_speed <= -1; 
--            elsif shape_center_y <= MIN_CENTER_Y then
--                y_speed <= 1; 
--            end if;
--        shape_center_y <= shape_center_y + y_speed;
--        end if;                    
    end if;
end process pixel_counter;

generate_bits: process(pxl_clk) 
variable dx, dy : integer;
begin
    if rising_edge(pxl_clk) then
        if active_video_i = '1' then 
            -- Calculate distance components from current pixel to circle's center
--            dx := x_coord - shape_center_x;
--            dy := y_coord - shape_center_y;
            
            -- Check if the pixel is inside the circle: (dx*dx) + (dy*dy) <= radius*radius
--            if (dx*dx + dy*dy) <= CIRCLE_RADIUS_SQ then
            if x_coord > shape_x_position and x_coord < (shape_x_position + 50) and y_coord > shape_y_position and y_coord < (shape_y_position + 50) then
                pxl_int <= x"f63f0f"; -- Circle color (Orange-ish)
            -- Draw grass
            elsif y_coord > 360 and y_coord < 460 then
                pxl_int <= x"0000dd";
            -- Draw trunk
            elsif y_coord > 300 and y_coord < 360 and x_coord < 425 and x_coord > 400 then
                pxl_int <= x"A52A2A";
            -- Draw triangle (leaves)
            elsif (y_coord >= 200 and y_coord <= 300) and                         -- Y-range check
               ( (25 * x_coord + 6 * y_coord - 11500) >= 0 ) and              -- Right of/on left edge
               ( (4 * x_coord - y_coord - 1448) <= 0 ) then                   -- Left of/on right edge
                pxl_int <= x"000066"; -- Green for leaves
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
