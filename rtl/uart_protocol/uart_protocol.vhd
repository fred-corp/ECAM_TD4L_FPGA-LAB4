---------------------------------------------------------------------------------------------------
-- ECAM Brussels
-- FPGA lab: Robot project
-- Author:
-- File content: UART protocol handler
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_protocol is
    port (
        clk   : in std_logic;
        reset  : in std_logic;

        -- UART interface
        rx_data : in std_logic_vector(7 downto 0);
        rx_valid : in std_logic;

        tx_data : out std_logic_vector(7 downto 0);
        tx_valid : out std_logic;
        tx_ready : in std_logic;

        -- APB interface
        m_paddr : out std_logic_vector(7 downto 0);
        m_psel : out std_logic;
        m_penable : out std_logic;
        m_pwrite : out std_logic;
        m_pwdata : out std_logic_vector(15 downto 0);
        m_prdata : in std_logic_vector(15 downto 0)
    );
end entity uart_protocol;

architecture rtl of uart_protocol is

begin


end architecture;