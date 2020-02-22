-- RV32I.vhd --
-- Top level file for the CPU.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity RV32I is
port (
   clk : in    std_logic         -- the main CPU clock
   -- TODO: put in an input for external interrupts from I/O
   -- TODO: put the signal needed for the AXI4-lite interface here (used for slow peripherals like UART)
);
end RV32I;

architecture Behavioral of RV32I is

begin


end Behavioral;
