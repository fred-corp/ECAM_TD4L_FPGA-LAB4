---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab : Robot project
-- Author : Frédéric Druppel
-- File content : Configuration registers
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity config_regs is
  port (
    clk   : in std_logic; --* Main clock
    reset : in std_logic; --* Reset signal (active high)

    -- APB interface
    s_paddr   : in std_logic_vector(7 downto 0); --* APB address
    s_psel    : in std_logic; --* APB select
    s_penable : in std_logic; --* APB enable
    s_pwrite  : in std_logic; --* APB write
    s_pwdata  : in std_logic_vector(15 downto 0); --* APB write data
    s_prdata  : out std_logic_vector(15 downto 0); --* APB read data

    -- Outputs
    led_r : out std_logic; --* Red LED
    led_g : out std_logic; --* Green LED
    led_b : out std_logic; --* Blue LED

    mot1_pwm : out std_logic_vector(15 downto 0); --* Motor 1 PWM data
    mot2_pwm : out std_logic_vector(15 downto 0); --* Motor 2 PWM data

    -- PI controller
    pi_kp   : out std_logic_vector(15 downto 0); --* PI controller Kp
    pi_ki   : out std_logic_vector(15 downto 0); --* PI controller Ki
    pi_sp   : out std_logic_vector(15 downto 0); --* PI controller setpoint
    pi_enable : out std_logic; --* PI controller enable

    -- Ramp generator
    ramp_time_delay      : out std_logic_vector(15 downto 0); --* Ramp time delay
    ramp_target_speed    : out std_logic_vector(15 downto 0); --* Ramp target speed
    ramp_fast_time       : out std_logic_vector(15 downto 0); --* Ramp fast time
    ramp_speed_increment : out std_logic_vector(15 downto 0); --* Ramp speed increment
    ramp_speed_decrement : out std_logic_vector(15 downto 0); --* Ramp speed decrement
    ramp_execute_out     : out std_logic; --* Ramp execute output

    -- Inputs
    -- Distance driver
    echo_valid  : in std_logic; --* Echo signal valid flag
    echo_cycles : in unsigned(15 downto 0); --* Duration of the echo signal

    -- Encoders
    quad1_valid : in std_logic; --* Quadrature Encoder 1 valid
    quad1_count : in std_logic_vector(15 downto 0); --* Quadrature Encoder 1 data
    quad2_valid : in std_logic; --* Quadrature Encoder 2 valid
    quad2_count : in std_logic_vector(15 downto 0) --* Quadrature Encoder 2 data
  );
end entity config_regs;

architecture rtl of config_regs is
  signal s_led_r : std_logic := '0'; --* Red LED output signal
  signal s_led_g : std_logic := '0'; --* Green LED output signal
  signal s_led_b : std_logic := '0'; --* Blue LED output signal

  signal s_mot1_pwm : std_logic_vector(15 downto 0) := (others => '0'); --* Motor 1 PWM data
  signal s_mot2_pwm : std_logic_vector(15 downto 0) := (others => '0'); --* Motor 2 PWM data

  signal s_echo_cycles : unsigned(15 downto 0) := (others => '0'); --* Duration of the echo signal

  signal s_quad1_count : std_logic_vector(15 downto 0) := (others => '0'); --* Quadrature Encoder 1 data
  signal s_quad2_count : std_logic_vector(15 downto 0) := (others => '0'); --* Quadrature Encoder 2 data

  signal s_pi_kp : std_logic_vector(15 downto 0) := (others => '0'); --* PI controller Kp
  signal s_pi_ki : std_logic_vector(15 downto 0) := (others => '0'); --* PI controller Ki
  signal s_pi_sp : std_logic_vector(15 downto 0) := (others => '0'); --* PI controller setpoint
  signal s_pi_enable : std_logic := '0'; --* PI controller enable

  signal s_ramp_time_delay : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp time delay
  signal s_ramp_target_speed : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp target speed
  signal s_ramp_fast_time : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp fast time
  signal s_ramp_speed_increment : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp speed increment
  signal s_ramp_speed_decrement : std_logic_vector(15 downto 0) := (others => '0'); --* Ramp speed decrement
  signal s_ramp_execute : std_logic := '0'; --* Ramp execute signal

begin
  main : process (clk)
  begin
    if rising_edge(clk) then
      --* APB interface
      if s_psel = '1' then
        if s_pwrite = '1' then
          if s_penable = '1' then
            --* Write registers
            -- LED registers
            if s_paddr = x"00" then
              s_led_r <= s_pwdata(0);
            elsif s_paddr = x"02" then
              s_led_g <= s_pwdata(0);
            elsif s_paddr = x"04" then
              s_led_b <= s_pwdata(0);

              -- Motor PWM registers
            elsif s_paddr = x"06" then
              s_mot1_pwm <= s_pwdata;
            elsif s_paddr = x"08" then
              s_mot2_pwm <= s_pwdata;

            -- PI controller registers
            elsif s_paddr = x"14" then
              s_pi_kp <= s_pwdata; -- Kp value
            elsif s_paddr = x"16" then
              s_pi_ki <= s_pwdata; -- Ki value
            elsif s_paddr = x"18" then
              s_pi_sp <= s_pwdata; -- Setpoint value
            elsif s_paddr = x"20" then
              s_pi_enable <= s_pwdata(0); -- Enable PI controller


              -- Ramp registers
            elsif s_paddr = x"22" then
              s_ramp_time_delay <= s_pwdata; -- Ramp time delay
            elsif s_paddr = x"24" then
              s_ramp_target_speed <= s_pwdata; -- Ramp target speed
            elsif s_paddr = x"26" then
              s_ramp_fast_time <= s_pwdata; -- Ramp fast time
            elsif s_paddr = x"28" then
              s_ramp_speed_increment <= s_pwdata; -- Ramp speed s_ramp_speed_increment
            elsif s_paddr = x"30" then
              s_ramp_speed_decrement <= s_pwdata; -- Ramp speed decrement
            elsif s_paddr = x"32" then
              s_ramp_execute <= s_pwdata(0);
            else
              -- Unused registers, do nothing
            end if;
          end if;
        else
          if s_penable = '0' then
            --* Read registers
            -- LED registers
            if s_paddr = x"00" then
              s_prdata(0) <= s_led_r;
            elsif s_paddr = x"02" then
              s_prdata(0) <= s_led_g;
            elsif s_paddr = x"04" then
              s_prdata(0) <= s_led_b;

              -- Distance driver
            elsif s_paddr = x"05" then
              s_prdata <= std_logic_vector(s_echo_cycles);

              -- Motor PWM registers
            elsif s_paddr = x"06" then
              s_prdata <= s_mot1_pwm;
            elsif s_paddr = x"08" then
              s_prdata <= s_mot2_pwm;

              -- Quadrature encoder 1
            elsif s_paddr = x"10" then
              s_prdata <= s_quad1_count;
              -- Quadrature encoder 2
            elsif s_paddr = x"12" then
              s_prdata <= s_quad2_count;

              -- PI controller
            elsif s_paddr = x"14" then
              s_prdata <= s_pi_kp; -- Kp value
            elsif s_paddr = x"16" then
              s_prdata <= s_pi_ki; -- Ki value
            elsif s_paddr = x"18" then
              s_prdata <= s_pi_sp; -- Setpoint value
            elsif s_paddr = x"20" then
              s_prdata(0) <= s_pi_enable; -- Enable PI controller

              -- Ramp registers
            elsif s_paddr = x"22" then
              s_prdata <= s_ramp_time_delay; -- Ramp time delay
            elsif s_paddr = x"24" then
              s_prdata <= s_ramp_target_speed; -- Ramp target speed
            elsif s_paddr = x"26" then
              s_prdata <= s_ramp_fast_time; -- Ramp fast time
            elsif s_paddr = x"28" then
              s_prdata <= s_ramp_speed_increment; -- Ramp speed increment
            elsif s_paddr = x"30" then
              s_prdata <= s_ramp_speed_decrement; -- Ramp speed decrement
            elsif s_paddr = x"32" then
              s_prdata(0) <= s_ramp_execute; -- Ramp execute signal

            else
              s_prdata <= x"0123";
            end if;
          end if;
        end if;
      end if;

      --* Valid signal handling
      -- Distance driver
      if echo_valid = '1' then
        s_echo_cycles <= echo_cycles; -- Store the duration of the echo signal
      end if;

      -- Quadrature encoders
      if quad1_valid = '1' then
        s_quad1_count <= quad1_count; -- Store the quadrature encoder 1 data
      end if;
      if quad2_valid = '1' then
        s_quad2_count <= quad2_count; -- Store the quadrature encoder 2 data
      end if;

      --* Reset signal
      if reset = '1' then
        s_led_r        <= '0';
        s_led_g        <= '0';
        s_led_b        <= '0';
        s_mot1_pwm     <= (others => '0');
        s_mot2_pwm     <= (others => '0');
        s_echo_cycles  <= (others => '0');
        s_ramp_execute <= '0';
      end if;
    end if;
  end process main;

  --* Output signals
  -- LED signals
  led_r <= s_led_r;
  led_g <= s_led_g;
  led_b <= s_led_b;

  -- Motor signals
  mot1_pwm <= s_mot1_pwm;
  mot2_pwm <= s_mot2_pwm;

  -- PI controller signals
  pi_kp <= s_pi_kp;
  pi_ki <= s_pi_ki;
  pi_sp <= s_pi_sp;
  pi_enable <= s_pi_enable;

  -- Ramp generator signals
  ramp_time_delay <= s_ramp_time_delay; -- Ramp time delay
  ramp_target_speed <= s_ramp_target_speed; -- Ramp target speed
  ramp_fast_time <= s_ramp_fast_time; -- Ramp fast time
  ramp_speed_increment <= s_ramp_speed_increment; -- Ramp speed increment
  ramp_speed_decrement <= s_ramp_speed_decrement; -- Ramp speed decrement
  ramp_execute_out <= s_ramp_execute; -- Ramp execute output

end architecture;