----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
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
        Port ( clk    : in STD_LOGIC; -- 100MHz
               clk_out: out std_logic;
               rx     : in STD_LOGIC;
               tx     : out STD_LOGIC;
               rx_trig: out std_logic;
    
               tx_trig: in std_logic;
               tx_ack : out std_logic;
               data_rx: out std_logic_vector(7 downto 0);
               data_tx: in  std_logic_vector(7 downto 0));
    end component;
    
    signal data_rx : std_logic_vector(7 downto 0) := x"00";
    signal data_tx : std_logic_vector(7 downto 0) := (others=>'0');
    signal rx_trig, tx_trig, tx_ack , clk_out: std_logic := '0';
    
    -- signal counter : std_logic_vector (2 downto 0) := "000";
    SIGNAL clk100, rx_buffer, tx_buffer : STD_LOGIC := '0';
    SIGNAL tx_probe, rx_probe, tx_trig_probe, clk_probe : STD_LOGIC_VECTOR(0 DOWNTO 0) := (others => '0');
    -- signal sync_clk : std_logic := counter(2);
    -- signal rx_prev : std_logic := '0';
    -- signal data : std_logic_vector(7 downto 0) := x"00";
    -- signal index : integer := 0;
    -- signal index2 : std_logic_vector(5 downto 0) := "000000";
        
    signal rd_trig_prev : std_logic := '0';
    
    type states is (receive,send,delay);
    
    signal state : states := receive;
    signal counter : std_logic_vector(23 downto 0) := (others => '0');
    
    
BEGIN
    -- rx_buffer <= rx;
    tx <= tx_buffer;
--    tx_trig <= tx_trig_probe(0);
    tx_probe(0) <= tx_buffer;
    rx_probe(0) <= rx;
    clk_probe(0) <= tx_trig;
    
    clk : PLL PORT MAP(clk100,sysclk);
    ila : ila_0 PORT MAP(clk100,tx_probe,rx_probe,data_rx,clk_probe);
--    vio : vio_0 PORT MAP (clk100,data_rx,tx_trig_probe,data_tx);
    

    uart_module: UART port map ( 
               clk => clk100, -- 100MHz
               clk_out => clk_out,
               rx => rx,
               tx => tx_buffer,
               rx_trig => rx_trig,
               tx_trig => tx_trig,
               tx_ack => tx_ack,
               data_rx => data_rx,
               data_tx => data_tx);


        process (sysclk)
        begin
            if (rising_edge(sysclk)) then
                rd_trig_prev <= rx_trig;
                
                    if (rd_trig_prev /= rx_trig) then
                        data_tx <= data_rx;
                        tx_trig <= not tx_trig;
                     end if;
                
            end if;
        end process;
    
    -- process (clk64)
    -- begin
    --     if (rising_edge(clk64)) then
    --         rx_prev <= rx;
    --         if (rx_prev='1' and rx='0') then
    --             counter <= "000";
    --         else
    --             counter <= counter +1;
    --         end if;
    --     end if;
    -- end process;


    -- process (clk8)
    -- begin
    --     if (rising_edge(clk8)) then
    --         index2 <= index2 + 1;
    --         tx_buffer <= data_tx(to_integer(unsigned(index2)));
--            case state2 is
--                when state_idle =>
----                    if (rx='0') then
--                        data_tx <= x"59";
--                        tx_buffer <= '1';
--                        index <= 0;
--                        state2 <= state_receive;
----                    end if;
--                when state_receive =>
--                    if (index = 7) then
--                        state2 <= state_parity;
--                    end if;
--                    tx_buffer <= data_tx(index);
--                    -- data_tx <= "0"&data(7 downto 1);
--                    index <= index + 1;
--                when state_parity =>
--                    state2 <= state_stop;
--                    tx_buffer <= '1';
--                when state_stop =>
--                    tx_buffer <= '1';
--                    state2 <= state_idle1;
--                when state_idle1 =>
--                    tx_buffer <= '0';
--                    state2 <= state_idle;
--                when others =>
--                    state2 <= state_idle;
--            end case;
    --     end if;
    -- end process;
    
    -- process (sync_clk)
    --     begin
    --         if (rising_edge(sync_clk)) then
    --             case state is
                
    --                 when state_idle =>
    --                     if (rx='0') then
    --                         state <= state_receive;
    --                         data <= x"00";
    --                         index <= 0;
    --                     end if;
    --                 when state_receive =>
    --                     if (index = 7) then
    --                         state <= state_parity;
    --                         data_rx <= rx&data(7 downto 1);
    --                     end if;
    --                     data <= rx&data(7 downto 1);
    --                     index <= index + 1;
    --                 when state_parity =>
    --                     state <= state_idle;
    -- --                when state_stop =>
    -- --                    state <= state_idle;
    --                 when others =>
    --                     state <= state_idle;
    --             end case;
    --         end if;
    --     end process;

END Behavioral;