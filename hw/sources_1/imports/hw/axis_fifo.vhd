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
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
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
signal tlast_int_gather, m00_axis_tlast_int : std_logic := '0';

type buffer_state is (GATHER, STREAM);
signal current_state, next_state : buffer_state := GATHER;

type buffer_array_t is array(0 to 511) of std_logic_vector(31 downto 0);
signal buffer_array : buffer_array_t := (others => (others => '0'));


signal read_data_int, buffer_out : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal stream_switch, stream_true, m00_axis_tvalid_int : std_logic := '0';

signal gather_index : integer range 0 to 511 := 0;
signal stream_index : integer range 0 to 511 := 0;
signal frame_ready  : std_logic := '0';
signal streaming_active : std_logic := '0';
signal stream_done : std_logic := '0';



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
        wr_en_i     : in std_logic;
        wr_data_i   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_en_i     : in std_logic;
        rd_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        empty_o         : out std_logic;
        full_o          : out std_logic);   
end component fifo;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------   
fifo_inst : fifo
    generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    )
    port map (
        clk_i       => s00_axis_aclk, 
        reset_i     => fifo_reset, 
        wr_en_i     => fifo_wr_en,
        wr_data_i   => fifo_wr_data,
        rd_en_i     => fifo_rd_en,
        rd_data_o   => read_data_int,
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
            current_state        <= GATHER;
            gather_index         <= 0;
            stream_index         <= 0;
            frame_ready          <= '0';
            m00_axis_tvalid_int  <= '0';
            m00_axis_tlast_int   <= '0';
            stream_done          <= '0';
        else
            case current_state is
                when GATHER =>
                    m00_axis_tvalid_int <= '0';
                    m00_axis_tlast_int  <= '0';
                    buffer_out          <= (others => '0');
                    stream_index        <= 0;
                    stream_done         <= '0';

                    if fifo_rd_en = '1' and fifo_empty = '0' then
                        buffer_array(gather_index) <= read_data_int;

                        if gather_index = 511 then
                            gather_index  <= 0;
                            frame_ready   <= '1';
                            current_state <= STREAM;  -- immediate transition
                        else
                            gather_index  <= gather_index + 1;
                            frame_ready   <= '0';
                        end if;
                    end if;

                when STREAM =>
                    frame_ready         <= '0';
                    m00_axis_tvalid_int <= '1';
                    buffer_out          <= buffer_array(stream_index);

                    if stream_index = 511 then
                        m00_axis_tlast_int <= '1';
                        stream_done        <= '1';
                        current_state      <= GATHER;  -- switch back immediately
                        stream_index       <= 0;
                    else
                        m00_axis_tlast_int <= '0';
                        stream_index       <= stream_index + 1;
                    end if;

            end case;
        end if;
    end if;
end process;




fifo_reset <= not s00_axis_aresetn;
fifo_wr_en <= s00_axis_tvalid;
fifo_wr_data <= s00_axis_tdata;

fifo_rd_en <= '1' when (current_state = GATHER) and (fifo_empty = '0') else '0';

s00_axis_tready <= (not fifo_full) and s00_axis_aresetn;

m00_axis_tvalid <= m00_axis_tvalid_int;
m00_axis_tdata  <= buffer_out;
m00_axis_tlast  <= m00_axis_tlast_int;



end Behavioral;