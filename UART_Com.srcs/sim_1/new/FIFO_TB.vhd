----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.09.2022 12:48:47
-- Design Name: 
-- Module Name: FIFO_TB - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FIFO_TB is
--  Port ( );
end FIFO_TB;

architecture Behavioral of FIFO_TB is
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


signal data_write : std_logic_vector(7 downto 0) := x"00";
signal data_read  : std_logic_vector(7 downto 0) := x"00";
signal clk,rd_en ,emt: std_logic := '0';
signal i : integer := 0;



begin

    buf : FIFO
    PORT map (
      wr_clk => clk,
      rd_clk => clk,
      din => data_write,
      wr_en => '1',
      rd_en => rd_en,
      dout => data_read,
      full => open,
      empty => emt
    );
    clk <= not clk after 10 ns;
    
    main : process( clk )
    begin
        if rising_edge(clk) then
            i <= i + 1;
            data_write <= data_write + 1;
            
            if (emt = '0' and i<8) then
                rd_en <= '1';
            else
                rd_en <= '0';
            end if;
        end if;
    end process ; -- main


end Behavioral;
