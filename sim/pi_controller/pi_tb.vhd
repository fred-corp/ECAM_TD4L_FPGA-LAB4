library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

entity pi_controller_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of pi_controller_tb is

  constant clk_period : time := 83 ns; -- 12 MHz

  signal clk        : std_logic                     := '0';
  signal reset      : std_logic                     := '1';
  signal auto       : std_logic                     := '0';
  signal Kp         : std_logic_vector(15 downto 0) := (others => '0');
  signal Ki         : std_logic_vector(15 downto 0) := (others => '0');
  signal setpoint   : std_logic_vector(15 downto 0) := (others => '0');
  signal pv         : std_logic_vector(15 downto 0) := (others => '0');
  signal output_pwm : std_logic_vector(15 downto 0);

  -- Helper function: convert integer to custom signed magnitude std_logic_vector
  function to_smag(val : integer) return std_logic_vector is
    variable mag         : unsigned(14 downto 0);
    variable res         : std_logic_vector(15 downto 0);
  begin
    if val < 0 then
      mag     := to_unsigned(-val, 15);
      res(15) := '1'; -- sign bit
    else
      mag     := to_unsigned(val, 15);
      res(15) := '0';
    end if;
    res(14 downto 0) := std_logic_vector(mag);
    return res;
  end function;

begin

  clk_process : process
  begin
    while true loop
      clk <= '1';
      wait for clk_period / 2;
      clk <= '0';
      wait for clk_period / 2;
    end loop;
  end process;

  -- DUT instance
  uut : entity work.pi_controller
    generic map(
      clk_freq    => 12.0e6,
      pi_period   => 100.0,
      output_min  => 0,
      output_max  => 32767,
      dp_position => 8
    )
    port map
    (
      clk      => clk,
      reset    => reset,
      auto     => auto,
      Kp       => Kp,
      Ki       => Ki,
      setpoint => setpoint,
      pv       => pv,
      output   => output_pwm
    );

  test_proc : process
  begin
    test_runner_setup(runner, runner_cfg);

    -- Reset pulse
    wait for 200 ns;
    reset <= '0';

    -- Apply gains (e.g., Kp = 1.0, Ki = 0.1 in fixed-point Q8.8)
    Kp   <= std_logic_vector(to_signed(256, 16)); -- 1.0 * 2^8 = 256
    Ki   <= std_logic_vector(to_signed(26, 16)); -- 0.1 * 2^8 ≈ 26
    auto <= '1';

    -- Initial setpoint = 0, pv = 0
    setpoint <= to_smag(0);
    pv       <= to_smag(0);
    wait for 1 ms;

    -- Step input: setpoint = 100, pv still 0
    setpoint <= to_smag(10);
    wait for 10 ms;

    -- Change pv to simulate response: pv = 50
    pv <= to_smag(100);
    wait for 500 us;

    -- Change pv to simulate response: pv = 10
    pv <= to_smag(10);
    wait for 10 ms;

    -- Setpoint = -50
    -- setpoint <= to_smag(-50);
    -- wait for 10 ms;

    -- Auto = off
    auto <= '0';
    wait for 10 ms;

    test_runner_cleanup(runner);
  end process;

end architecture;
