----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: FIFO buffer with AXI stream valid signal
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity fifo is
Generic (
    FIFO_DEPTH : integer := 1024;
    DATA_WIDTH : integer := 32);
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
end fifo;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of fifo is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
type mem_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal fifo_buf : mem_type := (others => (others => '0'));

signal read_pointer, write_pointer : integer range 0 to FIFO_DEPTH-1 := 0;
signal data_count : integer range 0 to FIFO_DEPTH-1 := 0;

signal read_output : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal empty_flag : std_logic := '1';
signal full_flag : std_logic := '0';
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Processes and Logic
----------------------------------------------------------------------------
rd_data_o <= fifo_buf(read_pointer);
--empty_o <= empty_flag; 
--full_o <= full_flag;

fifo : process(clk_i)
begin
if rising_edge(clk_i) then    
    if reset_i = '1' then
        read_pointer <= 0;
        write_pointer <= 0;
        empty_flag <= '1';
        full_flag <= '0';
        data_count <= 0;
    else 
        if ((wr_en_i = '1') and (data_count /= FIFO_DEPTH-1))  then
            if write_pointer = FIFO_DEPTH-1 then 
                write_pointer <= 0;
            else 
                write_pointer <= write_pointer + 1;
            end if;    
            
            fifo_buf(write_pointer) <= wr_data_i;
            data_count <= data_count + 1;
        end if;    
          
        if ((rd_en_i = '1') and (data_count /= 0)) then
            if read_pointer = FIFO_DEPTH-1 then 
                read_pointer <= 0;
            else 
                read_pointer <= read_pointer + 1;
            end if;
              data_count <= data_count - 1;
        end if;
                  
        if ((wr_en_i = '1') and (full_flag = '0')) and ((rd_en_i = '1') and (empty_flag = '0')) then
            data_count <= data_count;
        end if;
    end if;     
end if;
end process fifo;

full_o <= '1' when data_count = FIFO_DEPTH-1 else '0';
empty_o <=  '1' when data_count = 0 else '0';

end Behavioral;