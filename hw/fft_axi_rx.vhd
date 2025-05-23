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
    
    peak_freq_mag       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    peak_bin            : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
    );
end fft_axi_rx;

architecture Behavioral of fft_axi_rx is

signal peak_bin_int :  STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
signal peak_freq_mag_int :  STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');

begin


s_axis_data_tready <= '1';

process(s_axis_clk)
    variable mag_temp     : unsigned(47 downto 0);
    variable max_mag_var  : unsigned(47 downto 0);
    variable peak_bin_var : std_logic_vector(8 downto 0);
begin
    if rising_edge(s_axis_clk) then
        if s_axis_resetn = '0' then
            peak_freq_mag_int <= (others => '0');
            peak_bin_int      <= (others => '0');
            max_mag_var       := (others => '0');
            peak_bin_var      := (others => '0');

        elsif s_axis_data_tvalid = '1' then
            
            mag_temp := 
                unsigned(signed(s_axis_data_tdata(23 downto 0)) * signed(s_axis_data_tdata(23 downto 0))) +
                unsigned(signed(s_axis_data_tdata(47 downto 24)) * signed(s_axis_data_tdata(47 downto 24)));

            if mag_temp > max_mag_var then
                max_mag_var  := mag_temp;
                peak_bin_var := s_axis_data_tuser(8 downto 0);
            end if;

            if s_axis_data_tlast = '1' then
                peak_freq_mag_int <= std_logic_vector(max_mag_var(31 downto 0));  -- top 32 bits
                peak_bin_int      <= peak_bin_var;
                max_mag_var       := (others => '0');
                peak_bin_var      := (others => '0');
            end if;
        end if;
    end if;
end process;



peak_bin <= peak_bin_int;
peak_freq_mag <= peak_freq_mag_int;

end Behavioral;