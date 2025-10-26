----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/22/2025 08:51:42 AM
-- Design Name: 
-- Module Name: tb_calibrate_10MHz - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity tb_calibrate_10MHz is
end tb_calibrate_10MHz;

architecture Behavioral of tb_calibrate_10MHz is
    component  calibrate_10MHz is
    Port ( 
        clk_100M  : in  STD_LOGIC;
        ref_in    : in  STD_LOGIC;
        pps_in    : in  STD_LOGIC;
        uart_tx   : out STD_LOGIC
    );
    end component;

    signal clk_100M  : STD_LOGIC := '0';
    signal ref_in    : STD_LOGIC := '0';
    signal pps_in    : STD_LOGIC := '0';
    signal uart_tx   : STD_LOGIC;

begin

process
    begin
       clk_100M <= '1';
       wait for 5 ns;
       clk_100M <= '0';
       wait for 5 ns;       
    end process;

process
    begin
       ref_in <= '1';
       wait for 51 ns;
       ref_in <= '0';
       wait for 51 ns;       
    end process;

process
    begin
        pps_in <= '0';
        wait for 0.9 ms;
        pps_in <= '1';
        wait for 0.1 ms;        
    end process;

uut: calibrate_10MHz port map (
        clk_100M  => clk_100M,
        ref_in    => ref_in,
        pps_in    => pps_in,
        uart_tx   => uart_tx
    );

end Behavioral;
