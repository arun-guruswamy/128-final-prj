----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: AXI Stream FIFO Controller/Responder Interface 
----------------------------------------------------------------------------
-- Library Declarations
library ieee;
use ieee.std_logic_1164.all;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fifo is
	generic (
		DATA_WIDTH	: integer	:= 32;
		FIFO_DEPTH	: integer	:= 1024
	);
	port (
	
		-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic
	);
end axis_fifo;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of axis_fifo is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------  
-- Internal signals for connecting to the FIFO instance
signal fifo_wr_en   : std_logic;
signal fifo_rd_en   : std_logic;
signal fifo_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0);
signal fifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0);
signal fifo_empty   : std_logic;
signal fifo_full    : std_logic;
signal fifo_reset   : std_logic;

-- For FFT
signal sample_count : integer range 0 to 511 := 0;
signal m00_axis_tlast_int : std_logic := '0';


----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------  
component fifo is
    Generic (
		FIFO_DEPTH : integer := FIFO_DEPTH;
        DATA_WIDTH : integer := DATA_WIDTH);
    Port ( 
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        -- Write channel
        wr_en_i     : in std_logic;
        wr_data_i   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Read channel
        rd_en_i     : in std_logic;
        rd_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Status flags
        empty_o         : out std_logic;
        full_o          : out std_logic);   
end component fifo;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------   
-- Instantiate the FIFO core
fifo_inst : fifo
    generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    )
    port map (
        clk_i       => s00_axis_aclk, 
        reset_i     => fifo_reset, 

        -- Write channel
        wr_en_i     => s00_axis_tvalid,
        wr_data_i   => s00_axis_tdata,

        -- Read channel
        rd_en_i     => fifo_rd_en,
        rd_data_o   => m00_axis_tdata,

        -- Status flags
        empty_o     => fifo_empty,
        full_o      => fifo_full
    );
----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------  

process(s00_axis_aclk)
begin
  if rising_edge(s00_axis_aclk) then
    if fifo_reset = '1' then
      sample_count       <= 0;
      m00_axis_tlast_int <= '0';
    elsif fifo_rd_en = '1' and fifo_empty = '0' then
      if sample_count = 511 then
        m00_axis_tlast_int <= '1';
        sample_count       <= 0;
      else
        m00_axis_tlast_int <= '0';
        sample_count       <= sample_count + 1;
      end if;
    else
      m00_axis_tlast_int <= '0';  -- Ensure TLAST is low when idle
    end if;
  end if;
end process;

fifo_reset <= not s00_axis_aresetn;

-- FIFO is ready to accept data if it's not full
s00_axis_tready <= (not fifo_full) and s00_axis_aresetn;

-- Write to FIFO only when input data is valid and FIFO is ready
fifo_wr_en <= s00_axis_tvalid;

-- Connect input data to FIFO write data port
fifo_wr_data <= s00_axis_tdata;

-- Output data is valid if the FIFO is not empty
m00_axis_tvalid <= (not fifo_empty) and m00_axis_aresetn;

-- Read from FIFO only when output is valid and receiver is ready
fifo_rd_en <= m00_axis_tready;

-- Pass-through TSTRB and assigned TLAST from internal signal
m00_axis_tstrb <= s00_axis_tstrb;
m00_axis_tlast <= m00_axis_tlast_int;


end Behavioral;
