library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rgb_transform is
    generic (
        C_VIDEO_DATA_WIDTH : integer := 24
    );
    port (
        s_axis_clk    : IN  STD_LOGIC;
        s_axis_resetn : IN  STD_LOGIC;
        peak_bin      : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        video_in      : IN  STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0);
        video_out     : OUT STD_LOGIC_VECTOR(C_VIDEO_DATA_WIDTH-1 downto 0)
    );
end rgb_transform;

architecture Behavioral of rgb_transform is

----------------- RGB Block ROM -----------------
COMPONENT blk_mem_gen_1
  PORT (
    clka   : IN  STD_LOGIC;
    ena    : IN  STD_LOGIC;
    addra  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta  : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;

type state_type is (IDLE, WAIT1, WAIT2, WRITE);
signal state : state_type := IDLE;

signal addra         : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
signal douta         : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
signal video_out_reg : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');

begin

----------------- RGB Block ROM PORT MAP -----------------
rom_inst : blk_mem_gen_1
  PORT MAP (
    clka   => s_axis_clk,
    ena    => '1',
    addra  => addra,
    douta  => douta
  );

----------------- Color Assignment Process -----------------
process(s_axis_clk)
begin
    if rising_edge(s_axis_clk) then
        if s_axis_resetn = '0' then
            state           <= IDLE;
            addra           <= (others => '0');
            video_out_reg   <= (others => '0');
        else
            case state is
                when IDLE =>
                    if video_in /= x"000000" then
                        addra <= peak_bin(7 downto 0);
                        state <= WAIT1;
                    else
                        video_out_reg <= video_in;
                        state <= IDLE;
                    end if;

                when WAIT1 =>
                    state <= WAIT2;

                when WAIT2 =>
                    state <= WRITE;

                when WRITE =>
                    video_out_reg <= douta;
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end if;
end process;

video_out <= video_out_reg;

end Behavioral;
