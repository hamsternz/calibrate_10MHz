----------------------------------------------------------------------------------
-- serial_interface.vhd :
--
-- (c) 2025 Mike Field (hamster@snap.net.nz)
--
-- Send a 12-digit BCD number to the serial port, with leading zero suppresion. 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_interface is
    generic (
        BAUD               : natural := 115200;
        CLK_FREQ           : natural := 10000000
    );    
    Port (
        clk     : in  STD_LOGIC;
        bcd     : in  STD_LOGIC_VECTOR (47 downto 0);
        send    : in  STD_LOGIC;
        uart_tx : out STD_LOGIC := '1'
    );
end serial_interface;

architecture Behavioral of serial_interface is
    type a_digits is array(0 to 11) of std_logic_vector(7 downto 0);
    signal digits      : a_digits                           := (others => x"30");
    
    signal output_sr   : std_logic_vector(15*10-1 downto 0) := (others => '0');
    signal accum       : unsigned(29 downto 0)              := (others => '0');
    signal busy        : unsigned(7 downto 0)               := (others => '0');
    constant all_ones  : unsigned(11 downto 0)      := (others => '1');
    signal is_zero     : unsigned(11 downto 0)      := (others => '0');
begin

process(bcd)
    begin
        for i in 0 to 11 loop
            if bcd(4*i+3 downto 4*i) = x"0" then
                is_zero(i) <= '1'; 
            else
                is_zero(i) <= '0'; 
            end if;
        end loop;
    end process;
    
process(bcd, is_zero)
    begin
        for i in 0 to 11 loop
            if unsigned(is_zero(11 downto i)) = all_ones(11 downto i) and i /= 0 then
                digits(i) <= x"20";
            else    
                digits(i) <= x"3" & bcd(4*i+3 downto 4*i);
            end if;
        end loop;
    end process;


process(clk)
    begin
        if rising_edge(clk) then
            if accum + BAUD >= CLK_FREQ then
                uart_tx <= output_sr(0);
                output_sr <= "1" & output_sr(output_sr'high downto 1);
                if busy > 0 then
                    busy  <= busy -1;
                end if;
                accum <= accum + BAUD - CLK_FREQ;
            else
                accum <= accum + BAUD;
            end if;
            if send = '1' and busy = 0 then
                output_sr( 0*10+9 downto  0*10) <= "1" & digits(11) & "0";
                output_sr( 1*10+9 downto  1*10) <= "1" & digits(10) & "0";
                output_sr( 2*10+9 downto  2*10) <= "1" & digits( 9) & "0";
                output_sr( 3*10+9 downto  3*10) <= "1" & digits( 8) & "0";
                output_sr( 4*10+9 downto  4*10) <= "1" & digits( 7) & "0";
                output_sr( 5*10+9 downto  5*10) <= "1" & digits( 6) & "0";
                output_sr( 6*10+9 downto  6*10) <= "1" & digits( 5) & "0";
                output_sr( 7*10+9 downto  7*10) <= "1" & digits( 4) & "0";
                output_sr( 8*10+9 downto  8*10) <= "1" & digits( 3) & "0";
                output_sr( 9*10+9 downto  9*10) <= "1" & digits( 2) & "0";
                output_sr(10*10+9 downto 10*10) <= "1" & x"2E" & "0";
                output_sr(11*10+9 downto 11*10) <= "1" & digits( 1) & "0";
                output_sr(12*10+9 downto 12*10) <= "1" & digits( 0) & "0";
                output_sr(13*10+9 downto 13*10) <= "1" & x"0D" & "0";
                output_sr(14*10+9 downto 14*10) <= "1" & x"0A" & "0";
                busy <= to_unsigned(output_sr'length+1, 8);
            end if; 
        end if;        
    end process;

end Behavioral;
