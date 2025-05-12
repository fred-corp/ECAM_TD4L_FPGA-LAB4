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

  -- VUnit logging
  constant logger : logger_t := get_logger("pi_logger");

  signal output_int   : integer;
  signal setpoint_int : integer;
  signal pv_int       : integer;

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

  output_int   <= to_integer(signed(output_pwm));
  setpoint_int <= to_integer(signed(setpoint));
  pv_int       <= to_integer(signed(pv));

  log_proc : process(clk)
begin
  if rising_edge(clk) then
    if now > 100 ns then  -- avoid logging during reset/setup phase
      log(logger,
        "time=" & integer'image(now / 1 ns) &
        ", setpoint=" & integer'image(setpoint_int) &
        ", pv=" & integer'image(pv_int) &
        ", output=" & integer'image(output_int));
    end if;
  end if;
end process;

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
    variable pv_int          : integer := 0; -- Internal integer representation of pv
    variable target_setpoint : integer := 100; -- Setpoint in real units
  begin
    test_runner_setup(runner, runner_cfg);

    -- Initial reset
    reset <= '1';
    wait for 100 ns;
    reset <= '0';

    -- Apply gains (e.g., Kp = 1.0, Ki = 0.1)
    Kp   <= std_logic_vector(to_signed(256, 16)); -- 1.0 in Q8.8
    Ki   <= std_logic_vector(to_signed(26, 16)); -- 0.1 in Q8.8
    auto <= '1';

    -- Initial setpoint = 0
    setpoint <= to_smag(0);
    pv       <= to_smag(0);
    wait for 1 ms;

    -- Step input: setpoint = 100
    setpoint <= to_smag(target_setpoint);

    -- Simulated plant response loop (rise toward 100 in steps)
    for i in 0 to 60 loop
      -- Simulate slow system: increase pv towards setpoint
      pv_int := pv_int + integer((target_setpoint - pv_int) / 8); -- simple first-order
      pv <= to_smag(pv_int);
      wait for 50 us;
    end loop;
    pv <= to_smag(target_setpoint);
    wait for 1 ms;

    -- Now simulate an overshoot or disturbance
    pv_int := 120;
    pv <= to_smag(pv_int);
    wait for 100 us;

    -- Simulate recovery
    for i in 0 to 30 loop
      pv_int := pv_int - integer((pv_int - target_setpoint) / 6); -- recovery
      pv <= to_smag(pv_int);
      wait for 60 us;
    end loop;
    pv <= to_smag(target_setpoint);
    wait for 1 ms;

    -- Turn off auto
    auto <= '0';
    wait for 2 ms;

    test_runner_cleanup(runner);
  end process;

end architecture;
