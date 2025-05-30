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
        mute_en_not   : IN  STD_LOGIC;
        active_video_out : IN STD_LOGIC;  -- high only when active frame is drawing
        peak_bin      : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
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

type state_type is (IDLE, WAIT1, WAIT2);
signal state : state_type := IDLE;

signal addra         : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
signal douta         : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
signal video_out_reg : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
signal latch_ready      : STD_LOGIC := '0';


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
        if s_axis_resetn = '0' or mute_en_not = '1' then
            state           <= IDLE;
            video_out_reg   <= video_in;
            latch_ready     <= '0';
        else
            case state is
                when IDLE =>
                    if active_video_out = '1' then
                        if video_in = x"f63f0f" then
                            if latch_ready = '0' then
                                -- First non black pixel of frame
                                addra       <= peak_bin;
                                latch_ready <= '1';
                                state       <= WAIT1;
                            else
                                -- During active video, apply  color to all non black pixels
                                video_out_reg <= douta;
                                state         <= IDLE;
                            end if;
                        else
                            -- Black pixel, pass through unchanged
                            video_out_reg <= video_in;
                            state         <= IDLE;
                        end if;
                    else
                        -- Outside active video, just passthrough
                        video_out_reg <= video_in;
                        state         <= IDLE;
                    end if;

                when WAIT1 =>
                    state <= WAIT2;

                when WAIT2 =>
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;

            -- Reset latch_ready when video goes inactive
            if active_video_out = '0' then
                latch_ready <= '0';
            end if;
        end if;
    end if;
end process;


video_out <= video_out_reg;

end Behavioral;