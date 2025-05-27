library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

library UNISIM;
use UNISIM.VComponents.all;     -- contains BUFG clock buffer

entity i2s_clock_gen is
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
		lrclk_unbuf_o     : out std_logic
		);  
end i2s_clock_gen;

architecture Behavioral of i2s_clock_gen is

signal bclk_int, lrclk_int : std_logic := '0';


component rising_clock_divider is
    Generic (CLK_DIV_RATIO : integer := 25_000_000);
    Port (  fast_clk_i : in STD_LOGIC;		  
            slow_clk_o : out STD_LOGIC); 
end component;

component falling_clock_divider is
    Generic (CLK_DIV_RATIO : integer := 25_000_000);
    Port (  fast_clk_i : in STD_LOGIC;		  
            slow_clk_o : out STD_LOGIC;
            unbuf_clk_o : out std_logic
            ); 
end component;



begin


bclk_divider : rising_clock_divider 
    generic map (   CLK_DIV_RATIO   => 4)	
    port map (      fast_clk_i      => mclk_i,		  
                    slow_clk_o      => bclk_int);
 
lrclk_divider : falling_clock_divider 
    generic map (   CLK_DIV_RATIO   => 64)	
    port map (      fast_clk_i      => bclk_int,		  
                    slow_clk_o      => lrclk_int,
                    unbuf_clk_o     => lrclk_unbuf_o);

bclk_o <= bclk_int;
lrclk_o <= lrclk_int;
            
            
mclk_forward_oddr : ODDR
    generic map( DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
                 INIT => '0', -- Initial value for Q port ('1' or '0')
                 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map (  Q => mclk_fwd_o,     -- 1-bit DDR output
                C => mclk_i,     -- 1-bit clock input
                CE => '1', -- 1-bit clock enable input
                D1 => '1', -- 1-bit data input (positive edge)
                D2 => '0', -- 1-bit data input (negative edge)
                R => '0', -- 1-bit reset input
                S => '0');

bclk_forward_oddr : ODDR
    generic map( DDR_CLK_EDGE => "SAME_EDGE",
                 INIT => '0', 
                 SRTYPE => "SYNC") 
    port map (  Q => bclk_fwd_o,    
                C => bclk_int,    
                CE => '1', 
                D1 => '1', 
                D2 => '0', 
                R => '0', 
                S => '0');
                
lrclk_adc_forward_oddr : ODDR
    generic map( DDR_CLK_EDGE => "SAME_EDGE", 
                 INIT => '0',
                 SRTYPE => "SYNC")
    port map (  Q => adc_lrclk_fwd_o,     
                C => lrclk_int,     
                CE => '1', 
                D1 => '1', 
                D2 => '0',
                R => '0', 
                S => '0');
                
lrclk_dac_forward_oddr : ODDR
    generic map( DDR_CLK_EDGE => "SAME_EDGE", 
                 INIT => '0', 
                 SRTYPE => "SYNC") 
    port map (  Q => dac_lrclk_fwd_o,     
                C => lrclk_int,   
                CE => '1', 
                D1 => '1',
                D2 => '0', 
                R => '0', 
                S => '0');        


end Behavioral;
