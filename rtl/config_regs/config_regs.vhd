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

    ramp_execute : out std_logic; --* Ramp execute signal

    -- Inputs
    -- Distance driver
    echo_valid  : in std_logic; --* Echo signal valid flag
    echo_cycles : in unsigned(15 downto 0); --* Duration of the echo signal

    -- Ramp generator
    ramp_speed_out : in std_logic_vector(15 downto 0); --* Ramp speed output

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

  signal s_ramp_execute : std_logic := '0'; --* Ramp execute signal

  signal s_quad1_count : std_logic_vector(15 downto 0) := (others => '0'); --* Quadrature Encoder 1 data
  signal s_quad2_count : std_logic_vector(15 downto 0) := (others => '0'); --* Quadrature Encoder 2 data

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

              -- Ramp registers
            elsif s_paddr = x"32" then
              s_ramp_execute <= s_pwdata(0);
            end if;
          end if;
        else
          if s_penable = '0' then
            --* Read registers
            -- Distance driver
            if s_paddr = x"00" then
              s_prdata <= std_logic_vector(s_echo_cycles);

              -- Ramp speed
            elsif s_paddr = x"02" then
              s_prdata <= ramp_speed_out;

              -- Quadrature encoder 1
            elsif s_paddr = x"10" then
              s_prdata <= s_quad1_count;
              -- Quadrature encoder 2
            elsif s_paddr = x"12" then
              s_prdata <= s_quad2_count;
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
        s_led_r       <= '0';
        s_led_g       <= '0';
        s_led_b       <= '0';
        mot1_pwm      <= (others => '0');
        mot2_pwm      <= (others => '0');
        s_echo_cycles <= (others => '0');
        ramp_execute  <= '0';
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

  -- Ramp speed signal
  ramp_execute <= s_ramp_execute;

end architecture;