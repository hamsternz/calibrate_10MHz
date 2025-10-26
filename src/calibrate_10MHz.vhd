----------------------------------------------------------------------------------
-- calibrate_10MHz.vhd :
--
-- (c) 2025 Mike Field (hamster@snap.net.nz)
--
-- A tool to count the frequency of a 10MHz OCXO against a GPS PPS signal  
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity calibrate_10MHz is
    Port ( 
        clk_100M  : in  STD_LOGIC;
        ref_in    : in  STD_LOGIC;
        pps_in    : in  STD_LOGIC;
        uart_tx   : out STD_LOGIC
    );
end calibrate_10MHz;

architecture Behavioral of calibrate_10MHz is
    component frequency_counter is
    port (
        clk_100M        : in  STD_LOGIC;
        clk_125M        : out STD_LOGIC;
        ref_in          : in  STD_LOGIC;
        pps_in          : in  STD_LOGIC;
        freq_x100_valid : out STD_LOGIC;
        freq_x100       : out STD_LOGIC_VECTOR (31 downto 0) := STD_LOGIC_VECTOR(to_unsigned(12345678,32))
    );
    end component;

    signal clk_125M   : STD_LOGIC;

    signal freq_x100_valid : std_logic                     := '0';
    signal freq_x100_value : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1234567,32));
    
    component binary_to_decimal is
    Port ( 
        clk         : in  STD_LOGIC;
        value_valid : in  STD_LOGIC;
        value       : in  STD_LOGIC_VECTOR (31 downto 0);
        bcd_valid   : out STD_LOGIC;        
        bcd         : out STD_LOGIC_VECTOR (47 downto 0)
    );
    end component;

    signal bcd       : STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
    signal bcd_valid : STD_LOGIC                      := '0';

    component serial_interface is
    generic (
        BAUD               : natural := 115200;
        CLK_FREQ           : natural := 10000000
    );    
    Port (
        clk     : in  STD_LOGIC;
        bcd     : in  STD_LOGIC_VECTOR (47 downto 0);
        send    : in  STD_LOGIC;
        uart_tx : out STD_LOGIC
    );
    end component;
    
begin

i_frequency_counter: frequency_counter Port map ( 
        clk_100M   => clk_100M,
        clk_125M   => clk_125M, 
        ref_in     => ref_in,
        pps_in     => pps_in,
        freq_x100_valid => freq_x100_valid,
        freq_x100       => freq_x100_value
    );
    

i_binary_to_decimal: binary_to_decimal Port map ( 
        clk         => clk_125M,
        value_valid => freq_x100_valid,
        value       => freq_x100_value,
        bcd_valid   => bcd_valid,        
        bcd         => bcd
    );

    
i_serial_interface: serial_interface generic map (
        BAUD     => 115200,
        CLK_FREQ => 125*1000*1000
    ) port map (
        clk     => clk_125M,
        bcd     => bcd,
        send    => bcd_valid,
        uart_tx => uart_tx
    );
    
end Behavioral;
