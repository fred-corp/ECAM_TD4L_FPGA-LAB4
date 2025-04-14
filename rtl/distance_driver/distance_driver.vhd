---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab : Robot project
-- Author : Frédéric Druppel
-- File content : Distance driver
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity distance_driver is
  generic (
    clk_freq  : real := 10.0e6; --! Clock frequency in Hz
    us_period : real := 500.0; --! Ultrasonic sensor trigger period in ms
    us_width  : real := 5.0 --! Ultrasonic sensor pulse width in µs
  );
  port (
    clk   : in std_logic; --! Main clock
    reset : in std_logic; --! Reset signal (active high)

    trig_pin : out std_logic; --! Trigger pin for the ultrasonic sensor
    echo_pin : in std_logic; --! Echo pin for the ultrasonic sensor
    distance : out std_logic_vector(15 downto 0) --! Distance measurement output
  );
end entity;

architecture rtl of distance_driver is
  constant pulse_delay   : integer := integer(clk_freq * us_width/real(1000000)); --! Pulse width in clock cycles
  constant trigger_delay : integer := integer(clk_freq * us_period/real(1000)); --! Trigger delay in clock cycles
  
  -- Calculate width based on clk_freq and us_period
  constant counter_width : integer := integer(ceil(log2(clk_freq))); --! Width of the counter

  signal counter       : unsigned(counter_width - 1 downto 0) := (others => '0'); --! Counter for timing
  signal echo_duration : unsigned(15 downto 0)                := (others => '0'); --! Duration of echo signal
  signal distance_mm   : unsigned(15 downto 0)                := (others => '0'); --! Distance in mm

begin
  main : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        counter       <= (others => '0');
        trig_pin      <= '0';
        echo_duration <= (others => '0');
        distance_mm   <= (others => '0');
      else
        -- generate a trigger pulse (us_width every us_period)
        counter <= counter + 1;
        if counter < pulse_delay then
          trig_pin <= '1'; -- Trigger the ultrasonic sensor
        else
          trig_pin <= '0'; -- Stop triggering
          if echo_pin = '1' then
            echo_duration <= echo_duration + 1; -- Count the duration of the echo signal
          else
            if echo_duration > 0 then
              distance_mm <= echo_duration * 171; -- Convert to mm (speed of sound in air is ~343 m/s)
              distance    <= std_logic_vector(distance_mm); -- Output the distance measurement
              echo_duration <= (others => '0'); -- Reset the duration counter
            end if;
          end if;
        end if;
        if counter = integer(clk_freq) then
          counter <= (others => '0');
        end if;
      end if;
    end if;

  end process main;
end architecture rtl;