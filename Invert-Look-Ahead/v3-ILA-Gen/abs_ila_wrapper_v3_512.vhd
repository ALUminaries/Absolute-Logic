-------------------------------------------------------------------------------------
-- abs_ila_wrapper_v3_512.vhd
-------------------------------------------------------------------------------------
-- Authors:     Maxwell Phillips, Riley Jackson (original code), 
--              Nathan Hagerdorn (original state machine code)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Absolute value (sign and magnitude) logic wrapper.
-- Precision:   512 bits
-------------------------------------------------------------------------------------
--
-- Inverts a two's complement input.
-- Takes one slow clock cycle (`hw_clk`) to complete.
--
-------------------------------------------------------------------------------------
-- Generics
-------------------------------------------------------------------------------------
--
-- [G_n]: Size of two's complement input to invert. 
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
-- [input]: Parallel data input.
--
-- [output_sign], [output_magnitude]: Self explanatory.
--
-- [done]: High once the hardware has finished processing.
--
-------------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

entity abs_ila_wrapper is
  generic (
    G_n : integer := 512  -- Input length is n
  );
  port (
    reg_clk          : in    std_logic;
    hw_clk           : in    std_logic;
    start            : in    std_logic;
    load             : in    std_logic;
    reset            : in    std_logic;
    input            : in    std_logic_vector(G_n - 1 downto 0);
    output           : out   std_logic_vector(G_n - 1 downto 0);
    done             : out   std_logic
  );
end abs_ila_wrapper;

architecture structural of abs_ila_wrapper is

  ----------------
  -- Components --
  ----------------

  component abs_look_ahead_512 is
    port (
      input    : in    std_logic_vector(G_n - 1 downto 0);
      output   : out   std_logic_vector(G_n - 1 downto 0);
      prop_out : out   std_logic
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
  signal abs_hw_output : std_logic_vector(G_n - 1 downto 0);

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

  -- ensures hardware input is valid since [output_magnitude] will go back to source of [input]
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

  abs_hw : abs_look_ahead_512
    port map (
      input    => '1' & abs_hw_input(abs_hw_input'left - 1 downto 0),
      output   => abs_hw_output,
      prop_out => open
    );
    
  output <= not abs_hw_input(G_n - 1) & abs_hw_output(abs_hw_output'left - 1 downto 0);

end architecture structural;