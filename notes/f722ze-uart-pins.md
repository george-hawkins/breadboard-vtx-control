F722ZE USART pins
=================

Pin information taken from the STM32F722ZE [datasheet](https://www.st.com/resource/en/datasheet/stm32f722ze.pdf):

* UART1_TX PA9/PB6
* UART2_TX PA2/PD5
* UART3_TX PB10/PC10/PD8
* UART4_TX PA0/PC10/PH13
* UART5_TX PC12
* UART6_TX PC6/PG14
* UART7_TX PE8/PF7
* UART8_TX PE1

* UART1_RX PA10/PB7
* UART2_RX PA3/PD6
* UART3_RX PB11/PC11/PD9
* UART4_RX PA1/PC11/PH14/PI9
* UART5_RX PD2
* UART6_RX PC7/PG9
* UART7_RX PE7/PF6
* UART8_RX PE0

It turns out it would have been much easier to find this information in [`drivers/serial_uart_stm32f7xx.c`](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/drivers/serial_uart_stm32f7xx.c).

Notes:

* Yes - PC10 can be used by UART3_TX or UART4_TX and PC11 can be used by UART3_RX or UART4_RX.
* In most cases,the the RX pin is just after the TX pin, e.g. PA9 and PA10, but for some cases it's before, e.g. UART8, or there's no such relationship, e.g. UART5.
* It is not the case that where there seems to be an obvious pair, e.g. PA9 and PA10 for the TX and RX pins for UART1, that those pins have to be used in combination, e.g. PB7 is an alternative to PA10 and can be used just as well in combination with PA9.
* Most UARTs have as many options for the TX pin as the RX pin - this isn't the case for UART4.

UART pins on the Zio headers
----------------------------

The following UART pins are accessible via the Zio headers.

* UART1_TX PB6
* UART1_RX -

* UART2_TX PD5
* UART2_RX PA3/PD6

* UART3_TX PB10/PC10
* UART3_RX PB11/PC11

* UART4_TX PA0/PC10
* UART4_RX PC11

* UART5_TX PC12
* UART5_RX PD2

* UART6_TX PC6/PG14
* UART6_RX PC7/PG9

* UART7_TX PE8/PF7
* UART7_RX PE7

* UART8_TX -
* UART8_RX PE0

Pins PC10, PC11, PC12, PD2, PD5, PD6, PE0, PE7, PG9 and PG14, are not specified in `fullTimerHardware` in `src/main/drivers/timer_stm32f7xx.c`. I thought this _might_ be relevant but it is not. The `G` values may not be available until one defines `TARGET_IO_PORTG` in `target.h`.
