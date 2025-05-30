

-- Does not work with current implementation because sim only sends tlast but here we just use a counter

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity fft_axi_rx is
    port (
    s_axis_clk          : IN STD_LOGIC;
    s_axis_resetn       : IN STD_LOGIC;
    s_axis_data_tdata   : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    s_axis_data_tuser   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_data_tvalid  : IN STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tlast   : IN STD_LOGIC;
    
    peak_bin            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
end fft_axi_rx;

architecture Behavioral of fft_axi_rx is

signal peak_bin_int :  STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
signal peak_freq_mag_int :  STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');

signal max_mag_var :  unsigned(47 downto 0) := (others => '0');
signal peak_bin_var :  STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');

signal half_counter : integer := 0;

begin


s_axis_data_tready <= '1';

process(s_axis_clk)
    variable mag_temp     : unsigned(47 downto 0);
begin
    if rising_edge(s_axis_clk) then
        if s_axis_resetn = '0' then
            half_counter      <= 0;
            peak_bin_int      <= (others => '0');
            max_mag_var       <= (others => '0');
            peak_bin_var      <= (others => '0');

        elsif s_axis_data_tvalid = '1' then    
            mag_temp := 
                unsigned(signed(s_axis_data_tdata(23 downto 0)) * signed(s_axis_data_tdata(23 downto 0))) +
                unsigned(signed(s_axis_data_tdata(47 downto 24)) * signed(s_axis_data_tdata(47 downto 24)));
            
            if half_counter < 255 then -- Switch to only counting in real half 
                half_counter <= half_counter + 1;
                if mag_temp > max_mag_var then
                    max_mag_var  <= mag_temp;
                    peak_bin_var <= s_axis_data_tuser(7 downto 0);
                end if;
            elsif half_counter = 255 then
                if mag_temp > max_mag_var then
                    peak_bin_int      <= s_axis_data_tuser(7 downto 0); -- Only pull real half side of tuser bins
                else              
                    peak_bin_int      <= peak_bin_var;
                end if;
                max_mag_var  <= (others => '0');
                peak_bin_var <= (others => '0');
                half_counter      <= 0;
            else
                max_mag_var  <= (others => '0');
                peak_bin_var <= (others => '0');
                half_counter      <= 0;
            end if;    
        end if;
    end if;
end process; 



peak_bin <= peak_bin_int;

end Behavioral;