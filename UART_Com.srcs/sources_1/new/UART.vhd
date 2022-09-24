----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.09.2022 21:48:32
-- Design Name: 
-- Module Name: UART - Behavioral
-- Project Name: 
-- Target Devices: 
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART is
    generic(
           counter_bit : integer := 32;
           baud_rate   : real := 115200.0
    );
    Port ( clk : in STD_LOGIC; -- 100MHz
           clk_out : out std_logic;
           rx : in STD_LOGIC;
           tx : out STD_LOGIC;
           rx_trig : out std_logic;
           tx_trig : in std_logic;
           tx_ack : out std_logic; -- acknowledgement
           data_rx: out std_logic_vector(7 downto 0);
           data_tx: in  std_logic_vector(7 downto 0));
end UART;

architecture Behavioral of UART is
    COMPONENT FIFO
    PORT (
        clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
    );
    END COMPONENT;

    type states is (state_idle, state_start, state_data, state_parity);
    signal rx_state : states := state_idle;
    signal tx_state : states := state_idle;
   
    signal rx_prev, rx_trig_buffer, tx_trig_buffer, tx_trig_prev, tx_ack_buf: std_logic := '0';
    signal tx_buffer: std_logic := '1';
    signal index_rx, index_tx : integer := 0;
    signal data_rx_buffer : std_logic_vector(7 downto 0) := (others => '0');

    signal accum_rx : unsigned (counter_bit-1 downto 0) := (others => '0');
    signal accum_tx : unsigned (counter_bit-1 downto 0) := (others => '0');
    
    constant DDSMF  :     real    := 0.5 + baud_rate*(2.0**counter_bit)/100000000.0;

    signal step     : unsigned (counter_bit-1 downto 0) := to_unsigned(integer(DDSMF),counter_bit);
    signal rx_clk   : std_logic := accum_rx(counter_bit-1);
    signal tx_clk   : std_logic := accum_tx(counter_bit-1);

    

begin

    transmit_buffer : FIFO
    PORT MAP (
        clk => clk,
        din => din,
        wr_en => wr_en,
        rd_en => rd_en,
        dout => dout,
        full => full,
        empty => empty
    );
    received_buffer : FIFO
    PORT MAP (
        clk => clk,
        din => din,
        wr_en => wr_en,
        rd_en => rd_en,
        dout => dout,
        full => full,
        empty => empty
    );

    rx_trig <= rx_trig_buffer;
    tx <= tx_buffer;
    tx_ack <= tx_ack_buf;
    
    clk_out <= rx_clk;
    
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

    fetch : process( clk )
    begin
        
        
    end process ; -- fetch

    process (rx_clk)
    begin
        if (rising_edge(rx_clk)) then
            case rx_state is
                when state_idle =>
                    if (rx='0') then
                        rx_state <= state_data;
                        data_rx_buffer <= (others => '0');
                        index_rx <= 0;
                    end if;
                when state_data =>
                    if (index_rx = 7) then
                        rx_state <= state_parity;
                        data_rx <= rx&data_rx_buffer(7 downto 1);
                        rx_trig_buffer <= not rx_trig_buffer;
                    end if;
                    data_rx_buffer <= rx&data_rx_buffer(7 downto 1);
                    index_rx <= index_rx + 1;
                when state_parity =>
                    rx_state <= state_idle;
                when others =>
                    rx_state <= state_idle;
            end case;
        end if;
    end process;
        
    process (tx_clk)
    begin
        if (rising_edge(tx_clk)) then
            tx_trig_prev <= tx_trig;

            case tx_state is
                when state_idle =>

                    if (tx_trig_prev /= tx_trig) then
                        tx_buffer <= '0';
                        index_tx  <= 0;
                        tx_state  <= state_data;
                    else
                        tx_buffer <= '1';
                    end if;
                when state_data =>
                        if (index_tx < data_tx'length) then
                            tx_buffer <= data_tx(index_tx);
                            index_tx <= index_tx + 1;
                        else
                            tx_buffer <= '1'; -- stop bit
                            tx_state <= state_parity; -- or stop bit after parity bit
                        end if;
                when state_parity =>
                            tx_buffer <= '1';
                            tx_ack_buf <= not tx_ack_buf;
                            tx_state <= state_idle;
                when others =>
                        tx_state <= state_idle;
            end case;
        end if;
    end process;

end Behavioral;
