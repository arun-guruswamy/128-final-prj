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
        fsync_i : IN STD_LOGIC_VECTOR(0 DOWNTO 0);  -- high only when active frame is drawing
        vsync_i : std_logic;
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

type state_type is (IDLE_fsync, IDLE, WAIT1, WAIT2);
signal state : state_type := IDLE;

signal addra         : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
signal douta         : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
signal video_out_reg : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
signal latch_ready      : STD_LOGIC := '0';
signal fsync_int : std_logic := '0';
signal fsync_prev      : std_logic := '0';

signal frame_counter : integer range 0 to 255 := 0;
signal update_enable : std_logic := '0';


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
        if s_axis_resetn = '0' or not(mute_en_not) = '1' then
            state           <= IDLE;
            video_out_reg   <= video_in;
            latch_ready     <= '0';
        else
            case state is
                when IDLE_fsync =>
                    if fsync_int = '1' then
                        state <= IDLE;
                    end if;
                when IDLE => 
                    if video_in /= x"000000" then
                        if latch_ready = '0' and update_enable = '1' then
                            -- First non black pixel of frame
                            addra       <= peak_bin(7 downto 0);
                            latch_ready <= '1';
                            update_enable <= '0';
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

                when WAIT1 =>
                    state <= WAIT2;

                when WAIT2 =>
                    state <= IDLE;

                when others =>
                    state <= IDLE_fsync;
            end case;

            -- Reset latch_ready when video goes inactive
            if vsync_i = '0' then
                if frame_counter = 12 then  -- ~0.5s at 48 fps
                    latch_ready   <= '0';
                    update_enable <= '1';
                    frame_counter <= 0;
                    state         <= IDLE_fsync;
                else
                    update_enable <= '0';
                    frame_counter <= frame_counter + 1;
                end if;
            end if;

        end if;
    end if;
end process;

process(s_axis_clk)
begin
  if rising_edge(s_axis_clk) then
    fsync_int <= '0';
    if fsync_i(0) = '1' and fsync_prev = '0' then
      fsync_int <= '1';
    end if;
    fsync_prev <= fsync_i(0);
  end if;
end process;


video_out <= video_out_reg;

end Behavioral;