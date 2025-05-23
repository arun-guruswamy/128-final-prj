

-- Testbench for the fft axi rx
-- real = 50, imag = 50
-- mag² = 50² + 50² = 2500 + 2500 = 5000

-- Should see: Peak magnitude (squared) = 5000


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_fft_axi_rx is
end tb_fft_axi_rx;

architecture tb of tb_fft_axi_rx is

-- DUT input signals
signal s_axis_clk         : std_logic := '0';
signal s_axis_resetn      : std_logic := '0';
signal s_axis_data_tdata  : std_logic_vector(47 downto 0) := (others => '0');
signal s_axis_data_tuser  : std_logic_vector(15 downto 0) := (others => '0');
signal s_axis_data_tvalid : std_logic := '0';
signal s_axis_data_tlast  : std_logic := '0';

signal test1 : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(5, 24)) & std_logic_vector(to_signed(10, 24));
signal test2 : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(20, 24)) & std_logic_vector(to_signed(30, 24));
signal test3 : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(50, 24)) & std_logic_vector(to_signed(50, 24));
signal test4 : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(2, 24)) & std_logic_vector(to_signed(5, 24));
signal test5 : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(1, 24)) & std_logic_vector(to_signed(3, 24));

-- PEAK FIRST
signal test1_peak_first : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(70, 24)) & std_logic_vector(to_signed(70, 24));  -- mag² = 9800
signal test2_peak_first : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(10, 24)) & std_logic_vector(to_signed(5, 24));   -- mag² = 125
signal test3_peak_first : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(20, 24)) & std_logic_vector(to_signed(15, 24));  -- mag² = 625
signal test4_peak_first : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(1, 24)) & std_logic_vector(to_signed(1, 24));    -- mag² = 2

-- PEAK LAST
signal test1_peak_last : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(5, 24)) & std_logic_vector(to_signed(2, 24));    -- mag² = 29
signal test2_peak_last : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(10, 24)) & std_logic_vector(to_signed(15, 24));  -- mag² = 325
signal test3_peak_last : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(30, 24)) & std_logic_vector(to_signed(25, 24));  -- mag² = 1525
signal test4_peak_last : std_logic_vector(47 downto 0) := std_logic_vector(to_signed(68, 24)) & std_logic_vector(to_signed(68, 24));  -- mag² = 9800 (peak)


-- DUT output signals
signal s_axis_data_tready : std_logic;
signal peak_freq_mag      : std_logic_vector(31 downto 0) := (others => '0');

component fft_axi_rx is
    port (
        s_axis_clk         : in  std_logic;
        s_axis_resetn      : in  std_logic;
        s_axis_data_tdata  : in  std_logic_vector(47 downto 0);
        s_axis_data_tuser  : in  std_logic_vector(15 downto 0);
        s_axis_data_tvalid : in  std_logic;
        s_axis_data_tready : out std_logic;
        s_axis_data_tlast  : in  std_logic;
        peak_freq_mag      : out std_logic_vector(31 downto 0)
    );
end component;

begin

-- Instantiate the DUT
uut: fft_axi_rx
    port map (
        s_axis_clk         => s_axis_clk,
        s_axis_resetn      => s_axis_resetn,
        s_axis_data_tdata  => s_axis_data_tdata,
        s_axis_data_tuser  => s_axis_data_tuser,
        s_axis_data_tvalid => s_axis_data_tvalid,
        s_axis_data_tready => s_axis_data_tready,
        s_axis_data_tlast  => s_axis_data_tlast,
        peak_freq_mag      => peak_freq_mag
    );

-- Clock generation
clk_proc: process
begin
    while true loop
        s_axis_clk <= '0';
        wait for 5 ns;
        s_axis_clk <= '1';
        wait for 5 ns;
    end loop;
end process;

stim_proc: process
begin
    -- 1. Reset
    s_axis_resetn <= '0';
    wait for 20 ns;
    s_axis_resetn <= '1';
    wait for 10 ns;

    -- === TEST 2: Peak at middle ===
    -- SAMPLE 1: small (real=10, imag=5)
    s_axis_data_tdata  <= test1;
    s_axis_data_tuser  <= std_logic_vector(to_unsigned(0, 16));
    s_axis_data_tvalid <= '1';
    s_axis_data_tlast  <= '0';
    wait until rising_edge(s_axis_clk);
    
    -- SAMPLE 2: medium (real=30, imag=20)
    s_axis_data_tdata  <= test2;
    s_axis_data_tuser  <= std_logic_vector(to_unsigned(1, 16));
    wait until rising_edge(s_axis_clk);

    -- SAMPLE 3: BIG peak (real=50, imag=50)
    s_axis_data_tdata  <= test3;
    s_axis_data_tuser  <= std_logic_vector(to_unsigned(2, 16));
    wait until rising_edge(s_axis_clk);

    -- SAMPLE 4: small (real=5, imag=2)
    s_axis_data_tdata  <= test4;
    s_axis_data_tuser  <= std_logic_vector(to_unsigned(3, 16));
    wait until rising_edge(s_axis_clk);
    
    -- SAMPLE 5: small (real=1, imag=3), last
    s_axis_data_tdata  <= test5;
    s_axis_data_tuser  <= std_logic_vector(to_unsigned(4, 16));
    s_axis_data_tlast  <= '1';
    wait until rising_edge(s_axis_clk);

    -- Deassert control signals
    s_axis_data_tvalid <= '0';
    s_axis_data_tlast  <= '0';
    -- Wait for output
    wait for 50 ns;
    
    
    -- === TEST 2: Peak at front ===
    s_axis_data_tvalid <= '1';
    s_axis_data_tlast  <= '0';
    
    s_axis_data_tdata <= test1_peak_first;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(0, 16));
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tdata <= test2_peak_first;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(1, 16));
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tdata <= test3_peak_first;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(2, 16));
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tdata <= test4_peak_first;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(3, 16));
    s_axis_data_tlast <= '1';
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tvalid <= '0';
    s_axis_data_tlast  <= '0';
    wait for 50 ns;
    
    
    -- === TEST 3: Peak at end ===
    s_axis_data_tvalid <= '1';
    s_axis_data_tlast  <= '0';
    
    s_axis_data_tdata <= test1_peak_last;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(0, 16));
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tdata <= test2_peak_last;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(1, 16));
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tdata <= test3_peak_last;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(2, 16));
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tdata <= test4_peak_last;
    s_axis_data_tuser <= std_logic_vector(to_unsigned(3, 16));
    s_axis_data_tlast <= '1';
    wait until rising_edge(s_axis_clk);
    
    s_axis_data_tvalid <= '0';
    s_axis_data_tlast  <= '0';
    wait for 50 ns;
    

    wait;
end process;



end tb;
