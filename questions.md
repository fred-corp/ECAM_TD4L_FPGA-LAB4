# Questions

## Specification analysis

* What functionalities are required to make this work?
  * PWM Block
  * UART
  * Quadrature Decoder
  * HC-SR-04
  * P/I Controller
  * Ramp accel/decel
* How would you store the configuration of the design?
  * Registers/APB
* How do you connect interfaces ?
* List the pins needed on the PMOD connectors.
* What interfaces are synchronous or asynchronous?
  * RS232 -> Async
  * PWM IO -> Async
  * Encoder inputs -> Async
  * HC-SR04 input/control -> Async

## USB to UART Interface

Explain what the UART interfaces are and how your block is going to use them. One interface is AXI
Stream2

* Which signals go to FPGA pins?
  * Uart_Tx & Uart_Rx

From the description above explain:

* What is the address size ?
  * 8 bits
* What is the data size?
  * 8 bits
* Describe the FSM states and transitions
* What is the APB required signals? What size are they ?
  * PEnable : 1b
  * PSelX : 1b
  * PAddr : **8b**/16b/32b
  * PWData : 8b/**16b**/32b
  * PWrite : 1b
  * PRData : 8b/**16b**/32b
  * PCLK : 1b
  * PNReset : 1b
