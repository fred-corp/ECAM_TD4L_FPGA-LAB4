--
-- Synopsys
-- Vhdl wrapper for top level design, written on Sat Mar 22 20:44:31 2025
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wrapper_for_top is
   port (
      clk : in std_logic;
      rstn : in std_logic;
      uart_txd : out std_logic;
      uart_rxd : in std_logic;
      us_trig : out std_logic;
      us_echo : in std_logic;
      quad1 : in std_logic_vector(1 downto 0);
      quad2 : in std_logic_vector(1 downto 0);
      pwm_mot1 : out std_logic_vector(1 downto 0);
      pwm_mot2 : out std_logic_vector(1 downto 0);
      led_r : out std_logic;
      led_g : out std_logic;
      led_b : out std_logic
   );
end wrapper_for_top;

architecture rtl of wrapper_for_top is

component top
 port (
   clk : in std_logic;
   rstn : in std_logic;
   uart_txd : out std_logic;
   uart_rxd : in std_logic;
   us_trig : out std_logic;
   us_echo : in std_logic;
   quad1 : in std_logic_vector (1 downto 0);
   quad2 : in std_logic_vector (1 downto 0);
   pwm_mot1 : out std_logic_vector (1 downto 0);
   pwm_mot2 : out std_logic_vector (1 downto 0);
   led_r : out std_logic;
   led_g : out std_logic;
   led_b : out std_logic
 );
end component;

signal tmp_clk : std_logic;
signal tmp_rstn : std_logic;
signal tmp_uart_txd : std_logic;
signal tmp_uart_rxd : std_logic;
signal tmp_us_trig : std_logic;
signal tmp_us_echo : std_logic;
signal tmp_quad1 : std_logic_vector (1 downto 0);
signal tmp_quad2 : std_logic_vector (1 downto 0);
signal tmp_pwm_mot1 : std_logic_vector (1 downto 0);
signal tmp_pwm_mot2 : std_logic_vector (1 downto 0);
signal tmp_led_r : std_logic;
signal tmp_led_g : std_logic;
signal tmp_led_b : std_logic;

begin

tmp_clk <= clk;

tmp_rstn <= rstn;

uart_txd <= tmp_uart_txd;

tmp_uart_rxd <= uart_rxd;

us_trig <= tmp_us_trig;

tmp_us_echo <= us_echo;

tmp_quad1 <= quad1;

tmp_quad2 <= quad2;

pwm_mot1 <= tmp_pwm_mot1;

pwm_mot2 <= tmp_pwm_mot2;

led_r <= tmp_led_r;

led_g <= tmp_led_g;

led_b <= tmp_led_b;



u1:   top port map (
		clk => tmp_clk,
		rstn => tmp_rstn,
		uart_txd => tmp_uart_txd,
		uart_rxd => tmp_uart_rxd,
		us_trig => tmp_us_trig,
		us_echo => tmp_us_echo,
		quad1 => tmp_quad1,
		quad2 => tmp_quad2,
		pwm_mot1 => tmp_pwm_mot1,
		pwm_mot2 => tmp_pwm_mot2,
		led_r => tmp_led_r,
		led_g => tmp_led_g,
		led_b => tmp_led_b
       );
end rtl;
