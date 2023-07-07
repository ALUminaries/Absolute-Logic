-------------------------------------------------------------------------------------
-- abs_2c_wrapper_v3_1024.vhd
-------------------------------------------------------------------------------------
-- Authors:     Maxwell Phillips, Riley Jackson (original code), 
--              Nathan Hagerdorn (original state machine code)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Absolute value (two's complement) logic wrapper.
-- Precision:   1024 bits
-------------------------------------------------------------------------------------
--
-- Finds the two's complement of a sign and magnitude input.
-- Takes one slow clock cycle (`hw_clk`) to complete.
--
-------------------------------------------------------------------------------------
-- Generics
-------------------------------------------------------------------------------------
--
-- [G_n]: Size of the magnitude of the sign-and-magnitude input. 
--
-------------------------------------------------------------------------------------
-- Ports
-------------------------------------------------------------------------------------
--
-- [reg_clk]: Register clock signal.
--
-- [hw_clk]: Clock for absolute logic hardware.
--
-- [start]: Tells hardware to begin processing.
--
-- [reset]: Asynchronous reset signal.
--
-- [input_sign]: Input sign for sign-and-magnitude representation.
--
-- [input]: Parallel data input (magnitude).
--
-- [output]: Sign extended two's complement output ([G_n] + 1 bits!)
--
-- [done]: High once the hardware has finished processing.
--
-------------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

entity abs_2c_wrapper is
  generic (
    G_n : integer := 1024  -- Input magnitude length is n
  );
  port (
    reg_clk    : in    std_logic;
    hw_clk     : in    std_logic;
    start      : in    std_logic;
    load       : in    std_logic;
    reset      : in    std_logic;
    input_sign : in    std_logic;
    input      : in    std_logic_vector(G_n - 1 downto 0);
    output     : out   std_logic_vector(G_n downto 0); -- important! sign extended, additional bit (n + 1 not n)
    done       : out   std_logic
  );
end abs_2c_wrapper;

architecture structural of abs_2c_wrapper is

  ----------------
  -- Components --
  ----------------

  component abs_2c_look_ahead_1024 is
    port (
      input_sign : in    std_logic;
      input      : in    std_logic_vector(G_n - 1 downto 0);
      output     : out   std_logic_vector(G_n - 1 downto 0);
      prop_out   : out   std_logic
    );
  end component;

  component storage_register is
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
  end component;

  component d_flip_flop is
    port (
      input  : in    std_logic;
      clk    : in    std_logic;
      reset  : in    std_logic;
      output : out   std_logic
    );
  end component;

  --------------------
  -- Absolute Logic --
  --------------------

  signal abs_hw_input  : std_logic_vector(G_n - 1 downto 0);

begin

  done_generator : d_flip_flop
    port map (
      input  => start,
      clk    => hw_clk,
      reset  => reset,
      output => done
    );

  ---------------------
  -- Buffer Register --
  ---------------------

  -- ensures hardware input is valid since [output] will go back to source of [input]
  input_buf_reg : storage_register
    generic map (
      G_n => G_n
    )
    port map (
      input  => input,
      clk    => reg_clk,
      reset  => reset,
      load   => load,
      output => abs_hw_input
    );

  -----------------------------
  -- Absolute Logic Hardware --
  -----------------------------

  abs_2c_hw : abs_2c_look_ahead_1024
    port map (
      input_sign => input_sign,
      input      => abs_hw_input,
      output     => output(output'left - 1 downto 0),
      prop_out   => open
    );

  output(output'left) <= input_sign;
  
end architecture structural;