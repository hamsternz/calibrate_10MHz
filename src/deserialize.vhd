----------------------------------------------------------------------------------

-- frequency_counter.vhd :
--
-- (c) 2025 Mike Field (hamster@snap.net.nz)
--
-- Smaple the incoming serial bitstreams at 1GS/s.
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity deserialize is
    port (
        clk_100M          : in  STD_LOGIC;
        clk_125M          : out STD_LOGIC;
        ref_in            : in  STD_LOGIC;
        pps_in            : in  STD_LOGIC;
        ref_oversampled   : out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
        pps_oversampled   : out STD_LOGIC_VECTOR(7 downto 0) := (others => '0')
    );
end deserialize;

architecture Behavioral of deserialize is

    signal clk_125M_internal : std_logic;
    signal pps_in_sync       : std_logic := '0';
    signal ref_in_sync       : std_logic := '0';

    signal clk_fb            : std_logic;
    signal pps               : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal ref               : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    
    signal clk_hs            : std_logic;
    signal locked            : std_logic;
    signal reset             : std_logic;
begin
    clk_125M <= clk_125M_internal;
    ref_oversampled <= ref;
    pps_oversampled <= pps; 
    reset           <= not locked;


pps_ISERDESE2_inst : ISERDESE2
   generic map (
      DATA_RATE         => "DDR",
      DATA_WIDTH        => 8,
      DYN_CLKDIV_INV_EN => "FALSE",
      DYN_CLK_INV_EN    => "FALSE",
      INIT_Q1           => '0',
      INIT_Q2           => '0',
      INIT_Q3           => '0',
      INIT_Q4           => '0',
      INTERFACE_TYPE    => "NETWORKING",
      IOBDELAY          => "NONE",
      NUM_CE            => 1,
      OFB_USED          => "FALSE",          -- Select OFB path (FALSE, TRUE)
      SERDES_MODE       => "MASTER",      -- MASTER, SLAVE
      SRVAL_Q1          => '0',
      SRVAL_Q2          => '0',
      SRVAL_Q3          => '0',
      SRVAL_Q4          => '0'
   )
   port map (
      O             => open,
      
      Q1            => pps(0),
      Q2            => pps(1),
      Q3            => pps(2),
      Q4            => pps(3),
      Q5            => pps(4),
      Q6            => pps(5),
      Q7            => pps(6),
      Q8            => pps(7),
      
      SHIFTOUT1     => open,
      SHIFTOUT2     => open,
      BITSLIP       => '0',
      CE1           => '1',
      CE2           => '1',
      CLKDIVP       => '0',
      CLK           => clk_hs,       
      CLKB          => not clk_hs,   
      CLKDIV        => clk_125M_internal,
      OCLKB         => '0',          
      
      OCLK          => '0', 
      DYNCLKDIVSEL  => '0', 
      DYNCLKSEL     => '0',
      D             => pps_in,
      DDLY          => '0',
      OFB           => '0',
      RST           => reset,
      SHIFTIN1      => '0',
      SHIFTIN2      => '0'
   );

ref_ISERDESE2_inst : ISERDESE2
   generic map (
      DATA_RATE         => "DDR",
      DATA_WIDTH        => 8,
      DYN_CLKDIV_INV_EN => "FALSE",
      DYN_CLK_INV_EN    => "FALSE",
      INIT_Q1           => '0',
      INIT_Q2           => '0',
      INIT_Q3           => '0',
      INIT_Q4           => '0',
      INTERFACE_TYPE    => "NETWORKING",
      IOBDELAY          => "NONE",
      NUM_CE            => 1,
      OFB_USED          => "FALSE",          -- Select OFB path (FALSE, TRUE)
      SERDES_MODE       => "MASTER",      -- MASTER, SLAVE
      SRVAL_Q1          => '0',
      SRVAL_Q2          => '0',
      SRVAL_Q3          => '0',
      SRVAL_Q4          => '0'
   )
   port map (
      O             => open,
      
      Q1            => ref(0),
      Q2            => ref(1),
      Q3            => ref(2),
      Q4            => ref(3),
      Q5            => ref(4),
      Q6            => ref(5),
      Q7            => ref(6),
      Q8            => ref(7),
      
      SHIFTOUT1     => open,
      SHIFTOUT2     => open,
      BITSLIP       => '0',
      CE1           => '1',
      CE2           => '1',
      CLKDIVP       => '0',
      CLK           => clk_hs,       
      CLKB          => not clk_hs,   
      CLKDIV        => clk_125M_internal,
      OCLKB         => '0',          
      
      OCLK          => '0', 
      DYNCLKDIVSEL  => '0', 
      DYNCLKSEL     => '0',
      D             => ref_in,
      DDLY          => '0',
      OFB           => '0',
      RST           => reset,
      SHIFTIN1      => '0',
      SHIFTIN2      => '0'
   );


   PLLE2_BASE_inst : PLLE2_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- OPTIMIZED, HIGH, LOW
      CLKFBOUT_MULT => 10,
      CLKFBOUT_PHASE => 0.0,
      CLKIN1_PERIOD => 10.0,
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT0_DIVIDE => 2,
      CLKOUT1_DIVIDE => 8,
      CLKOUT2_DIVIDE => 1,
      CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      DIVCLK_DIVIDE => 1,        -- Master division value, (1-56)
      REF_JITTER1 => 0.0,        -- Reference input jitter in UI, (0.000-0.999).
      STARTUP_WAIT => "FALSE"    -- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   port map (
      CLKOUT0  => clk_hs,            -- 1-bit output: CLKOUT0
      CLKOUT1  => clk_125M_internal, -- 1-bit output: CLKOUT1
      CLKOUT2  => open,              -- 1-bit output: CLKOUT2
      CLKOUT3  => open,              -- 1-bit output: CLKOUT3
      CLKOUT4  => open,              -- 1-bit output: CLKOUT4
      CLKOUT5  => open,              -- 1-bit output: CLKOUT5
      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT => clk_fb,            -- 1-bit output: Feedback clock
      LOCKED   => locked,            -- 1-bit output: LOCK
      CLKIN1   => clk_100M,          -- 1-bit input: Input clock
      -- Control Ports: 1-bit (each) input: PLL control ports
      PWRDWN   => '0',               -- 1-bit input: Power-down
      RST      => '0',               -- 1-bit input: Reset
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN  => clk_fb
   );


end Behavioral;
