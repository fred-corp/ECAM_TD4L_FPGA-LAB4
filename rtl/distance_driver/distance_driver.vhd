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
    clk_freq  : real := 12.0e6; --* Clock frequency in Hz
    ms_period : real := 100.0; --* Ultrasonic sensor trigger period in ms
    us_width  : real := 10.0 --* Ultrasonic sensor pulse width in µs
  );
  port (
    clk   : in std_logic; --* Main clock
    reset : in std_logic; --* Reset signal (active high)

    trig_pin : out std_logic; --* Trigger pin for the ultrasonic sensor
    echo_pin : in std_logic; --* Echo pin for the ultrasonic sensor
    -- distance : out std_logic_vector(15 downto 0) --* Distance measurement output
    echo_valid  : out std_logic := '0'; --* Echo signal valid flag
    echo_cycles : out unsigned(15 downto 0) := (others => '0') --* Duration of the echo signal
  );
end entity;

architecture rtl of distance_driver is
  constant pulse_delay   : integer := integer(clk_freq * us_width/real(1000000)); --* Pulse width in clock cycles (120 for 10us @ 12MHz)
  constant trigger_delay : integer := integer(clk_freq * ms_period/real(1000)); --* Trigger delay in clock cycles (1200000 for 100ms @ 12MHz)
  
  -- Calculate width based on clk_freq and us_period
  constant counter_width : integer := integer(ceil(log2(clk_freq))); --* Width of the counter

  signal counter       : unsigned(counter_width - 1 downto 0) := (others => '0'); --* Counter for timing
  signal echo_duration : unsigned(15 downto 0)                := (others => '0'); --* Duration of echo signal
  signal s_echo_cycles : unsigned(15 downto 0)                := (others => '0'); --* Duration of the echo signal
  -- signal distance_mm   : unsigned(15 downto 0)                := (others => '0'); --* Distance in mm

  signal echo_previous : std_logic := '0'; --* Previous state of the echo signal

begin
  main : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        counter       <= (others => '0');
        trig_pin      <= '0';
        echo_duration <= (others => '0');
        -- distance_mm   <= (others => '0');
      else
        -- generate a trigger pulse (us_width every us_period)
        counter <= counter + 1;
        echo_previous <= echo_pin; -- Update the previous state of the echo signal
        
        if counter < pulse_delay then
          trig_pin <= '1'; -- Trigger the ultrasonic sensor
        else
          trig_pin <= '0'; -- Stop triggering
        end if;
        
        if echo_pin = '1' and echo_duration < x"FFFF" then
          echo_duration <= echo_duration + 1; -- Count the duration of the echo signal
        end if;
        
        if echo_pin = '0' and echo_previous = '1' then
          s_echo_cycles <= echo_duration; -- Store the duration of the echo signal
          echo_duration <= (others => '0'); -- Reset the duration counter
          echo_valid <= '1'; -- Set the echo valid flag
        else 
          echo_valid <= '0'; -- Clear the echo valid flag
        end if;

        if counter = integer(trigger_delay) then
          counter <= (others => '0');
        end if;
      end if;
    end if;

  end process main;

  -- Assign the echo_cycles output
  echo_cycles <= s_echo_cycles;
end architecture rtl;