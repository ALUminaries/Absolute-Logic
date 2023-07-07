-------------------------------------------------------------------------------------
-- invert_look_ahead.vhd
-------------------------------------------------------------------------------------
-- Authors:     Riley Jackson, Maxwell Phillips (revision)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Group logic block handling 4 PFAs or lower-level ILAs.
-------------------------------------------------------------------------------------
-- Ports
-------------------------------------------------------------------------------------
--
-- [c_in] Input carry.
--
-- [prop_in_i] Input prop_out signals from PFAs or lower-level ILAs.
--
-- [c_out_i] Carry out signals to PFAs or lower-level ILAs.
--
-- [prop_group] Determines whether this group is capable of propagating a carry.
--
-------------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity invert_look_ahead is
  port (
    c_in       : in    std_logic; -- previously `i`
    prop_in_0  : in    std_logic; -- prev. `a0`
    prop_in_1  : in    std_logic; -- prev. `a1`
    prop_in_2  : in    std_logic; -- prev. `a2`
    prop_in_3  : in    std_logic; -- prev. `a3`
    c_out_0    : out   std_logic; -- prev. `i0`
    c_out_1    : out   std_logic; -- prev. `i1`
    c_out_2    : out   std_logic; -- prev. `i2`
    c_out_3    : out   std_logic; -- prev. `i3`
    prop_group : out   std_logic  -- prev. `i4_0`
  );
end invert_look_ahead;

architecture behavioral of invert_look_ahead is

begin

  c_out_0    <= c_in;
  c_out_1    <= c_in or prop_in_0;
  c_out_2    <= c_in or prop_in_0 or prop_in_1;
  c_out_3    <= c_in or prop_in_0 or prop_in_1 or prop_in_2;
  prop_group <= prop_in_0 or prop_in_1 or prop_in_2 or prop_in_3;

end architecture behavioral;
