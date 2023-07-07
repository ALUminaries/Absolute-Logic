-------------------------------------------------------------------------------------
-- storage_reg_generic.vhd
-------------------------------------------------------------------------------------
-- Authors:     Riley Jackson, Nathan Hagerdorn (basis), Maxwell Phillips (revision)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Storage register configurable via generic [G_n].
-------------------------------------------------------------------------------------
-- Generics
-------------------------------------------------------------------------------------
--
-- [G_n]: Size of register/data. 
--        Must be set via `generic map` with an upper-level component.
--
-------------------------------------------------------------------------------------
-- Ports
-------------------------------------------------------------------------------------
--
-- [input]: Parallel data input.
--
-- [clk]: Register clock signal. 
--
-- [reset]: Asynchronous reset signal.
--
-- [load]: Loads data from input into register. Synchronous to [clk].
--
-- [output]: Parallel data output. Synchronous to [clk].
--
-------------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

entity storage_register is
  generic (
    G_n : integer
  );
  port (
    input  : in    std_logic_vector(G_n - 1 downto 0);
    clk    : in    std_logic;
    reset  : in    std_logic;
    load   : in    std_logic;
    output : out   std_logic_vector(G_n - 1 downto 0)
  );
end storage_register;

architecture behavioral of storage_register is

  signal data : std_logic_vector(G_n - 1 downto 0);

begin

  process (clk, reset) begin
    if (reset = '1') then
      data <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (load = '1') then
        data <= input;
      end if;
    end if;
  end process;

  output <= data;

end architecture behavioral;
