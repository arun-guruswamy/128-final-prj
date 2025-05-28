library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_transmitter is	
        generic (
            DATA_WIDTH	: integer	:= 32;
            FIFO_DEPTH	: integer	:= 1024
        );
        Port(	
		lrclk_i : in std_logic;
		
		left_audio_data : in std_logic_vector(24-1 downto 0);
		right_audio_data : in std_logic_vector(24-1 downto 0);
		
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;

		m00_axis_tready   : in std_logic;
		
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tlast    : out std_logic
		);		
end axi_transmitter;

architecture Behavioral of axi_transmitter is

component double_flip_flop is
    Port(
        clk_i         : in  std_logic;
        async_data_i  : in  std_logic_vector(23 downto 0);
        sync_data_o   : out std_logic_vector(23 downto 0)
    );
end component;

signal right_data_sync : std_logic_vector(23 downto 0) := (others => '0');
signal data_out        : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal valid_int       : std_logic := '0';

type state_type is (idle, load, wait_latch);
signal current_state, next_state : state_type := idle;

begin

-- Synchronize right audio data
axi_ff_right : double_flip_flop
    port map (
        clk_i        => m00_axis_aclk,
        async_data_i => right_audio_data,
        sync_data_o  => right_data_sync
    );

-- FSM state register
StateUpdate: process(m00_axis_aclk)
begin
    if rising_edge(m00_axis_aclk) then
        if m00_axis_aresetn = '0' then
            current_state <= idle;
        else
            current_state <= next_state;
        end if;
    end if;
end process;

-- FSM next-state + output logic
NextStateLogic: process(current_state, m00_axis_aresetn, lrclk_i, m00_axis_tready, right_data_sync)
begin
    next_state <= current_state;
    valid_int  <= '0';

    case current_state is
        when idle =>
            if m00_axis_aresetn = '1' and lrclk_i = '1' then
                next_state <= load;
            end if;

        when load =>
            valid_int <= '1';
            if m00_axis_tready = '1' then
                data_out  <= right_data_sync & x"00";  -- 24-bit audio + 8-bit pad
                next_state <= wait_latch;
            end if;

        when wait_latch =>
            if m00_axis_aresetn = '1' and lrclk_i = '0' then
                next_state <= idle;
            end if;

        when others =>
            next_state <= idle;
    end case;
end process;

-- AXIS output assignments
m00_axis_tdata  <= data_out;
m00_axis_tvalid <= valid_int;
m00_axis_tlast  <= '0';  -- leave tlast to FIFO or external logic

end Behavioral;


