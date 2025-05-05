---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab : Robot project
-- Author : Frédéric Druppel
-- File content : Ramp generator
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ramp_generator is
  generic (
    clk_freq : integer := 12_000_000 --* Clock frequency in Hz
  );
  port (
    clk   : in std_logic; --* Main clock
    reset : in std_logic; --* Reset signal (active high)

    time_delay      : in std_logic_vector(15 downto 0); --* Time delay input ms
    target_speed    : in std_logic_vector(15 downto 0); --* Target speed input
    fast_time       : in std_logic_vector(15 downto 0); --* Fast time input ms
    speed_increment : in std_logic_vector(15 downto 0); --* Speed increment input
    speed_decrement : in std_logic_vector(15 downto 0); --* Speed decrement input
    execute         : in std_logic; --* Execute signal (active high)

    speed_out : out std_logic_vector(15 downto 0) --* Speed output

  );
end entity;

architecture rtl of ramp_generator is
  -- Calculate width based on clk_freq and us_period
  constant counter_width : integer := integer(ceil(log2(real(clk_freq)))) + (fast_time'length); --* Width of the counter

  type state_type is (IDLE, RAMP_UP, FAST, RAMP_DOWN); --* State machine states
  signal ramp_generator_state : state_type := IDLE; --* State machine state

  signal counter           : unsigned(counter_width - 1 downto 0) := (others => '0'); --* Counter for timing
  signal fast_time_cycles  : unsigned(counter_width - 1 downto 0) := (others => '0'); --* Fast time in clock cycles
  signal time_delay_cycles : unsigned(counter_width - 1 downto 0) := (others => '0'); --* Time delay in clock cycles
  signal speed_out_reg     : unsigned(15 downto 0)                := (others => '0'); --* Speed output register

begin
  main : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        counter              <= (others => '0'); --* Reset counter
        ramp_generator_state <= IDLE; --* Reset state machine
        speed_out_reg        <= (others => '0'); --* Reset speed output register
      else
        counter     <= counter + 1; --* Increment the counter

        case ramp_generator_state is
          when IDLE                =>
            speed_out_reg <= (others => '0');
            if execute = '1' then
              ramp_generator_state <= RAMP_UP; --* Transition to RAMP_UP state
              counter              <= (others => '0'); --* Reset counter
              fast_time_cycles     <= resize((unsigned(fast_time) * to_unsigned(clk_freq, 32)) / 1000, counter_width); --* Set fast time in clock cycles
              time_delay_cycles    <= resize((unsigned(time_delay) * to_unsigned(clk_freq, 32)) / 1000, counter_width); --* Set time delay in clock cycles
            end if;

          when RAMP_UP =>
            counter <= counter + 1;
            if speed_out_reg < unsigned(target_speed) and counter = 0 then
              speed_out_reg <= speed_out_reg + unsigned(speed_increment); --* Ramp up speed
            end if;

            if counter >= time_delay_cycles then
              counter <= (others => '0'); --* Reset counter
            end if;

            if speed_out_reg >= unsigned(target_speed) then
              counter              <= (others => '0'); --* Reset counter
              ramp_generator_state <= FAST; --* Transition to FAST state
            end if;

          when FAST =>
            if counter < fast_time_cycles then
              speed_out_reg <= unsigned(target_speed); --* Maintain target speed
              counter       <= counter + 1; --* Increment counter
            else
              counter              <= (others => '0'); --* Reset counter
              ramp_generator_state <= RAMP_DOWN; --* Transition to RAMP_DOWN state
            end if;

          when RAMP_DOWN =>
            counter <= counter + 1;
            if speed_out_reg > 0 and counter = 0 then
              speed_out_reg <= speed_out_reg - unsigned(speed_decrement); --* Ramp down speed
            end if;
            if counter >= time_delay_cycles then
              counter <= (others => '0'); --* Reset counter
            end if;

            if speed_out_reg  <= 0 then
              counter              <= (others => '0'); --* Reset counter
              ramp_generator_state <= IDLE; --* Transition back to IDLE state
            end if;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process main;

  -- Assign the speed output register to the output port
  speed_out <= std_logic_vector(speed_out_reg); --* Convert unsigned to std_logic_vector
end architecture rtl;