-- CSR_Bus.vhd --
-- Describes a bus that enables the CSRs to be read and written to.
-- TODO: describe interface here
-- TODO: check if this type of bus is feasible or if it will be too slow

-- exceptions
--  nonexistant CSR
--  inappropriate privilege level
--  write to read-only register
--  writes to an entirely read only WIRI CSR (optional)

-- Interfacing a CSR with the CSR_Bus
--  CSR sets its data read line to high impedance by default
--  When CSR sees its address on the address line, it then
--     checks if there is sufficient priviledge to access the register
--     checks if an exception should be raised due to bad written values (if CSR a write is occuring)
--     if exception should be raised, then do nothing (exception raised automatically by weak high interrupt line)
--     if no exception is raised
--        CSR pulls exception line low
--        CSR asserts its data on its data read line
--        CSR writes new data (if a CSR write is occurring)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity CSR_Bus is
   port ( ADDRESS_IN : in std_logic_vector(11 downto 0);            -- address of selected CSR
          DATA_OUT : out std_logic_vector(31 downto 0);             -- data read from the CSR
          DATA_IN : in std_logic_vector(31 downto 0);               -- data to write to selected CSR
          
          -- CSR bus lines
          CSR_ADDRESS_LINE    : out std_logic_vector(11 downto 0);   -- bus line containing address of selected CSR
          CSR_DATA_READ_LINE  : out std_logic_vector(31 downto 0);   -- bus line containing data from selected CSR
          CSR_DATA_WRITE_LINE : out std_logic_vector(31 downto 0);   -- bus line containing data to write to selected CSR
          CSR_INT_LINE        : in std_logic;                        -- bus line indicating an illegal instruction
          csr_we_line         : out    std_logic;                    -- bus line enabling write to the selected CSR
          
          CSR_EN : in std_logic;  -- enable for csr functions
          FUNCT  : in std_logic_vector(2 downto 0);
          CSR_RS : in std_logic_vector(4 downto 0);  -- write data source register (if applicable)
          CSR_WD : in std_logic_vector(31 downto 0);  -- data to write into CSR
          INT    : out std_logic;  -- asserted to raise illegal instruction exception
          RD     : out std_logic_vector(31 downto 0));
end CSR_Bus;


architecture Behavioral of CSR_Bus is
   signal bus_address : std_logic_vector(31 downto 0);
   signal bus_data : std_logic_vector(31 downto 0);
begin
   

end Behavioral;
