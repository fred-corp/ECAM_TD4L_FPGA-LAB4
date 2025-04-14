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
        clk   : in std_logic;
        reset  : in std_logic;

        -- APB interface
        s_paddr : in std_logic_vector(7 downto 0);
        s_psel : in std_logic;
        s_penable : in std_logic;
        s_pwrite : in std_logic;
        s_pwdata : in std_logic_vector(15 downto 0);
        s_prdata : out std_logic_vector(15 downto 0);

        -- Outputs
        led_r : out std_logic;
        led_g : out std_logic;
        led_b : out std_logic;

        mot1_pwm : out std_logic_vector(15 downto 0);
        mot2_pwm : out std_logic_vector(15 downto 0)
    );
end entity config_regs;

architecture rtl of config_regs is

begin
  main : process (clk)
  begin
    if rising_edge(clk) then
      if s_pwrite = '1' then
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
      else
        s_prdata <= x"0123";
      end if;
    end if;
    end process main;

end architecture;