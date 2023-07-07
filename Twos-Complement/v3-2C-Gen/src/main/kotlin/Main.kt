import java.io.File
import kotlin.math.ceil
import kotlin.math.log
import kotlin.math.pow

/*
Generates the following files:
- abs_2c_look_ahead_####.vhd
- abs_2c_wrapper_v3_####.vhd
 */
fun main(args: Array<String>) {
    val num_bits = 32 // bits to receive/transmit

    // Note: This generator doesn't work for num_bits <= 16.
    // Not that you should be trying to make one that small anyway.

    // don't change anything below this

    val levels = ceil(log(base = 4.0, x = num_bits.toDouble())).toInt()
    val l0_size = 4.0.pow(levels)

    fun getLevelSize(i: Int): Int {
        return if (i == 0) {
            l0_size.toInt()
        } else {
            l0_size.toInt() / (4.0.pow(i)).toInt()
        }
    }

    val levelSizes = IntArray(levels) { i -> getLevelSize(i)}

    println("Levels: $levels")
    println("Level Sizes: ")
    for (i in 0 until levels) {
        println("l${i}_size = ${levelSizes[i]}")
    }

    fun genLevelSizeString(): String {
        /* Sample:
            G_l0_size : integer := 4096; -- should be equal to 4^(G_levels) and the smallest power of 4 larger than G_n
            G_l1_size : integer := 1024; -- G_l0_size / 4, and so on.
            G_l2_size : integer := 256;
            G_l3_size : integer := 64;
            G_l4_size : integer := 16;
            G_l5_size : integer := 4
         */

        val sb = StringBuilder()
        for (i in 0 until levels) {
            sb.append("    ")
            sb.append("G_l${i}_size : integer := ")
            sb.append(levelSizes[i])
            if (i != levels - 1) sb.append(";")
            if (i == 0) {
                sb.append(" -- should be equal to 4^(G_levels) and the smallest power of 4 larger than G_n")
            } else if (i == 1) {
                sb.append(" -- G_l0_size / 4, and so on.")
            }
            if (i != levels - 1) sb.append("\n")
        }
        return sb.toString()
    }

    fun genMiddleLevelSignalStrings(): String {
        /* Sample:
            signal l5_to_l4_carry_in : std_logic_vector(G_l4_size - 1 downto 0);
            signal l4_to_l5_prop_out : std_logic_vector(G_l4_size - 1 downto 0);

            signal l4_to_l3_carry_in : std_logic_vector(G_l3_size - 1 downto 0);
            signal l3_to_l4_prop_out : std_logic_vector(G_l3_size - 1 downto 0);

            signal l3_to_l2_carry_in : std_logic_vector(G_l2_size - 1 downto 0);
            signal l2_to_l3_prop_out : std_logic_vector(G_l2_size - 1 downto 0);

            signal l2_to_l1_carry_in : std_logic_vector(G_l1_size - 1 downto 0); -- (C_4i..4i+3) carry in signals from L2 ILAs to L1 ILAs
            signal l1_to_l2_prop_out : std_logic_vector(G_l1_size - 1 downto 0); -- (P_4i..4i+3) group propagate signals from L1 ILAs to L2 ILAs
         */
        val sb = StringBuilder()
        for (i in (levels - 1) downTo 2) {
            sb.append("  signal l${i}_to_l${i - 1}_carry_in : std_logic_vector(G_l${i-1}_size - 1 downto 0);")
            if (i == 2) {
                sb.append(" -- (C_4i..4i+3) carry in signals from L2 ILAs to L1 ILAs")
            }
            sb.append("\n")
            sb.append("  signal l${i - 1}_to_l${i}_prop_out : std_logic_vector(G_l${i-1}_size - 1 downto 0);")
            if (i == 2) {
                sb.append(" -- (P_4i..4i+3) group propagate signals from L1 ILAs to L2 ILAs")
            }
            if (i != 2) sb.append("\n\n")
        }
        return sb.toString()
    }

    fun getLevelIDString(i: Int): String {
        return if (i == levels) "top"
        else "l$i"
    }

    fun genMiddleLevelComponentLoopsString(): String {
        /* Sample:
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
         */
        val sb = StringBuilder()
        for (i in 2 until levels) {
            sb.append("""
  gen_l${i}_ila : for i in 0 to (G_l${i}_size - 1) generate
    l${i}_ila_i : invert_look_ahead
      port map (
        c_in       => ${getLevelIDString(i + 1)}_to_l${i}_carry_in(i),
        prop_in_0  => l${i - 1}_to_l${i}_prop_out(i * 4),
        prop_in_1  => l${i - 1}_to_l${i}_prop_out(i * 4 + 1),
        prop_in_2  => l${i - 1}_to_l${i}_prop_out(i * 4 + 2),
        prop_in_3  => l${i - 1}_to_l${i}_prop_out(i * 4 + 3),
        c_out_0    => l${i}_to_l${i - 1}_carry_in(i * 4),
        c_out_1    => l${i}_to_l${i - 1}_carry_in(i * 4 + 1),
        c_out_2    => l${i}_to_l${i - 1}_carry_in(i * 4 + 2),
        c_out_3    => l${i}_to_l${i - 1}_carry_in(i * 4 + 3),
        prop_group => l${i}_to_${getLevelIDString(i + 1)}_prop_out(i)
      );
  end generate gen_l${i}_ila;""")
            sb.append("\n")
        }
        return sb.toString()
    }

    var content =
"""
-------------------------------------------------------------------------------------
-- abs_2c_look_ahead_${num_bits}.vhd
-------------------------------------------------------------------------------------
-- Authors:     Riley Jackson, Maxwell Phillips (generalization and revision)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Primary absolute value logic based on carry-look-ahead structure.
--              This '2c' version takes an input sign.
-- Precision:   ${num_bits} bits
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

entity abs_2c_look_ahead_${num_bits} is
  generic (
    G_n       : integer := ${num_bits}; -- Input length is n
    G_levels  : integer := ${levels};    -- number of levels of invert look-ahead logic below the top level
${genLevelSizeString()}
  );
  port (
    input_sign : in    std_logic;
    input      : in    std_logic_vector(G_n - 1 downto 0);
    output     : out   std_logic_vector(G_n - 1 downto 0);
    prop_out   : out   std_logic
  );
end abs_2c_look_ahead_${num_bits};

architecture behavioral of abs_2c_look_ahead_${num_bits} is

  component partial_full_adder is
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

  signal top_to_l${levels - 1}_carry_in : std_logic_vector(G_l${levels - 1}_size - 1 downto 0);
  signal l${levels - 1}_to_top_prop_out : std_logic_vector(G_l${levels - 1}_size - 1 downto 0);
  
${genMiddleLevelSignalStrings()}

  signal l1_to_pfa_carry_in : std_logic_vector(G_l0_size - 1 downto 0); -- (C_i) carry in signals to L0 PFAs
  signal pfa_to_l1_prop_out : std_logic_vector(G_l0_size - 1 downto 0); -- (P_i) propagate signals from L0 PFAs

begin

  sign                  <= input_sign;        -- take sign as input directly from port
  output(0)             <= input(0);          -- LSB of output always equals LSB of input, since this bit is never flipped
  pfa_to_l1_prop_out(0) <= input(0);          -- need to pass this because it doesn't have a PFA
  prop_out              <= top_prop_out;

  -- note that the generation limit is G_n, not G_l0_size.
  -- the rest of the PFAs aren't needed, but G_l0_size is needed for other areas because of indexing.
  -- however, unnecessary things will be optimized away during implementation.
  gen_pfa : for i in 1 to (G_n - 1) generate
    pfa_i : partial_full_adder
      port map (
        a_sign   => sign,
        a_i      => input(i),
        carry_in => l1_to_pfa_carry_in(i),
        sum_out  => output(i),
        prop_out => pfa_to_l1_prop_out(i)
      );
  end generate gen_pfa;

  gen_l1_ila : for i in 0 to (G_l1_size - 1) generate
    l1_ila_i : invert_look_ahead
      port map (
        c_in       => l2_to_l1_carry_in(i),
        prop_in_0  => pfa_to_l1_prop_out(i * 4),
        prop_in_1  => pfa_to_l1_prop_out(i * 4 + 1),
        prop_in_2  => pfa_to_l1_prop_out(i * 4 + 2),
        prop_in_3  => pfa_to_l1_prop_out(i * 4 + 3),
        c_out_0    => l1_to_pfa_carry_in(i * 4),
        c_out_1    => l1_to_pfa_carry_in(i * 4 + 1),
        c_out_2    => l1_to_pfa_carry_in(i * 4 + 2),
        c_out_3    => l1_to_pfa_carry_in(i * 4 + 3),
        prop_group => l1_to_l2_prop_out(i)
      );
  end generate gen_l1_ila;
${genMiddleLevelComponentLoopsString()}
  top_ila : invert_look_ahead
    port map (
      c_in       => input(0),
      prop_in_0  => l${levels - 1}_to_top_prop_out(0),
      prop_in_1  => l${levels - 1}_to_top_prop_out(1),
      prop_in_2  => l${levels - 1}_to_top_prop_out(2),
      prop_in_3  => l${levels - 1}_to_top_prop_out(3),
      c_out_0    => top_to_l${levels - 1}_carry_in(0),
      c_out_1    => top_to_l${levels - 1}_carry_in(1),
      c_out_2    => top_to_l${levels - 1}_carry_in(2),
      c_out_3    => top_to_l${levels - 1}_carry_in(3),
      prop_group => top_prop_out
    );

end architecture behavioral;
""".trimIndent()

    var file = File("abs_2c_look_ahead_${num_bits}.vhd")

    file.writeText(content)

    content =
        """
-------------------------------------------------------------------------------------
-- abs_2c_wrapper_v3_${num_bits}.vhd
-------------------------------------------------------------------------------------
-- Authors:     Maxwell Phillips, Riley Jackson (original code), 
--              Nathan Hagerdorn (original state machine code)
-- Copyright:   Ohio Northern University, 2023.
-- License:     GPL v3
-- Description: Absolute value (two's complement) logic wrapper.
-- Precision:   ${num_bits} bits
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
    G_n : integer := ${num_bits}  -- Input magnitude length is n
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

  component abs_2c_look_ahead_${num_bits} is
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

  abs_2c_hw : abs_2c_look_ahead_${num_bits}
    port map (
      input_sign => input_sign,
      input      => abs_hw_input,
      output     => output(output'left - 1 downto 0),
      prop_out   => open
    );

  output(output'left) <= input_sign;
  
end architecture structural;
""".trimIndent()

    file = File("abs_2c_wrapper_v3_${num_bits}.vhd")

    file.writeText(content)
}