library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;     
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

type gather_state_t is (IDLE, FETCH, APPLY);
signal gather_state : gather_state_t := IDLE;
signal gather_index_reg1, gather_index_reg2 : integer range 0 to 511 := 0;
signal raw_sample_reg : std_logic_vector(23 downto 0);
signal han_addr_i : STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
signal han_o : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');

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


COMPONENT blk_mem_gen_HanWindow
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;
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
    
HanWindow : blk_mem_gen_HanWindow
  PORT MAP (
    clka => s00_axis_aclk,
    addra => han_addr_i,
    douta => han_o
  );
----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------  
process(s00_axis_aclk)
    variable sample      : signed(23 downto 0);
    variable coeff       : signed(23 downto 0);
    variable sample_ext  : signed(47 downto 0);
    variable coeff_ext   : signed(47 downto 0);
    variable product     : signed(47 downto 0);
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

                    case gather_state is

                        when IDLE =>
                            if fifo_empty = '0' then
                                -- Start ROM access
                                han_addr_i        <= std_logic_vector(to_unsigned(gather_index, 9));
                                gather_index_reg1 <= gather_index;
                                raw_sample_reg    <= read_data_int(31 downto 8);  -- Extract 24-bit audio
                                gather_state      <= FETCH;
                            end if;
                    
                        when FETCH =>
                            -- Wait 1st ROM latency cycle
                            gather_index_reg2 <= gather_index_reg1;
                            gather_state      <= APPLY;
                    
                        when APPLY =>
                            -- Wait 2nd ROM latency cycle, multiply with coeff, store in buffer
                    
                            sample     := signed(raw_sample_reg);
                            coeff      := signed(han_o);
                            sample_ext := "000000000000000000000000" & sample;
                            coeff_ext  := "000000000000000000000000" & coeff;
                            product    := sample_ext * coeff_ext;
                            
                            --product := product * ("000000000000000000000000" & coeff);
                            
                    
                            buffer_array(gather_index_reg2)(31 downto 8) <= std_logic_vector(product(46 downto 23));
                            buffer_array(gather_index_reg2)(7 downto 0)  <= (others => '0');  -- zero out LSBs for safety
                    
                            if gather_index = 511 then
                                gather_index  <= 0;
                                frame_ready   <= '1';
                                current_state <= STREAM;
                                gather_state  <= IDLE;
                            else
                                gather_index  <= gather_index + 1;
                                frame_ready   <= '0';
                                gather_state  <= IDLE;
                            end if;
                    
                    end case;


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