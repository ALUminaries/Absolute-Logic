-------------------------------------------------------------------------------------
-- d_flip_flop.vhd
-------------------------------------------------------------------------------------
-- Authors:     Maxwell Phillips
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Standard D-flip-flop, designed to generate delayed 'done' signal.
-------------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

entity d_flip_flop is
  port (
    input  : in    std_logic;
    clk    : in    std_logic;
    reset  : in    std_logic; -- asynchronous
    output : out   std_logic
  );
end d_flip_flop;

architecture behavioral of d_flip_flop is

  signal value : std_logic := '0';

begin

  process (clk, reset) begin
    if (reset = '1') then
      value <= '0';
    elsif (clk'event and clk = '1') then
      value <= input;
    end if;
  end process;

  output <= value;

end architecture behavioral;
