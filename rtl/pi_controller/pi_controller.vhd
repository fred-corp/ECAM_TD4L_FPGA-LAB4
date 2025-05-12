---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab : Robot project
-- Author : Frédéric Druppel
-- File content : PI Controller (with anti-windup)
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pi_controller is
  generic (
    clk_freq    : real    := 12.0e6; --* Clock frequency in Hz
    pi_period   : real    := 100.0; --* PI controller period in ms
    output_min  : integer := 0; --* Minimum output value
    output_max  : integer := 32767; --* Maximum output value
    dp_position : integer := 8 --* Decimal point position (8 bits)
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    auto     : in std_logic; --* Auto mode (active high)
    Kp       : in std_logic_vector(15 downto 0); --* Proportional gain, 16bits, 8bits for integer, 8bits for decimal
    Ki       : in std_logic_vector(15 downto 0); --* Integral gain, 16bits, 8bits for integer, 8bits for decimal
    setpoint : in std_logic_vector(15 downto 0); --* Desired setpoint, encoder pulse Hz
    pv       : in std_logic_vector(15 downto 0); --* Perceived value, encoder pulse Hz
    output   : out std_logic_vector(15 downto 0) := (others => '0') --* PI controller output, PWM
  );
end entity;

architecture rtl of pi_controller is
  constant MAX_INTEGRAL : signed(31 downto 0) := to_signed(2147483647, 32); -- 2^31 - 1
  constant MIN_INTEGRAL : signed(31 downto 0) := to_signed(-2147483648, 32); -- -2^31
  
  signal s_setpoint     : signed(15 downto 0) := (others => '0'); --* Desired setpoint
  signal s_pv           : signed(15 downto 0) := (others => '0'); --* Process variable
  signal s_error        : signed(15 downto 0) := (others => '0'); --* Integral error signal
  signal s_output       : signed(15 downto 0) := (others => '0'); --* PI controller output signal
  signal s_integral     : signed(31 downto 0) := (others => '0'); --* Integral term
  signal s_proportional : signed(31 downto 0) := (others => '0'); --* Proportional term

begin
  main : process (clk)
    variable s_pi_raw      : signed(31 downto 0);
    variable next_integral : signed(32 downto 0); -- For overflow detection
    variable pi_shifted    : signed(31 downto 0); -- Scaled output
  begin
    if rising_edge(clk) then

      --* Input conversion from 16-bit sign/magnitude to two's complement
      if pv(15) = '0' then
        s_pv <= resize(signed(pv(14 downto 0)), 16);
      else
        s_pv <= - resize(signed(pv(14 downto 0)), 16);
      end if;

      if setpoint(15) = '0' then
        s_setpoint <= resize(signed(setpoint(14 downto 0)), 16);
      else
        s_setpoint <= - resize(signed(setpoint(14 downto 0)), 16);
      end if;

      --* Error computation
      s_error <= s_setpoint - s_pv;

      --* Proportional term
      s_proportional <= signed(Kp) * s_error;

      --* PI raw value
      s_pi_raw   := s_proportional + s_integral;
      pi_shifted := shift_right(s_pi_raw, integer(dp_position));

      --* Output saturation logic
      if pi_shifted > resize(to_signed(output_max, 16), 32) then
        s_output <= to_signed(output_max, 16);
      elsif pi_shifted < resize(to_signed(output_min, 16), 32) then
        s_output <= to_signed(output_min, 16);
      else
        s_output <= resize(pi_shifted, 16);
      end if;

      --* Integral update (with anti-windup: skip update if output saturated)
      if auto = '1' and s_output = resize(pi_shifted, 16) then
        next_integral := resize(s_integral, 33) + resize(signed(Ki) * s_error, 33);
        if next_integral > resize(MAX_INTEGRAL, 33) then
          s_integral <= MAX_INTEGRAL;
        elsif next_integral < resize(MIN_INTEGRAL, 33) then
          s_integral <= MIN_INTEGRAL;
        else
          s_integral <= resize(next_integral, 32);
        end if;
      end if;

      --* Reset logic
      if reset = '1' then
        s_error        <= (others => '0');
        s_output       <= (others => '0');
        s_integral     <= (others => '0');
        s_proportional <= (others => '0');
      end if;
    end if;
  end process;

  output <= std_logic_vector(s_output);

end architecture;
