---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab : Robot project
-- Author : Frédéric Druppel
-- File content : Quadrature decoder
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity quadrature_decoder is
  generic (
    clk_freq : integer := 12_000_000; --* Clock frequency in Hz
    ppr      : integer := 1024 --* Pulses per revolution
  );
  port (
    clk   : in std_logic; --* Main clock
    reset : in std_logic; --* Reset signal (active high)

    -- Inputs
    quad : in std_logic_vector(1 downto 0); --* Quadrature Encoder 1

    -- Outputs
    count_valid : out std_logic; --* Speed valid signal
    count_out   : out std_logic_vector(15 downto 0) --* Speed output
  );
end entity;

---------------------------------------------------------------------------------------------------
-- Main
---------------------------------------------------------------------------------------------------
architecture behavioral of quadrature_decoder is
  constant clk_count_width : integer                      := integer(ceil(log2(real(clk_freq/10)))); --* Width of the clock count
  signal s_quadA_delayed   : std_logic_vector(2 downto 0) := (others => '0');
  signal s_quadB_delayed   : std_logic_vector(2 downto 0) := (others => '0');

  signal step        : std_logic                          := '0'; --* Step signal
  signal direction   : std_logic                          := '0'; --* Direction of rotation
  signal clk_count   : unsigned(clk_count_width downto 0) := (others => '0'); --* Clock count
  signal count       : unsigned(14 downto 0)              := (others => '0'); --* Count of pulses
  signal s_count     : unsigned(14 downto 0)              := (others => '0'); --* Count of pulses (signal)
  signal s_direction : std_logic                          := '0'; --* Direction of rotation (signal)

begin
  main : process (clk)
  begin
    if rising_edge(clk) then
      -- shift the quadrature signals
      s_quadA_delayed <= s_quadA_delayed(1 downto 0) & quad(0);
      s_quadB_delayed <= s_quadB_delayed(1 downto 0) & quad(1);

      -- set step and direction
      step      <= s_quadA_delayed(1) xor s_quadA_delayed(2) xor s_quadB_delayed(1) xor s_quadB_delayed(2);
      direction <= s_quadA_delayed(1) xor s_quadB_delayed(2);

      -- Count pulses
      if step = '1' then
        count       <= count + 1;
        s_direction <= direction;
      end if;

      -- Calculate speed at 10Hz
      clk_count <= clk_count + 1;
      if clk_count = (clk_freq / 10) - 1 then
        clk_count   <= (others => '0');
        s_count     <= count;
        count       <= (others => '0');
        count_valid <= '1';
      else
        count_valid <= '0';
      end if;

      -- Reset logic
      if reset = '1' then
        s_quadA_delayed <= (others => '0');
        s_quadB_delayed <= (others => '0');
        step            <= '0';
        direction       <= '0';
        count_valid     <= '0';
        s_count         <= (others => '0');
      end if;

    end if;
  end process;

  count_out <= s_direction & std_logic_vector(s_count(14 downto 0));

end architecture;