----------------------------------------------------------------------------------

-- binary_to_decimal.vhd :
--
-- (c) 2025 Mike Field (hamster@snap.net.nz)
--
-- Convert a 32-bit binary number to BCD
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity binary_to_decimal is
    Port ( 
        clk         : in  STD_LOGIC;
        value_valid : in  STD_LOGIC;
        value       : in  STD_LOGIC_VECTOR (31 downto 0);
        bcd_valid   : out STD_LOGIC                      := '0';        
        bcd         : out STD_LOGIC_VECTOR (47 downto 0) := (others => '0')
    );
end binary_to_decimal;

architecture Behavioral of binary_to_decimal is
    signal processing : STD_LOGIC_VECTOR (31 downto 0);
    signal count      : unsigned(5 downto 0);    
    signal converted  : STD_LOGIC_VECTOR (47 downto 0);
begin

process(clk)
    variable v_carry_in : STD_LOGIC_VECTOR (12 downto 0);
    begin
        if rising_edge(clk) then
            v_carry_in(0) := processing(processing'high);
            processing    <= processing(processing'high-1 downto 0) & "0";
            for i in 0 to 11 loop
                case converted(4*i+3 downto 4*i) is
                    when "0000" => converted(4*i+3 downto 4*i+1) <= "000"; v_carry_in(i+1) := '0';  
                    when "0001" => converted(4*i+3 downto 4*i+1) <= "001"; v_carry_in(i+1) := '0';  
                    when "0010" => converted(4*i+3 downto 4*i+1) <= "010"; v_carry_in(i+1) := '0';  
                    when "0011" => converted(4*i+3 downto 4*i+1) <= "011"; v_carry_in(i+1) := '0';  
                    when "0100" => converted(4*i+3 downto 4*i+1) <= "100"; v_carry_in(i+1) := '0';  
                    when "0101" => converted(4*i+3 downto 4*i+1) <= "000"; v_carry_in(i+1) := '1';  
                    when "0110" => converted(4*i+3 downto 4*i+1) <= "001"; v_carry_in(i+1) := '1';  
                    when "0111" => converted(4*i+3 downto 4*i+1) <= "010"; v_carry_in(i+1) := '1';  
                    when "1000" => converted(4*i+3 downto 4*i+1) <= "011"; v_carry_in(i+1) := '1';  
                    when "1001" => converted(4*i+3 downto 4*i+1) <= "100"; v_carry_in(i+1) := '1';
                    when others => converted(4*i+3 downto 4*i+1) <= "000"; v_carry_in(i+1) := '0';
                end case;
                converted(4*i) <= v_carry_in(i); 
            end loop;
             
            if count = 1 then
                bcd_valid <= '1';
                bcd       <= converted;
            else
                bcd_valid <= '0';
            end if;

            if count > 0 then
                count <= count - 1;
            end if;
            
            if value_valid = '1' then
                processing <= value;
                converted  <= (others => '0');
                count      <= to_unsigned(33,6);
            end if;
        end if;
    end process;

end Behavioral;
