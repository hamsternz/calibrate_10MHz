----------------------------------------------------------------------------------
-- frequency_counter.vhd :
--
-- (c) 2025 Mike Field (hamster@snap.net.nz)
--
-- A cheap and chearful frequency counter to count 10MHz reference signals against 
-- Relies on the fact that each sample taking is 1ns, which is close to 0.01Hz
-- when the reference frequency is 10MHz.
--
-- For esample, 9,999,999 pulses, and a 'front porch' of 50 samples and a back 
-- porch of 30 samples is taken to be (9,999,999-1) + (50+30)/100 = 9,999,998.80 Hz  
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity frequency_counter is
    port (
        clk_100M        : in  STD_LOGIC;
        clk_125M        : out STD_LOGIC;
        ref_in          : in  STD_LOGIC;
        pps_in          : in  STD_LOGIC;
        freq_x100_valid : out STD_LOGIC                      := '0';
        freq_x100       : out STD_LOGIC_VECTOR (31 downto 0) := STD_LOGIC_VECTOR(to_unsigned(12345678,32))
    );        
end frequency_counter;

architecture Behavioral of frequency_counter is
    signal clk_125M_local : std_logic;
    signal count_test : unsigned(27 downto 0) := to_unsigned(99999990,28);
    component deserialize is
        port (
            clk_100M          : in  STD_LOGIC;
            clk_125M          : out STD_LOGIC;
            ref_in            : in  STD_LOGIC;
            pps_in            : in  STD_LOGIC;
            ref_oversampled   : out STD_LOGIC_VECTOR(7 downto 0);
            pps_oversampled   : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    signal ref_cycles_count : unsigned(31 downto 0)        := (others => '0');
    signal front_porch      : unsigned(15 downto 0)        := (others => '0');
    signal back_porch       : unsigned(15 downto 0)        := (others => '0');
    signal first_pulse_seen : std_logic := '0';


    signal pps_oversampled  : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
    signal pps_rising_edge  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal pps_edge         : STD_LOGIC := '0';
    signal pps_edge_pos     : unsigned(2 downto 0)         := (others => '0');


    signal ref_oversampled  : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
    signal ref_rising_edge  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal ref_edge         : STD_LOGIC := '0';
    signal ref_edge_pos     : unsigned(2 downto 0)         := (others => '0');

begin

    clk_125M <= clk_125M_local;
    

process(clk_125M_local)
    begin
        if rising_edge(clk_125M_local) then
            freq_x100_valid <= '0';
            if pps_edge = '0' then
                if ref_edge = '0' then
                    if first_pulse_seen = '0' then
                        front_porch <= front_porch + 8;
                    end if;                                  
                    back_porch <= back_porch + 8;
                else
                    ref_cycles_count <= ref_cycles_count + to_unsigned(100, 32);
                    back_porch <= to_unsigned(0,16) + ref_edge_pos + 1;
                    if first_pulse_seen = '0' then
                        front_porch <= front_porch + 7 - ref_edge_pos;
                        first_pulse_seen <= '1'; 
                    end if;                                                  
                end if;
            else
                if ref_edge = '0' then
                    -- Easy case - just split based on PPS edge
                    freq_x100 <= std_logic_vector(ref_cycles_count - 100 + front_porch + back_porch + 7 - pps_edge_pos);      --hig     
                    freq_x100_valid <= '1';

                    ref_cycles_count <= to_unsigned(0, 32);
                    back_porch       <= to_unsigned(0, 16) + pps_edge_pos+1;
                    front_porch      <= to_unsigned(0, 16) + pps_edge_pos+1;
                    first_pulse_seen <= '0'; 
                else
                    -- Hard case
                    if pps_edge_pos >= ref_edge_pos then
                        -- The referece edge is in the new pps windows
                        freq_x100 <= std_logic_vector(ref_cycles_count - 100 + front_porch + back_porch + 7 - pps_edge_pos);         
                        freq_x100_valid <= '1';

                        ref_cycles_count <= to_unsigned(100, 32);
                        front_porch      <= to_unsigned(0, 16) + pps_edge_pos - ref_edge_pos;  
                        back_porch       <= to_unsigned(0, 16) + ref_edge_pos + 1;  
                        first_pulse_seen <= '1'; 
                    else
                        -- The reference edge is in the old pps windows
                        freq_x100 <= std_logic_vector(ref_cycles_count + front_porch + ref_edge_pos-pps_edge_pos);         
                        freq_x100_valid <= '1';
                        
                        ref_cycles_count <= to_unsigned(0, 32);
                        front_porch      <= to_unsigned(0, 16) + pps_edge_pos+1;  
                        back_porch       <= to_unsigned(0, 16) + pps_edge_pos+1;  
                        first_pulse_seen <= '0'; 
                    end if;                 
                end if;
            end if;
        end if;
    end process;

i_deserialize: deserialize port map (
        clk_100M          => clk_100M,
        clk_125M          => clk_125M_local,
        ref_in            => ref_in,
        pps_in            => pps_in,
        ref_oversampled   => ref_oversampled(7 downto 0),
        pps_oversampled   => pps_oversampled(7 downto 0)
    );

process(clk_125M_local)
    begin
        if rising_edge(clk_125M_local) then
            pps_rising_edge <= (not pps_oversampled(8 downto 1)) AND pps_oversampled(7 downto 0); 
            ref_rising_edge <= (not ref_oversampled(8 downto 1)) AND ref_oversampled(7 downto 0); 
            ref_oversampled(8) <= ref_oversampled(0);
            pps_oversampled(8) <= pps_oversampled(0);
        end if;
    end process;

process(clk_125M_local)
    begin
        if rising_edge(clk_125M_local) then
            if pps_rising_edge(7) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "111";
            elsif pps_rising_edge(6) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "110";
            elsif pps_rising_edge(5) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "101";
            elsif pps_rising_edge(4) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "100";
            elsif pps_rising_edge(3) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "011";
            elsif pps_rising_edge(2) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "010";
            elsif pps_rising_edge(1) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "001";
            elsif pps_rising_edge(0) = '1' then
                pps_edge <= '1';
                pps_edge_pos <= "000";
            else
                pps_edge <= '0';
            end if;
            
            if ref_rising_edge(7) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "111";
            elsif ref_rising_edge(6) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "110";
            elsif ref_rising_edge(5) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "101";
            elsif ref_rising_edge(4) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "100";
            elsif ref_rising_edge(3) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "011";
            elsif ref_rising_edge(2) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "010";
            elsif ref_rising_edge(1) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "001";
            elsif ref_rising_edge(0) = '1' then
                ref_edge <= '1';
                ref_edge_pos <= "000";
            else
                ref_edge <= '0';
            end if;
        end if;
    end process;


end Behavioral;
