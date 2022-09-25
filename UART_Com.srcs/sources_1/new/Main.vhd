----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Abhilas Biswas
-- 
-- Create Date: 20.09.2022 21:38:21
-- Design Name: 
-- Module Name: Main - Behavioral
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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY Main IS
    PORT (
        sysclk : IN STD_LOGIC;
        rx : IN STD_LOGIC;
        tx : OUT STD_LOGIC
    );
END Main;

ARCHITECTURE Behavioral OF Main IS
    COMPONENT ila_0

        PORT (
            clk : IN STD_LOGIC;
            
            probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT PLL
        PORT (
            clk_out1 : OUT STD_LOGIC;
            clk_in1 : IN STD_LOGIC
        );
    END COMPONENT;
    
    COMPONENT vio_0
      PORT (
        clk : IN STD_LOGIC;
        probe_in0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    END COMPONENT;

    component UART is
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
    
    SIGNAL clk100, rx_buffer, tx_buffer : STD_LOGIC := '0';
    SIGNAL tx_probe, rx_probe, tx_trig_probe, clk_probe : STD_LOGIC_VECTOR(0 DOWNTO 0) := (others => '0');
        
    signal rd_trig_prev : std_logic := '0';
    
    type states is (poll, receive, send, delay, fetch, send2);
    
    signal state : states := receive;
    signal counter : std_logic_vector(23 downto 0) := (others => '0');
    
BEGIN
    -- rx_buffer <= rx;
    tx <= tx_buffer;
--    tx_trig <= tx_trig_probe(0);
    tx_probe(0) <= tx_buffer;
    rx_probe(0) <= rx;
    clk_probe(0) <= tx_emt;
    
    clk : PLL PORT MAP(clk100,sysclk);
    ila : ila_0 PORT MAP(clk100,tx_probe,rx_probe,data_rx,clk_probe);
--    vio : vio_0 PORT MAP (clk100,data_rx,tx_trig_probe,data_tx);
    

    uart_module: UART port map ( 
               clk => clk100, -- 100MHz
               rx => rx,
               tx => tx_buffer,
               
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
                        state <= send2;
                    when send2 =>
                        state <= poll;
                    when others =>
                end case;
                
            end if;
        end process;
END Behavioral;