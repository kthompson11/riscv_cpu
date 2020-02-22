----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/07/2019 08:42:31 AM
-- Design Name: 
-- Module Name: clocking_unit - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clocking_unit is
   port (
      -- input clock
      input_clk    : in     std_logic;
      
      -- output clocks
      sys_clk        : out    std_logic;
      mem_ref_clk    : out    std_logic;
      
      -- clk status
      clk_locked     : out    std_logic
   );
end clocking_unit;

architecture Behavioral of clocking_unit is
   signal sys_clk_unbuffered, mem_ref_unbuffered : std_logic;
   signal buffered_input : std_logic;
   signal freq_synth_fb : std_logic;
begin
   -- IBUFG -> jitter filter -> freq synthesis -> BUFG
   -- omit jitter filter unless needed
   
   freq_synthesis_pll : PLLE2_BASE
      generic map (
         BANDWIDTH => "OPTIMIZED",  -- OPTIMIZED, HIGH, LOW
         CLKFBOUT_MULT => 14, --10,        -- Multiply value for all CLKOUT, (2-64)
         CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB, (-360.000-360.000).
         CLKIN1_PERIOD => 10.0,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
         -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
         CLKOUT0_DIVIDE => 18, --12,
         CLKOUT1_DIVIDE => 7, --5,
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
         -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
         CLKOUT0 => sys_clk_unbuffered,   -- 1-bit output: CLKOUT0
         CLKOUT1 => mem_ref_unbuffered,   -- 1-bit output: CLKOUT1
         CLKOUT2 => open,                 -- 1-bit output: CLKOUT2
         CLKOUT3 => open,                 -- 1-bit output: CLKOUT3
         CLKOUT4 => open,                 -- 1-bit output: CLKOUT4
         CLKOUT5 => open,                 -- 1-bit output: CLKOUT5
         -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
         CLKFBOUT => freq_synth_fb,       -- 1-bit output: Feedback clock
         LOCKED => clk_locked,            -- 1-bit output: LOCK
         CLKIN1 => buffered_input,           -- 1-bit input: Input clock
         -- Control Ports: 1-bit (each) input: PLL control ports
         PWRDWN => '0',                   -- 1-bit input: Power-down
         RST => '0',                      -- 1-bit input: Reset
         -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
         CLKFBIN => freq_synth_fb         -- 1-bit input: Feedback clock
      );
   
   input_clk_bufg : BUFG
   port map (
      O => buffered_input,
      I => input_clk
   );
   
   sys_clk_bufg : BUFG
      port map (
         O => sys_clk,
         I => sys_clk_unbuffered
      );
   
   mem_ref_bufg : BUFG
      port map (
         O => mem_ref_clk,
         I => mem_ref_unbuffered
      );

end Behavioral;
