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
        reset  : in std_logic; --* Reset signal (active high)

        -- APB interface
        s_paddr : in std_logic_vector(7 downto 0); --* APB address
        s_psel : in std_logic; --* APB select
        s_penable : in std_logic; --* APB enable
        s_pwrite : in std_logic; --* APB write
        s_pwdata : in std_logic_vector(15 downto 0); --* APB write data
        s_prdata : out std_logic_vector(15 downto 0); --* APB read data

        -- Outputs
        led_r : out std_logic; --* Red LED
        led_g : out std_logic; --* Green LED
        led_b : out std_logic; --* Blue LED

        mot1_pwm : out std_logic_vector(15 downto 0); --* Motor 1 PWM data
        mot2_pwm : out std_logic_vector(15 downto 0); --* Motor 2 PWM data

        -- Inputs
        echo_cycles : in unsigned(15 downto 0) --* Duration of the echo signal
    );
end entity config_regs;

architecture rtl of config_regs is

begin
  main : process (clk)
  begin
    if rising_edge(clk) then
      if s_psel = '1' then
        if s_pwrite = '1' then
          if s_penable = '1' then 
            -- Write registers
            -- LED registers
            if s_paddr = x"00" then
              led_r <= s_pwdata(0);
            elsif s_paddr = x"02" then
              led_g <= s_pwdata(0);
            elsif s_paddr = x"04" then
              led_b <= s_pwdata(0);

            -- Motor PWM registers
            elsif s_paddr = x"06" then
              mot1_pwm <= s_pwdata;
            elsif s_paddr = x"08" then
              mot2_pwm <= s_pwdata;
            end if;
          end if;
        else
          if s_penable = '0' then
            -- Read registers
            if s_paddr = x"00" then
              s_prdata <= std_logic_vector(echo_cycles);
            else
              s_prdata <= x"0123";
            end if;
          end if;
        end if;
      end if;
    end if;
    end process main;

end architecture;