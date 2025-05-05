---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab : Robot project
-- Author : Frédéric Druppel
-- File content : Robot project toplevel
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
  port (
    clk  : in std_logic; --* System clock
    rstn : in std_logic; --* System reset (active low)

    uart_txd : out std_logic; --* UART transmitter
    uart_rxd : in std_logic; --* UART receiver

    us_trig : out std_logic; --* Ultrasound Trigger
    us_echo : in std_logic := '0'; --* Ultrasound Echo

    quad1 : in std_logic_vector(1 downto 0) := (others => '0'); --* Quadrature Encoder 1
    quad2 : in std_logic_vector(1 downto 0) := (others => '0'); --* Quadrature Encoder 2

    pwm_mot1 : out std_logic_vector(1 downto 0); --* Motor 1 control
    pwm_mot2 : out std_logic_vector(1 downto 0); --* Motor 2 control

    led_r : out std_logic; --* Red LED
    led_g : out std_logic; --* Green LED
    led_b : out std_logic --* Blue LED
  );
end entity top;

architecture rtl of top is
  -- Reset
  signal reset : std_logic; --* Reset signal (active high)

  -- UART
  signal uart_tx_valid : std_logic := '0'; --* UART transmitter valid
  signal uart_tx_ready : std_logic; --* UART transmitter ready
  signal uart_tx_data  : std_logic_vector(7 downto 0); --* UART transmitter data
  signal uart_rx_valid : std_logic := '0'; --* UART receiver valid
  signal uart_rx_data  : std_logic_vector(7 downto 0); --* UART receiver data

  -- APB
  signal apb_paddr   : std_logic_vector(7 downto 0); --* APB address
  signal apb_psel    : std_logic; --* APB select
  signal apb_penable : std_logic; --* APB enable
  signal apb_pwrite  : std_logic; --* APB write
  signal apb_pwdata  : std_logic_vector(15 downto 0); --* APB write data
  signal apb_prdata  : std_logic_vector(15 downto 0); --* APB read data

  -- LEDs
  signal led_out_r : std_logic := '0'; --* Red LED output signal
  signal led_out_g : std_logic := '0'; --* Green LED output signal
  signal led_out_b : std_logic := '0'; --* Blue LED output signal

  -- Motor PWM
  signal mot1_pwm : std_logic_vector(15 downto 0); --* Motor 1 PWM data
  signal mot2_pwm : std_logic_vector(15 downto 0); --* Motor 2 PWM data

  -- Distance
  signal echo_cycles : unsigned(15 downto 0) := (others => '0'); --* Duration of the echo signal

  -- Ramp generator
  signal ramp_execute : std_logic := '0'; --* Ramp generator execute signal
  signal ramp_speed_out : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp generator output speed

  -- Counter
  signal counter : unsigned(23 downto 0) := (others => '0'); --* Counter for LED blinking

begin
  -- *** Reset resynchronization ***
  reset_gen_inst : entity work.olo_base_reset_gen
    generic map(
      RstInPolarity_g => '0'
    )
    port map
    (
      Clk    => Clk,
      RstOut => reset,
      RstIn  => rstn
    );

  -- *** UART ***
  uart_inst : entity work.olo_intf_uart
    generic map(
      ClkFreq_g  => 12.0e6,
      BaudRate_g => 230400.0
    )
    port map
    (
      Clk            => Clk,
      Rst            => reset,
      Tx_Valid       => uart_tx_valid,
      Tx_Ready       => uart_tx_ready,
      Tx_Data        => uart_tx_data,
      Rx_Valid       => uart_rx_valid,
      Rx_Data        => uart_rx_data,
      Rx_ParityError => open,
      Uart_Tx        => uart_txd,
      Uart_Rx        => uart_rxd
    );

  -- *** UART to APB ***
  uart_protocol_inst : entity work.uart_protocol
    port map
    (
      clk       => Clk,
      reset     => reset,
      rx_data   => uart_rx_data,
      rx_valid  => uart_rx_valid,
      tx_data   => uart_tx_data,
      tx_valid  => uart_tx_valid,
      tx_ready  => uart_tx_ready,
      m_paddr   => apb_paddr,
      m_psel    => apb_psel,
      m_penable => apb_penable,
      m_pwrite  => apb_pwrite,
      m_pwdata  => apb_pwdata,
      m_prdata  => apb_prdata
    );

  -- *** Config Registers ***
  config_registers_inst : entity work.config_regs
    port map
    (
      clk       => Clk,
      reset     => reset,
      s_paddr   => apb_paddr,
      s_psel    => apb_psel,
      s_penable => apb_penable,
      s_pwrite  => apb_pwrite,
      s_pwdata  => apb_pwdata,
      s_prdata  => apb_prdata,
      led_r     => led_out_r,
      led_g     => led_out_g,
      led_b     => led_out_b,
      mot1_pwm  => mot1_pwm,
      mot2_pwm  => mot2_pwm,
      echo_cycles => echo_cycles,
      ramp_execute => ramp_execute,
      ramp_speed_out => ramp_speed_out
    );

  -- *** PWM drivers ***
  pwm_driver_mot1_inst : entity work.pwm_driver
    generic map(
      clk_freq => 12.0e6,
      pwm_freq => 25.0e3
    )
    port map
    (
      clk       => Clk,
      reset     => reset,
      pwm_data  => mot1_pwm,
      pwm_out_1 => pwm_mot1(0),
      pwm_out_2 => pwm_mot1(1)
    );
  pwm_driver_mot2_inst : entity work.pwm_driver
    generic map(
      clk_freq => 12.0e6,
      pwm_freq => 25.0e3
    )
    port map
    (
      clk       => Clk,
      reset     => reset,
      pwm_data  => mot2_pwm,
      pwm_out_1 => pwm_mot2(0),
      pwm_out_2 => pwm_mot2(1)
    );

  -- *** Distance driver ***
  distance_driver_inst : entity work.distance_driver
    generic map(
      clk_freq  => 12.0e6,
      ms_period => 100.0,
      us_width  => 10.0
    )
    port map
    (
      clk       => Clk,
      reset     => reset,
      trig_pin  => us_trig,
      echo_pin  => us_echo,
      -- distance   => open,
      echo_cycles => echo_cycles
    );

  -- *** Ramp generator ***
  ramp_gen_inst : entity work.ramp_generator
    generic map (
      clk_freq  => 12_000_000
    )
    port map
    (
      clk       => Clk,
      reset     => reset,
      
      time_delay      => std_logic_vector(to_unsigned(1, 16)),
      target_speed    => std_logic_vector(to_unsigned(100, 16)),
      fast_time       => std_logic_vector(to_unsigned(50, 16)),
      speed_increment => std_logic_vector(to_unsigned(1, 16)),
      speed_decrement => std_logic_vector(to_unsigned(1, 16)),
      execute         => ramp_execute,
      speed_out       => ramp_speed_out
    );

  main : process (clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;
      if reset = '1' then
        counter <= (others => '0');
      end if;
    end if;
  end process main;
  ----------------------------------------

  -- *** LED drivers ***
  led_r <= '0' when led_out_r = '1' else
    'Z';
  led_g <= '0' when led_out_g = '1' else
    'Z';
  led_b <= '0' when led_out_b = '1' else
    'Z';

end architecture rtl;
