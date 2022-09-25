----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Abhilas Biswas
-- 
-- Create Date: 20.09.2022 21:38:21
-- Design Name: 
-- Module Name: Main - Behavioral
-- Project Name: 
-- Target Devices: cmod A7 35T, One USB-UART bridge should be within the board, can be used to any project just by configuring the tx and rx pin.
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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;


ENTITY Main IS
    PORT (
        sysclk : IN STD_LOGIC;
        rx : IN STD_LOGIC;
        tx : OUT STD_LOGIC
    );
END Main;

ARCHITECTURE Behavioral OF Main IS
    
    COMPONENT PLL
        PORT (
            clk_out1 : OUT STD_LOGIC;
            clk_in1 : IN STD_LOGIC
        );
    END COMPONENT;
    
    component UART is
        -- I tried upto 8Mbits baud rate
        generic(
               counter_bit : integer := 32;
               baud_rate   : real := 8000000.0
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
    end component;

    signal data_rx : std_logic_vector(7 downto 0) := x"00";
    signal data_tx, data_wr : std_logic_vector(7 downto 0) := (others=>'0');
    signal rx_emt, tx_emt, rd_en , wr_en: std_logic := '0';
    
    SIGNAL clk100 : STD_LOGIC := '0';
    
    type states is (poll, receive, send, delay, fetch, done);
    
    signal state : states := receive;
    signal counter : std_logic_vector(23 downto 0) := (others => '0');
    
BEGIN
    -- UART Module need 100 MHz base clock for baud rate generation
    clk : PLL PORT MAP(clk100,sysclk);
    

    uut: UART port map ( 
               clk => clk100, -- 100MHz
               rx => rx,
               tx => tx,
               
               rx_rd_clk => sysclk,
               tx_wr_clk => sysclk,
               rd_en   => rd_en,
               wr_en   => wr_en,
               rx_emt => rx_emt,
               tx_emt => tx_emt,
    
               data_rx => data_rx,
               data_tx => data_tx);


        process (sysclk)
        begin
            if (rising_edge(sysclk)) then
                case state is
                    when poll =>
                        if (rx_emt = '0') then
                            rd_en <= '1';
                            state <= receive;
                        end if;
                    when receive =>
                        rd_en <= '0';
                        state <= delay;
                    when delay =>
                        state <= fetch;
                    when fetch =>
                        wr_en <= '1';
                        data_tx <= data_rx;
                        state <= send;
                    when send =>
                        wr_en <= '0';
                        state <= done;
                    when done =>
                        state <= poll;
                    when others =>
                end case;
                
            end if;
        end process;
END Behavioral;