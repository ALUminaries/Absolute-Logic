-------------------------------------------------------------------------------------
-- abs_2c_look_ahead_512.vhd
-------------------------------------------------------------------------------------
-- Authors:     Riley Jackson, Maxwell Phillips (generalization and revision)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Primary absolute value logic based on carry-look-ahead structure.
--              This '2c' version takes an input sign.
-- Precision:   512 bits
-------------------------------------------------------------------------------------
--
-- Finds the sign and magnitude of a two's complement input.
-- Takes one slow clock cycle (`hw_clk`) to complete.
-- The only difference between this '2c' version and the standard (sign/mag) version
-- is that this version takes the sign as input directly instead of taking the MSB of the input.
--
-------------------------------------------------------------------------------------
-- Generics
-------------------------------------------------------------------------------------
--
-- [G_n]: Size of parallel input.
--
-- [G_levels]: Number of levels of invert look-ahead logic below the top level.
--             Not used directly, but exists for clarity.
--
-- [G_l0_size]: Equal to the smallest power of 4 larger than [G_n].
--
-- [G_li_size]: Set of [G_levels] generics used to frame each level of logic.
--              i = 0..[G_levels]
--
-------------------------------------------------------------------------------------
-- Ports
-------------------------------------------------------------------------------------
--
-- [input_sign]: Input sign for sign-and-magnitude representation.
--
-- [input]: Parallel data input (magnitude).
--
-- [output]: Sign extended two's complement output ([G_n] + 1 bits!)
--
-- [prop_out]: Output from top level ILA. Not strictly necessary for use.
--
-------------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity abs_2c_look_ahead_512 is
  generic (
    G_n       : integer := 512; -- Input length is n
    G_levels  : integer := 5;    -- number of levels of invert look-ahead logic below the top level
    G_l0_size : integer := 1024; -- should be equal to 4^(G_levels) and the smallest power of 4 larger than G_n
    G_l1_size : integer := 256; -- G_l0_size / 4, and so on.
    G_l2_size : integer := 64;
    G_l3_size : integer := 16;
    G_l4_size : integer := 4
  );
  port (
    input_sign : in    std_logic;
    input      : in    std_logic_vector(G_n - 1 downto 0);
    output     : out   std_logic_vector(G_n - 1 downto 0);
    prop_out   : out   std_logic
  );
end abs_2c_look_ahead_512;

architecture behavioral of abs_2c_look_ahead_512 is

  component partial_full_inverter is
    port (
      a_sign   : in    std_logic;
      a_i      : in    std_logic;
      carry_in : in    std_logic;
      sum_out  : out   std_logic;
      prop_out : out   std_logic
    );
  end component;

  component invert_look_ahead is
    port (
      c_in       : in    std_logic;
      prop_in_0  : in    std_logic;
      prop_in_1  : in    std_logic;
      prop_in_2  : in    std_logic;
      prop_in_3  : in    std_logic;
      c_out_0    : out   std_logic;
      c_out_1    : out   std_logic;
      c_out_2    : out   std_logic;
      c_out_3    : out   std_logic;
      prop_group : out   std_logic
    );
  end component;

  signal sign         : std_logic; -- the sign of the input
  signal top_prop_out : std_logic; -- the output of the top level ILA

  signal top_to_l4_carry_in : std_logic_vector(G_l4_size - 1 downto 0);
  signal l4_to_top_prop_out : std_logic_vector(G_l4_size - 1 downto 0);
  
  signal l4_to_l3_carry_in : std_logic_vector(G_l3_size - 1 downto 0);
  signal l3_to_l4_prop_out : std_logic_vector(G_l3_size - 1 downto 0);

  signal l3_to_l2_carry_in : std_logic_vector(G_l2_size - 1 downto 0);
  signal l2_to_l3_prop_out : std_logic_vector(G_l2_size - 1 downto 0);

  signal l2_to_l1_carry_in : std_logic_vector(G_l1_size - 1 downto 0); -- (C_4i..4i+3) carry in signals from L2 ILAs to L1 ILAs
  signal l1_to_l2_prop_out : std_logic_vector(G_l1_size - 1 downto 0); -- (P_4i..4i+3) group propagate signals from L1 ILAs to L2 ILAs

  signal l1_to_pfi_carry_in : std_logic_vector(G_l0_size - 1 downto 0); -- (C_i) carry in signals to L0 PFIs
  signal pfi_to_l1_prop_out : std_logic_vector(G_l0_size - 1 downto 0); -- (P_i) propagate signals from L0 PFIs

begin

  sign                  <= input_sign;        -- take sign as input directly from port
  output(0)             <= input(0);          -- LSB of output always equals LSB of input, since this bit is never flipped
  pfi_to_l1_prop_out(0) <= input(0);          -- need to pass this because it doesn't have a PFI
  prop_out              <= top_prop_out;

  -- note that the generation limit is G_n, not G_l0_size.
  -- the rest of the PFIs aren't needed, but G_l0_size is needed for other areas because of indexing.
  -- however, unnecessary things will be optimized away during implementation.
  gen_pfi : for i in 1 to (G_n - 1) generate
    pfi_i : partial_full_inverter
      port map (
        a_sign   => sign,
        a_i      => input(i),
        carry_in => l1_to_pfi_carry_in(i),
        sum_out  => output(i),
        prop_out => pfi_to_l1_prop_out(i)
      );
  end generate gen_pfi;

  gen_l1_ila : for i in 0 to (G_l1_size - 1) generate
    l1_ila_i : invert_look_ahead
      port map (
        c_in       => l2_to_l1_carry_in(i),
        prop_in_0  => pfi_to_l1_prop_out(i * 4),
        prop_in_1  => pfi_to_l1_prop_out(i * 4 + 1),
        prop_in_2  => pfi_to_l1_prop_out(i * 4 + 2),
        prop_in_3  => pfi_to_l1_prop_out(i * 4 + 3),
        c_out_0    => l1_to_pfi_carry_in(i * 4),
        c_out_1    => l1_to_pfi_carry_in(i * 4 + 1),
        c_out_2    => l1_to_pfi_carry_in(i * 4 + 2),
        c_out_3    => l1_to_pfi_carry_in(i * 4 + 3),
        prop_group => l1_to_l2_prop_out(i)
      );
  end generate gen_l1_ila;

  gen_l2_ila : for i in 0 to (G_l2_size - 1) generate
    l2_ila_i : invert_look_ahead
      port map (
        c_in       => l3_to_l2_carry_in(i),
        prop_in_0  => l1_to_l2_prop_out(i * 4),
        prop_in_1  => l1_to_l2_prop_out(i * 4 + 1),
        prop_in_2  => l1_to_l2_prop_out(i * 4 + 2),
        prop_in_3  => l1_to_l2_prop_out(i * 4 + 3),
        c_out_0    => l2_to_l1_carry_in(i * 4),
        c_out_1    => l2_to_l1_carry_in(i * 4 + 1),
        c_out_2    => l2_to_l1_carry_in(i * 4 + 2),
        c_out_3    => l2_to_l1_carry_in(i * 4 + 3),
        prop_group => l2_to_l3_prop_out(i)
      );
  end generate gen_l2_ila;

  gen_l3_ila : for i in 0 to (G_l3_size - 1) generate
    l3_ila_i : invert_look_ahead
      port map (
        c_in       => l4_to_l3_carry_in(i),
        prop_in_0  => l2_to_l3_prop_out(i * 4),
        prop_in_1  => l2_to_l3_prop_out(i * 4 + 1),
        prop_in_2  => l2_to_l3_prop_out(i * 4 + 2),
        prop_in_3  => l2_to_l3_prop_out(i * 4 + 3),
        c_out_0    => l3_to_l2_carry_in(i * 4),
        c_out_1    => l3_to_l2_carry_in(i * 4 + 1),
        c_out_2    => l3_to_l2_carry_in(i * 4 + 2),
        c_out_3    => l3_to_l2_carry_in(i * 4 + 3),
        prop_group => l3_to_l4_prop_out(i)
      );
  end generate gen_l3_ila;

  gen_l4_ila : for i in 0 to (G_l4_size - 1) generate
    l4_ila_i : invert_look_ahead
      port map (
        c_in       => top_to_l4_carry_in(i),
        prop_in_0  => l3_to_l4_prop_out(i * 4),
        prop_in_1  => l3_to_l4_prop_out(i * 4 + 1),
        prop_in_2  => l3_to_l4_prop_out(i * 4 + 2),
        prop_in_3  => l3_to_l4_prop_out(i * 4 + 3),
        c_out_0    => l4_to_l3_carry_in(i * 4),
        c_out_1    => l4_to_l3_carry_in(i * 4 + 1),
        c_out_2    => l4_to_l3_carry_in(i * 4 + 2),
        c_out_3    => l4_to_l3_carry_in(i * 4 + 3),
        prop_group => l4_to_top_prop_out(i)
      );
  end generate gen_l4_ila;

  top_ila : invert_look_ahead
    port map (
      c_in       => input(0),
      prop_in_0  => l4_to_top_prop_out(0),
      prop_in_1  => l4_to_top_prop_out(1),
      prop_in_2  => l4_to_top_prop_out(2),
      prop_in_3  => l4_to_top_prop_out(3),
      c_out_0    => top_to_l4_carry_in(0),
      c_out_1    => top_to_l4_carry_in(1),
      c_out_2    => top_to_l4_carry_in(2),
      c_out_3    => top_to_l4_carry_in(3),
      prop_group => top_prop_out
    );

end architecture behavioral;