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
    type UART_STATUS is
        (
            WRITE_ADDRESS, WRITE_DATA0, WRITE_DATA1, WRITE_APB_SETUP, WRITE_APB_EXECUTE, WRITE_APB_DONE, WRITE_ANSWER_HEADER, WRITE_ANSWER_OK,
            READ_ADDRESS, READ_APB_SETUP, READ_APB_EXECUTE, READ_APB_DONE, READ_ANSWER_HEADER, READ_ANSWER_DATA0, READ_ANSWER_DATA1,
            IDLE
        );
    
    signal state : UART_STATUS := IDLE;
    signal write : std_logic := '0';
    signal apb_data : std_logic_vector(15 downto 0);
    signal address : std_logic_vector(7 downto 0);
    signal wr_data : std_logic_vector(15 downto 0);

begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
            end if;

            case state is
                when IDLE =>
                    if rx_valid = '1' then
                        if rx_data = x"AA" then
                            state <= WRITE_ADDRESS;
                            write <= '1';
                        elsif rx_data = x"55" then
                            state <= READ_ADDRESS;
                            write <= '0';
                        else
                            state <= IDLE;
                        end if;
                    else
                        state <= IDLE;
                    end if;
                when WRITE_ADDRESS =>
                    if rx_valid = '1' then 
                        address <= rx_data;
                        state <= WRITE_DATA0;
                    end if;
                when WRITE_DATA0 =>
                    if rx_valid = '1' then 
                        wr_data(15 downto 8) <= rx_data;
                        state <= WRITE_DATA1;
                    end if;
                when WRITE_DATA1 =>
                    if rx_valid = '1' then 
                        wr_data(7 downto 0) <= rx_data;
                        state <= APB_SETUP;
                    end if;
                when APB_SETUP =>
                    m_psel <= '1';
                    m_paddr <= address;
                    m_pwrite <= write;
                    m_pwdata <= wr_data;
                    m_penable <= '0';
                    state <= APB_EXECUTE;
                when APB_EXECUTE =>
                    m_penable <= '1';
                    apb_data <= m_prdata;
                    state <= APB_DONE;
                when APB_DONE =>
                    m_psel <= '0';
                    if write = '1' then
                        state <= WRITE_ANSWER_HEADER;
                    else
                        state <= READ_ANSWER_HEADER;
                    end if;
                when WRITE_ANSWER_HEADER =>
                    tx_data <= x"AA";
                    tx_valid <= '1';
                    if tx_ready = '1' then
                        tx_valid <= '0';
                        state <= WRITE_ANSWER_OK;
                    end if;
                when WRITE_ANSWER_OK =>
                    tx_data <= x"00";
                    tx_valid <= '1';
                    if tx_ready = '1' then
                        tx_valid <= '0';
                        state <= IDLE;
                    end if;
                
                when others =>
                    null;
            end case;

        end if;
    end process;
end rtl;
