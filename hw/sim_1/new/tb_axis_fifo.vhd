library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axis_fifo is
end tb_axis_fifo;

architecture sim of tb_axis_fifo is
  -- Constants
  constant DATA_WIDTH : integer := 32;
  constant FIFO_DEPTH : integer := 1024;
  constant CLK_PERIOD : time := 10 ns;

  -- DUT Signals
  signal clk     : std_logic := '0';
  signal rst_n   : std_logic := '0';

  -- AXI Stream slave interface
  signal s_tvalid : std_logic := '0';
  signal s_tready : std_logic;
  signal s_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal s_tlast  : std_logic := '0';

  -- AXI Stream master interface
  signal m_tvalid : std_logic;
  signal m_tready : std_logic := '1';
  signal m_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal m_tlast  : std_logic;

  -- UUT
  component axis_fifo
    generic (
      DATA_WIDTH : integer := 32;
      FIFO_DEPTH : integer := 1024
    );
    port (
      s00_axis_aclk     : in  std_logic;
      s00_axis_aresetn  : in  std_logic;
      s00_axis_tready   : out std_logic;
      s00_axis_tdata    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      s00_axis_tlast    : in  std_logic;
      s00_axis_tvalid   : in  std_logic;
      m00_axis_aclk     : in  std_logic;
      m00_axis_aresetn  : in  std_logic;
      m00_axis_tvalid   : out std_logic;
      m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
      m00_axis_tlast    : out std_logic;
      m00_axis_tready   : in  std_logic
    );
  end component;

begin
  -- Clock generation
  clk_proc : process
  begin
    while true loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  -- UUT instantiation
  uut: axis_fifo
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      FIFO_DEPTH => FIFO_DEPTH
    )
    port map (
      s00_axis_aclk     => clk,
      s00_axis_aresetn  => rst_n,
      s00_axis_tready   => s_tready,
      s00_axis_tdata    => s_tdata,
      s00_axis_tlast    => s_tlast,
      s00_axis_tvalid   => s_tvalid,
      m00_axis_aclk     => clk,
      m00_axis_aresetn  => rst_n,
      m00_axis_tvalid   => m_tvalid,
      m00_axis_tdata    => m_tdata,
      m00_axis_tlast    => m_tlast,
      m00_axis_tready   => m_tready
    );

stim_proc : process
begin
  rst_n <= '0';
  s_tvalid <= '0';
  wait for 50 ns;
  rst_n <= '1';
  wait for 20 ns;

  for i in 0 to 511 loop
    wait until rising_edge(clk);
    s_tdata <= std_logic_vector(to_unsigned(i, 24)) & x"00";
    s_tvalid <= '1';

    wait until rising_edge(clk);
    s_tvalid <= '0';

    -- Wait for ~100 cycles to simulate slower input
    for j in 1 to 100 loop
      wait until rising_edge(clk);
    end loop;
  end loop;

  wait;
end process;



end sim;
