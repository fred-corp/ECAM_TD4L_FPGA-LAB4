---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab: Robot project
-- Author:
-- File content: Robot project toplevel
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
  port (
    clk  : in std_logic;
    rstn : in std_logic;

    uart_txd : out std_logic;
    uart_rxd : in std_logic;

    us_trig : out std_logic; -- Ultrasound Trigger
    us_echo : in std_logic := '0'; -- Ultrasound Echo

    quad1 : in std_logic_vector(1 downto 0) := (others => '0'); -- Quadrature Encoder 1
    quad2 : in std_logic_vector(1 downto 0) := (others => '0'); -- Quadrature Encoder 2

    pwm_mot1 : out std_logic_vector(1 downto 0); -- Motor 1 control
    pwm_mot2 : out std_logic_vector(1 downto 0); -- Motor 2 control

    led_r : out std_logic;
    led_g : out std_logic;
    led_b : out std_logic
  );
end entity top;

architecture rtl of top is
  -- Reset
  signal reset : std_logic;

  -- UART
  signal uart_tx_valid : std_logic := '0';
  signal uart_tx_ready : std_logic;
  signal uart_tx_data  : std_logic_vector(7 downto 0);
  signal uart_rx_valid : std_logic := '0';
  signal uart_rx_data  : std_logic_vector(7 downto 0);

  -- APB
  signal apb_paddr   : std_logic_vector(7 downto 0);
  signal apb_psel    : std_logic;
  signal apb_penable : std_logic;
  signal apb_pwrite  : std_logic;
  signal apb_pwdata  : std_logic_vector(15 downto 0);
  signal apb_prdata  : std_logic_vector(15 downto 0);

  -- LEDs
  signal led_out_r : std_logic := '0';
  signal led_out_g : std_logic := '0';
  signal led_out_b : std_logic := '0';

  signal counter : unsigned(23 downto 0) := (others => '0');
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
      clk       => Clk,
      reset     => reset,
      led_r => led_out_r,
      led_g => led_out_g,
      led_b => led_out_b,
      s_paddr   => apb_paddr,
      s_psel    => apb_psel,
      s_penable => apb_penable,
      s_pwrite  => apb_pwrite,
      s_pwdata  => apb_pwdata,
      s_prdata  => apb_prdata
    );

  -------- TO BE REMOVED DURING EXERCISES -----------------
  -- led_out_r <= counter(counter'high);
  -- led_out_g <= counter(counter'high);
  -- led_out_b <= counter(counter'high);

  -- olo_base_fifo_sync_inst : entity work.olo_base_fifo_sync
  --   generic map(
  --     Width_g => 8,
  --     Depth_g => 32
  --   )
  --   port map
  --   (
  --     Clk       => Clk,
  --     Rst       => reset,
  --     In_Data   => uart_rx_data,
  --     In_Valid  => uart_rx_valid,
  --     In_Ready  => open,
  --     Out_Data  => uart_tx_data,
  --     Out_Valid => uart_tx_valid,
  --     Out_Ready => uart_tx_ready
  --   );

  main : process (clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;
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
