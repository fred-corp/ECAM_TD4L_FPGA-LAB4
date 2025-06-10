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
  signal s_echo_valid  : std_logic             := '0'; --* Echo signal valid flag
  signal s_echo_cycles : unsigned(15 downto 0) := (others => '0'); --* Duration of the echo signal

  -- PI controller
  signal s_pi_kp   : std_logic_vector(15 downto 0) := (others => '0'); --* PI controller Kp
  signal s_pi_ki   : std_logic_vector(15 downto 0) := (others => '0'); --* PI controller Ki
  signal s_pi_enable : std_logic                     := '0'; --* PI controller enable
  signal s_pi_mot1_output : std_logic_vector(15 downto 0) := (others => '0'); --* PI controller output for motor 1
  signal s_pi_mot2_output : std_logic_vector(15 downto 0) := (others => '0'); --* PI controller output for motor 2

  -- Ramp generator
  signal s_ramp_time_delay : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp time delay
  signal s_ramp_target_speed : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp target speed
  signal s_ramp_fast_time : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp fast time
  signal s_ramp_speed_increment : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp speed increment
  signal s_ramp_speed_decrement : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp speed decrement
  signal s_ramp_execute : std_logic := '0'; --* Ramp execute signal
  signal s_ramp_speed_out : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp speed output

  -- Quadrature encoders
  signal quad1_valid : std_logic                     := '0'; --* Quadrature Encoder 1 valid
  signal quad1_count : std_logic_vector(15 downto 0) := (others => '0'); --* Quadrature Encoder 1 data
  signal quad2_valid : std_logic                     := '0'; --* Quadrature Encoder 2 valid
  signal quad2_count : std_logic_vector(15 downto 0) := (others => '0'); --* Quadrature Encoder 2 data

  -- Counter
  signal counter : unsigned(23 downto 0) := (others => '0'); --* Counter for LED blinking

  -- Interconnect signals
  signal si_speed_mot1 : std_logic_vector(15 downto 0) := (others => '0'); --* Interconnect signal for speed of motor 1
  signal si_speed_mot2 : std_logic_vector(15 downto 0) := (others => '0'); --* Interconnect signal for speed of motor 2

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
      clk                  => Clk,
      reset                => reset,
      s_paddr              => apb_paddr,
      s_psel               => apb_psel,
      s_penable            => apb_penable,
      s_pwrite             => apb_pwrite,
      s_pwdata             => apb_pwdata,
      s_prdata             => apb_prdata,
      led_r                => led_out_r,
      led_g                => led_out_g,
      led_b                => led_out_b,
      mot1_pwm             => mot1_pwm,
      mot2_pwm             => mot2_pwm,
      pi_kp                => s_pi_kp,
      pi_ki                => s_pi_ki,
      pi_sp                => s_pi_sp,
      pi_enable            => s_pi_enable, -- TODO connect to controller selection logic
      ramp_time_delay      => s_ramp_time_delay,
      ramp_target_speed    => s_ramp_target_speed,
      ramp_fast_time       => s_ramp_fast_time,
      ramp_speed_increment => s_ramp_speed_increment,
      ramp_speed_decrement => s_ramp_speed_decrement,
      ramp_execute_out     => s_ramp_execute,
      echo_valid           => s_echo_valid,
      echo_cycles          => s_echo_cycles,
      quad1_valid          => quad1_valid,
      quad1_count          => quad1_count,
      quad2_valid          => quad2_valid,
      quad2_count          => quad2_count
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
      clk         => Clk,
      reset       => reset,
      trig_pin    => us_trig,
      echo_pin    => us_echo,
      echo_valid  => s_echo_valid,
      echo_cycles => s_echo_cycles
    );

  -- *** Ramp generator ***
  ramp_gen_inst : entity work.ramp_generator
    generic map(
      clk_freq => 12000000
    )
    port map
    (
      clk   => Clk,
      reset => reset,

      time_delay      => s_ramp_time_delay,
      target_speed    => s_ramp_target_speed,
      fast_time       => s_ramp_fast_time,
      speed_increment => s_ramp_speed_increment,
      speed_decrement => s_ramp_speed_decrement,
      execute         => s_ramp_execute,
      speed_out       => s_ramp_speed_out
    );

  -- *** PI Controllers ***
  pi_controller_mot1_inst : entity work.pi_controller
    generic map(
      clk_freq    => 12.0e6,
      pi_period   => 100.0,
      output_min  => 0,
      output_max  => 32767,
      dp_position => 8
    )
    port map
    (
      clk      => Clk,
      reset    => reset,
      auto     => '1',
      Kp       => mot1_pwm,
      Ki       => s_pi_ki,
      setpoint => s_pi_sp,
      pv       => x"0000", -- TODO replace with actual process variable, calculate it from encoders
      output   => s_pi_mot1_output
    );
    pi_controller_mot2_inst : entity work.pi_controller
    generic map(
      clk_freq    => 12.0e6,
      pi_period   => 100.0,
      output_min  => 0,
      output_max  => 32767,
      dp_position => 8
    )
    port map
    (
      clk      => Clk,
      reset    => reset,
      auto     => '1',
      Kp       => mot2_pwm,
      Ki       => s_pi_ki,
      setpoint => s_pi_sp,
      pv       => x"0000", -- TODO replace with actual process variable, calculate it from encoders
      output   => s_pi_mot2_output
    );

  -- *** Quadrature decoders ***
  quad_decoder1_inst : entity work.quadrature_decoder
    generic map(
      clk_freq => 12000000,
      ppr      => 1024
    )
    port map
    (
      clk         => Clk,
      reset       => reset,
      quad        => quad1,
      count_valid => quad1_valid,
      count_out   => quad1_count
    );

  quad_decoder2_inst : entity work.quadrature_decoder
    generic map(
      clk_freq => 12000000,
      ppr      => 1024
    )
    port map
    (
      clk         => Clk,
      reset       => reset,
      quad        => quad2,
      count_valid => quad2_valid,
      count_out   => quad2_count
    );

  main : process (clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;

      --* Controller selection (PI/Ramp)
      if s_pi_enable = '0' then
        -- Use PI controller output for motor speed
        si_speed_mot1 <= s_pi_mot1_output;
        si_speed_mot2 <= s_pi_mot2_output;
      else
        -- Use ramp generator output for motor speed
        si_speed_mot1 <= s_ramp_speed_out;
        si_speed_mot2 <= s_ramp_speed_out;
      end if;

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
