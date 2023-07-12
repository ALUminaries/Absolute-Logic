-------------------------------------------------------------------------------------
-- partial_full_inverter.vhd
-------------------------------------------------------------------------------------
-- Authors:     Riley Jackson, Maxwell Phillips (revision)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Modified partial full adder for use with invert-look-ahead logic.
-------------------------------------------------------------------------------------
-- Ports
-------------------------------------------------------------------------------------
--
-- [a_sign]: The sign bit of the value being processed by the top-level logic.
--
-- [a_i]: The individual input bit, i.e., the addend.
--
-- [carry_in], [sum_out]: Self explanatory.
--
-- [prop_out]: Determines whether this bit slice is capable of propagating a carry.
--
-------------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity partial_full_inverter is
  port (
    a_sign   : in    std_logic; -- prev. `An`
    a_i      : in    std_logic; -- prev. `Ain`
    carry_in : in    std_logic; -- prev. `Iin`
    sum_out  : out   std_logic; -- prev. `O`
    prop_out : out   std_logic  -- prev. `Aout`
  );
end entity partial_full_inverter;

architecture behavioral of partial_full_inverter is

begin

  prop_out <= a_i;
  sum_out  <= a_i xor (carry_in and a_sign);

end architecture behavioral;
