----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Abhilas Biswas
-- 
-- Create Date: 23.09.2022 21:48:32
-- Design Name: 
-- Module Name: UART - Behavioral
-- Project Name: 
-- Target Devices: cmod A7 35T, Can be used as general component
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity UART is
    -- For setting the baud rate
    generic(
           counter_bit : integer := 32;
           baud_rate   : real := 115200.0
    );
    Port ( clk : in STD_LOGIC; -- 100MHz
           rx : in STD_LOGIC;
           tx : out STD_LOGIC;
           
           rx_rd_clk : in std_logic; -- acknowledgement
           tx_wr_clk : in std_logic;
           rd_en     : in std_logic;
           wr_en     : in std_logic;
           rx_emt : out std_logic;
           tx_emt : out std_logic;

           data_rx: out std_logic_vector(7 downto 0);
           data_tx: in  std_logic_vector(7 downto 0));
end UART;

architecture Behavioral of UART is
    -- Input and Output Queue, This is an IP provided by Vivado
    COMPONENT FIFO
    PORT (
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
      );
    END COMPONENT;
    
    -- Different states of Transfer and Receiver state machine
    type states is (state_idle, state_start, state_data, state_parity,state_fetch,state_delay);
    signal rx_state : states := state_idle;
    signal tx_state : states := state_idle;
   
    signal rx_prev: std_logic := '0';
    signal tx_buffer: std_logic := '1';
    signal index_rx, index_tx : integer := 0;
    signal data_rx_buffer, data_tx_buffer : std_logic_vector(7 downto 0) := (others => '0');
    signal data_rx_temp, data_tx_temp : std_logic_vector(7 downto 0) := (others => '0');

    signal accum_rx : unsigned (counter_bit-1 downto 0) := (others => '0');
    signal accum_tx : unsigned (counter_bit-1 downto 0) := (others => '0');
    -- Baudrate clock genration
    constant DDSMF  :     real    := 0.5 + baud_rate*(2.0**counter_bit)/100000000.0;

    signal step     : unsigned (counter_bit-1 downto 0) := to_unsigned(integer(DDSMF),counter_bit);
    signal rx_clk   : std_logic := accum_rx(counter_bit-1);
    signal tx_clk   : std_logic := accum_tx(counter_bit-1);

    signal tx_wr_en, tx_rd_en, rx_wr_en, rx_rd_en : std_logic := '0';
    signal tx_empty, rx_empty : std_logic := '0';

begin
    -- Transmitter Queue
    transmit_buffer : FIFO
    PORT MAP (
        wr_clk => tx_wr_clk,
        rd_clk => tx_clk,
        din => data_tx,
        wr_en => tx_wr_en,
        rd_en => tx_rd_en,
        dout => data_tx_buffer,
        full => open,
        empty => tx_empty
    );
    -- Receiver Queue
    received_buffer : FIFO
    PORT MAP (
        wr_clk => rx_clk,
        rd_clk => rx_rd_clk,
        din => data_rx_buffer,
        wr_en => rx_wr_en,
        rd_en => rx_rd_en,
        dout => data_rx,
        full => open,
        empty => rx_empty
    );

    tx <= tx_buffer;
    
    rx_emt <= rx_empty;
    tx_emt <= tx_empty;
    
    tx_wr_en <= wr_en;
    rx_rd_en <= rd_en;
    
    -- Baud rate and synchronised rx clock generator
    process (clk)
    begin
        if (rising_edge(clk)) then
            rx_prev <= rx;
            accum_tx <= accum_tx + step;
            if (rx_prev='1' and rx='0') then
                accum_rx <= (others => '0');
            else
                accum_rx <= accum_rx + step;
            end if;
        end if;
    end process;

    -- Receiver State machine
    process (rx_clk)
    begin
        if (rising_edge(rx_clk)) then
            case rx_state is
                when state_idle =>
                    if (rx='0') then
                        rx_state <= state_data;
                        data_rx_temp <= (others => '0');
                        index_rx <= 0;
                    end if;
                when state_data =>
                    if (index_rx = 7) then
                        data_rx_buffer <= rx&data_rx_temp(7 downto 1);
                        rx_wr_en <= '1';
                        rx_state <= state_parity;
                    end if;
                    data_rx_temp <= rx&data_rx_temp(7 downto 1);
                    index_rx <= index_rx + 1;
                when state_parity =>
                    rx_wr_en <= '0';
                    rx_state <= state_idle;
                when others =>
                    rx_state <= state_idle;
            end case;
        end if;
    end process;
    
    -- Transmitter State Machine
    process (tx_clk)
    begin
        if (rising_edge(tx_clk)) then
            case tx_state is
                when state_idle =>
                    tx_buffer <= '1';
                    if (tx_empty = '0') then
                        index_tx <= 0;
                        tx_rd_en <= '1';
                        tx_state  <= state_start;   
                    end if;
                when state_start =>
                        tx_rd_en <= '0';
                        tx_state  <= state_delay;
                when state_delay =>
                        data_tx_temp <= data_tx_buffer;
                        tx_state  <= state_data;
                        tx_buffer <= '0';
                when state_data =>
                        if (index_tx < data_tx'length) then
                            tx_buffer <= data_tx_temp(index_tx);
                            index_tx <= index_tx + 1;
                        else
                            tx_buffer <= '1'; -- stop bit
                            tx_state <= state_parity; -- or stop bit after parity bit
                        end if;
                when state_parity =>
                            tx_buffer <= '1';
                            tx_state <= state_idle;
                when others =>
                        tx_state <= state_idle;
            end case;
        end if;
    end process;

end Behavioral;
