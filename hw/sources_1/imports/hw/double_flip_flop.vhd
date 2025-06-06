

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity double_flip_flop is
    Port (
        clk_i   : in   std_logic;
        async_data_i    : in   std_logic_vector(24-1 downto 0);
        sync_data_o     : out   std_logic_vector(24-1 downto 0));
end double_flip_flop;

architecture Behavioral of double_flip_flop is

signal reg_metastable   : std_logic_vector(24-1 downto 0) := (others => '0');

begin

sync_process: process(clk_i)
begin
    if rising_edge(clk_i) then
        reg_metastable <= async_data_i;
        sync_data_o <= reg_metastable;
    end if;
end process;

end Behavioral;