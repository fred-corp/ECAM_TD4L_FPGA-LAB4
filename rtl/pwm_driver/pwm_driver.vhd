---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab : Robot project
-- Author : Frédéric Druppel
-- File content : PWM driver
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pwm_driver is
  generic (
    clk_freq : real := 10.0e6; --* clock frequency in Hz
    pwm_freq : real := 10.0e3 --* PWM frequency in Hz
  );
  port (
    clk   : in std_logic; --* Main clock
    reset : in std_logic; --* Reset signal (active high)

    -- input PWM data
    pwm_data : in std_logic_vector(15 downto 0); --* PWM data input

    -- PWM outputs
    pwm_out_1 : out std_logic; --* PWM output 1
    pwm_out_2 : out std_logic --* PWM output 2
  );
end entity;

architecture rtl of pwm_driver is
  -- calculate width based on clk_freq and pwm_freq
  constant pwm_width : integer := integer(ceil(log2(clk_freq / pwm_freq))); --* Width of PWM counter

  signal pwm_out_1_reg : std_logic := '0'; --* PWM output 1 register
  signal pwm_out_2_reg : std_logic := '0'; --* PWM output 2 register

  signal pwm_period : unsigned(pwm_width - 1 downto 0) := to_unsigned(integer(clk_freq / pwm_freq), pwm_width); --* PWM period
  signal counter    : unsigned(pwm_width - 1 downto 0) := (others => '0'); --* PWM counter

  signal pwm_dir   : std_logic                        := '0'; --* PWM direction
  signal pwm_value : unsigned(pwm_width - 1 downto 0) := (others => '0'); --* PWM value

begin

  -- process to generate PWM signals
  main : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        counter       <= (others => '0');
        pwm_dir       <= '0';
        pwm_value     <= (others => '0');
        pwm_out_1_reg <= '0';
        pwm_out_2_reg <= '0';
      else
        pwm_dir   <= pwm_data(pwm_data'high); -- MSB of pwm_data determines direction
        pwm_value <= unsigned(pwm_data(pwm_width - 1 downto 0)); -- resize pwm_data to match pwm_width

        if counter < pwm_period then
          counter <= counter + 1;
        else
          counter <= (others => '0');
        end if;

        -- generate PWM output signals based on input data
        if pwm_dir = '1' then
          if counter < pwm_value then
            pwm_out_1_reg <= '1';
          else
            pwm_out_1_reg <= '0';
            pwm_out_2_reg <= '1';
          end if;
        else
          if counter < pwm_value then
            pwm_out_2_reg <= '1';
          else
            pwm_out_2_reg <= '0';
            pwm_out_1_reg <= '1';
          end if;
        end if;

        -- reset PWM output signals if pwm_value is 0
        if pwm_value = 0 then
          pwm_out_1_reg <= '0';
          pwm_out_2_reg <= '0';
        end if;
      end if;
    end if;
  end process main;
  -- assign PWM output signals
  pwm_out_1 <= pwm_out_1_reg;
  pwm_out_2 <= pwm_out_2_reg;

end architecture rtl;