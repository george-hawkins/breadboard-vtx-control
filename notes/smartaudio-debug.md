In `src/main/io/vtx_smartaudio.c` we find:

    debugSerialPort = openSerialPort(DPRINTF_SERIAL_PORT, FUNCTION_NONE, NULL, NULL, 115200, MODE_RXTX, 0);

So it opens `DPRINTF_SERIAL_PORT` at 115.2kpbs.

In `vtx_smartaudio.h` we find:

    #ifdef USE_SMARTAUDIO_DPRINTF
    #define DPRINTF_SERIAL_PORT SERIAL_PORT_USART3

And we can find `SERIAL_PORT_USART3` in `src/main/drivers/serial_pinconfig.c`:

    { SERIAL_PORT_USART3, IO_TAG(UART3_RX_PIN), IO_TAG(UART3_TX_PIN), IO_TAG(INVERTER_PIN_UART3) },

And in `src/main/target/NUCLEOF722/target.h` we find:

    #define UART3_RX_PIN PD9
    #define UART3_TX_PIN PD8

In the Nucleo-F77ZE manual we find:

> The USART3 interface available on PD8 and PD9 of the STM32 can be connected either to ST-LINK or to ST morpho connector.

So we should be able to access USART3 via the virtual com port (VCP) created for the ST-LINK.

Disappointingly, for reasons that are unclear to me, this wasn't the case.

So in Configurator, I toggled off _Serial Rx_ for _UART2_ and...

Added the following line to `src/main/target/NUCLEOF722/target.h`:

    #define USE_SMARTAUDIO_DPRINTF

And changed the line mentioned above in `src/main/io/vtx_smartaudio.h` that specified `SERIAL_PORT_USART3` to:

    #define DPRINTF_SERIAL_PORT SERIAL_PORT_USART2

Then I plugged in my 3.3V USB-to-serial cable, connecting its ground pin to one of the board GND pins and connecting RX and TX to PD6 and PD7, i.e. UART2, and:

    $ screen /dev/ttyUSB0 115200

I rebooted the board, nothing happened so I swapped RX and TX and tried again, this time things worked:

    $ screen /dev/ttyUSB0 115200
    smartAudioInit: OK
    vtxSmartAudioInit 1 power levels recorded
    smartAudioGetSettings
    process: sending queue
    received settings
    processResponse: rawPowerValue is 0, legacy power is 0
    processResponse: power changed from index 0 to index 1
    Current status: version: 2
      mode(0x10): fmode=chan pit=off  inb=off outb=off lock=unlocked deferred=off
      channel: 37 freq: 5865 power: 1 powerval: 0 pitfreq: 0 BootIntoPitMode: no 
    smartAudioSetFreq: GETPIT
    sainit: willBootIntoPitMode is false
    process: sending queue
    saProcessResponse: GETPIT freq 5300
    Current status: version: 2
      mode(0x10): fmode=chan pit=off  inb=off outb=off lock=unlocked deferred=off
      channel: 37 freq: 5865 power: 1 powerval: 0 pitfreq: 5300 BootIntoPitMode: no 
    process: sending status change polling
    smartAudioGetSettings
    received settings
    processResponse: rawPowerValue is 0, legacy power is 0
    process: sending status change polling
    smartAudioGetSettings
    received settings
    processResponse: rawPowerValue is 0, legacy power is 0
    process: sending status change polling
    smartAudioGetSettings
    received settings
    processResponse: rawPowerValue is 0, legacy power is 0
    process: sending status change polling
    smartAudioGetSettings
    received settings
    processResponse: rawPowerValue is 0, legacy power is 0
    process: sending status change polling
    smartAudioGetSettings
    received settings
    processResponse: rawPowerValue is 0, legacy power is 0
