library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

entity top_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of top_tb is
    signal clk : std_logic := '0';
    signal rstn : std_logic := '0';
    signal uart_txd : std_logic := '0';
    signal uart_rxd : std_logic := '1';
    signal led_r : std_logic;
    signal led_g : std_logic;
    signal led_b : std_logic;
    signal debug : std_logic;

    constant uart_master_bfm : uart_master_t := new_uart_master(initial_baud_rate => 230400);
    constant uart_master_stream : stream_master_t := as_stream(uart_master_bfm);

begin
    top_inst : entity work.top
    port map (
        clk => clk,
        rstn => rstn,
        uart_txd => uart_txd,
        uart_rxd => uart_rxd,
        led_r => led_r,
        led_g => led_g,
        led_b => led_b,
        quad1 => (others => '0'),
        quad2 => (others => '0'),
        us_echo => '1'
    );

    uart_master_bfm_inst : entity vunit_lib.uart_master
    generic map (
      uart => uart_master_bfm)
    port map (
      tx => uart_rxd);

    clk <= not clk after (83.333/2.0)* 1 ns;
    rstn <= '0', '1' after 500 ns;

    main : process
    begin
      test_runner_setup(runner, runner_cfg);
      push_stream(net, uart_master_stream, X"AA");
      wait for 200 us;
      push_stream(net, uart_master_stream, X"32");
      wait for 200 us;
      push_stream(net, uart_master_stream, X"00");
      wait for 200 us;
      push_stream(net, uart_master_stream, X"01");
      wait for 500 us;
      push_stream(net, uart_master_stream, X"AA");
      wait for 200 us;
      push_stream(net, uart_master_stream, X"32");
      wait for 200 us;
      push_stream(net, uart_master_stream, X"00");
      wait for 200 us;
      push_stream(net, uart_master_stream, X"00");
      wait for 500 us;
      
      wait for 500 ms;
      test_runner_cleanup(runner); -- Simulation ends here
    end process;
end architecture;
