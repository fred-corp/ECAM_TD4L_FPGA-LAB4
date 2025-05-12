-- Testbench for quadrature_decoder using VUnit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity quadrature_decoder_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of quadrature_decoder_tb is
  constant clk_period : time := 83.333 ns; -- 12 MHz

  signal clk         : std_logic                    := '0';
  signal reset       : std_logic                    := '0';
  signal quad        : std_logic_vector(1 downto 0) := (others => '0');
  signal count_valid : std_logic;
  signal count_out   : std_logic_vector(15 downto 0);

begin
  -- Clock generation
  clk_process : process
  begin
    while true loop
      clk <= '0';
      wait for clk_period / 2;
      clk <= '1';
      wait for clk_period / 2;
    end loop;
  end process;

  -- DUT instantiation
  uut : entity work.quadrature_decoder
    generic map(
      clk_freq => 12000000,
      ppr      => 10
    )
    port map
    (
      clk         => clk,
      reset       => reset,
      quad        => quad,
      count_valid => count_valid,
      count_out   => count_out
    );

  -- Stimulus process
  stimulus : process
    procedure drive_quadrature_forward(steps : integer) is
    begin
      for i in 0 to steps - 1 loop
        quad <= "00";
        wait for 2500 us;
        quad <= "01";
        wait for 2500 us;
        quad <= "11";
        wait for 2500 us;
        quad <= "10";
        wait for 2500 us;
      end loop;
    end procedure;

    procedure drive_quadrature_backward(steps : integer) is
    begin
      for i in 0 to steps - 1 loop
        quad <= "00";
        wait for 2500 us;
        quad <= "10";
        wait for 2500 us;
        quad <= "11";
        wait for 2500 us;
        quad <= "01";
        wait for 2500 us;
      end loop;
    end procedure;

  begin
    test_runner_setup(runner, runner_cfg);

    reset <= '1';
    wait for 10 * clk_period;
    reset <= '0';

    -- Simulate forward motion
    drive_quadrature_forward(50); -- 50 steps forward
    wait for 200 ms;
    check_equal(count_out(15), '1', "Direction should be forward");

    -- Simulate backward motion
    drive_quadrature_backward(30); -- 30 steps backward
    wait for 200 ms;
    check_equal(count_out(15), '0', "Direction should be backward");

    test_runner_cleanup(runner);
  end process;

end architecture;