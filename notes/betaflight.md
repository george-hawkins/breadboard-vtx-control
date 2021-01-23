Notes on working with Betaflight
================================

The following page contains various notes accumulated while working on Betaflight

Branches
--------

Your primary Betaflight branches are:

* [4.2.5-nucleof722_min-redux](https://github.com/george-hawkins/betaflight/tree/4.2.5-nucleof722_min-redux) - where you've cleaned up things and just have a minimalist `NUCLEOF722_MIN` target along with a couple of minor bugfixes (related to things not compiling if certain features are undefined) and your support for booting into pit mode and supporting the non-standard Eachine TX805 pit mode behavior.
* [4.2.5-nucleof722_min](https://github.com/george-hawkins/betaflight/commits/4.2.5-nucleof722_min) - where you worked previously on creating the minimal target and tried out a few experimental features (like disabling VCP) which are discussed below but not included in 4.2.5-nucleof722_min-redux.

See [`NUCLEOF722_MIN/target.h`](https://github.com/george-hawkins/betaflight/blob/4.2.5-nucleof722_min-redux/src/main/target/NUCLEOF722_MIN/target.h) for my comprehensive minimalist `target.h` for the Nucleo-F722ZE board. Add see [`cli-diff-all.txt`](https://github.com/george-hawkins/betaflight/blob/4.2.5-nucleof722_min-redux/cli-diff-all.txt) for the settings file to with it.

I tried to get my change, to configure booting into pit mode, accepted by Betaflight (see [here](https://github.com/betaflight/betaflight/pull/10432)) but it's not currently considered acceptably generic in its present form.

Note: I've got a gist [here](https://gist.github.com/george-hawkins/9fbf557a41dcb063c480cd9152de6d32) that covers how Betaflight works with SmartAudio using `saSetMode`, `saQueueCmd` and various flags.

I also submitted by TX805 changes as a _draft_ PR [here](https://github.com/betaflight/betaflight/pull/10436). I also announced it [here](https://intofpv.com/t-betaflight-fix-for-toggling-pit-mode-via-tx-and-configurator?pid=124171) on InfoFPV but didn't get enough interest to feel it worth pushing (given that the Betaflight people are unwilling to incorporate product specific workarounds).

Space savings from undefining features
--------------------------------------

In `NUCLEOF722_MIN/target.h` there are comments that indicate the space saving gained by undefining various macro values, e.g. `USE_CLI`. These savings aren't independant, e.g. some macros enable whole areas of functionality while others just enable certain sections within those areas of functionality. But despite this, the numbers shown in `target.h` give some indication of the space savings possible.

Most of this information was gathered in a sequence of automated experiments on undefining a large number or macros, either individually or cummulatively. The results of these experiments are summarized in [`size-costs.md`](size-costs.md).

A few additional relevant macros were found after these experiments but nearly all were covered.

Working with Betaflight in the Eclipse IDE for Embedded C/C++ Developers
------------------------------------------------------------------------

I did almost all my work with Betaflight in `vim`. I took a start at getting it working with the version of the Eclipse IDE intended for embedded C/C++ developers - the relevant notes are in [`betaflight-eclipse.md`](betaflight-eclipse.md).

Basic steps when working with the Nucleo-F722ZE
-----------------------------------------------

Copy the existing target:

```
$ cp -r src/main/target/NUCLEOF722 src/main/target/NUCLEOF722_MIN
```

Modify the `target.h` file:

```
$ vi src/main/target/NUCLEOF722_MIN/target.h
```

Build the target:

```
$ rm obj/*.hex; make hex TARGET=NUCLEOF722_MIN
```

Copy the `.hex` file to the board:

```
$ cp obj/*.hex /media/$USER/NODE_F722ZE
```

List the sizes of functions and objects with static storage to get a handle on what's taking up space:

```
$ arm-none-eabi-nm --print-size --size-sort obj/main/betaflight_NUCLEOF722_MIN.elf
```

Run the Configurator:

```
$ /opt/betaflight/betaflight-configurator/betaflight-configurator
```

Valid UART pins
---------------

Oddly, the NUCLEOF722 `target.h` defines invalid pins for UART3 (see [here](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/target/NUCLEOF722/target.h#L82)).

So what are valid pins? It turns out that the easiest place to find these is in [`drivers/serial_uart_stm32f7xx.c`](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/drivers/serial_uart_stm32f7xx.c). E.g. there you can see that PA9 or PB6 can be used for the TX pin for UART1.

I tried out all the combinations possible for pins that are exposed via the Nucleo board's Zio headers. All expected combinations (except one) worked - the valid Zio accessible combinations are as follows:

* `UART1_TX_PIN` PB6
* `UART1_RX_PIN` NONE
* `UART2_RX_PIN` PD6 / PA3
* `UART2_TX_PIN` PD5
* `UART3_TX_PIN` PB10 / PC10
* `UART3_RX_PIN` PB11 / PC11
* `UART4_TX_PIN` PC10 / PA0
* `UART4_RX_PIN` PC11
* `UART5_TX_PIN` PC12
* `UART5_RX_PIN` PD2
* `UART6_TX_PIN` PC6
* `UART6_RX_PIN` PC7
* `UART7_TX_PIN` PE8 / PF7
* `UART7_RX_PIN` PE7
* `UART8_TX_PIN` NONE
* `UART8_RX_PIN` PE0

The pair that didn't work was:

* `UART6_TX_PIN` PG14
* `UART6_RX_PIN` PG9

To use G pins at all, you have to a definition for `TARGET_IO_PORTG` to `target.h` (in addition to the existing definitions for ports A to F) otherwise compilation fails. But evidently more is still required - I suspect this isn't anything fundamental and simply that G pins are not used (no other target currently specifies a G pin for anything) and so some minor setup has been missed out for G.

For more on the UART pins (not just those above that are accessible via the Zio headers), see [`f722ze-uart-pins.md`](f722ze-uart-pins.md).

Note: like `timerHardware` (discussed below), if you add or remove UARTs or change their pin assignments then you have to reset all settings, after flashing the new firmware, before these changes will show up in the Configurator.

I eventually settled on definitions for pins for four hardware UARTs. Many pins can be used for different purposes, e.g. UART, SPI etc. So I looked at which UARTs and which pin combinations are most commonly seen in the existing targets and chose the 4 most popular pairs on the basis that these pairs are unlikely to clash with some other common popular use for a given pin. Interestingly, UARTs 1 and 2 are far less commonly used that UARTs 3 to 6. I thought initially this might be because UARTs 1 and 2 are typically hardwired to other devices on the flight controller but even if these UARTs aren't available for end-users to use they still have to be defined for use in Betaflight. I guess it maybe reflects something to do with what devices are exposed on the low pin-count packages, like LQFP64, typically used in flight controllers, i.e. maybe UARTs 1 and 2 aren't exposed on these chips. Or maybe it reflects the fact that the pins that can be used for UARTs 1 and 2 are more commonly already taken for some other purpose, e.g. SPI.

TODO: merge this section with the corresponding section in the main `README`.

Telemetry
---------

Telemetry isn't just for data like RSSI or temperature, it's also the channel via which the flight controller can communicate with your TX (and any Lua scripts running on it). It does this using the `USE_MSP_OVER_TELEMETRY` feature.

Initially, I thought MSP was coming in via the SBUS (as it comes in on an RX pin) and going out via SPORT (i.e. telemetry, as it goes out on a TX pin). But it turns out telemetry is a bi-directional half-duplex link and MSP works solely via telemetry (SBUS is not involved).

Even if you undefine every obvious telemetry related feature, the flight controller still report "Hdg" (heading) telemetry data and "Tmp1". If you want to remove "Hdg":

```
# telemetry_disabled_heading set to ON
# save
```

It turns out "Tmp1" isn't actually a real temperature but is being used to encode information about the flight controller state (see the `case FSSP_DATAID_T1` in `processSmartPortTelemetry` in [`telemetry/smartport.c`](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/telemetry/smartport.c)). In OpenTX you see this sensor as something like "Tmp1 2002C", with the highest decimal place changing rapidly, it's actually a heartbeat value that's continously changing thru the values 1, 2 and 3 but encodes no meaning, the lower places do encode things, e.g. 2 at the end of 2002 means arming is disabled. If you want to remove "Tmp1":

```
# set telemetry_disabled_mode=ON
# save
```

To me `telemetry_disabled_mode` sounds dramatic but it really does just control if "Tmp1" (and under certain circumstances also "Tmp2") are sent.

Note: I thought MSP data must be similarly encoded into the data for a fake sensor but actually the SmartPort protocol supports different frame types - sensor data is sent with a `frameId` (see [`telemetry/smartport.c`](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/telemetry/smartport.c) again) of `FSSP_DATA_FRAME` while MSP data comes in with a `frameId` of either `FSSP_MSPC_FRAME_SMARTPORT` or `FSSP_MSPC_FRAME_FPORT` and is sent out with a `frameId` of `FSSP_MSPS_FRAME`.

Debugging using tfp_printf
--------------------------

You can debug SmartAudio by adding the following define to `target.h`:

```
#define USE_SMARTAUDIO_DPRINTF
```

You should then check the value for `DPRINTF_SERIAL_PORT` in [`vtx_smartaudio.h`](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/io/vtx_smartaudio.h). By default it's `SERIAL_PORT_USART3` but you can change it to something else if e.g. UART3 isn't available for some reason.

This then enables various debug output in the SmartAudio code that you can then view on the given UART using e.g. `screen`:

```
$ screen /dev/ttyUSB0 115200
```

Where `/dev/ttyUSB0` corresponds to the device created for your USB-to-serial cable that's connected to the relevant UART.

You can also use the same setup to add you're debug output, just add something like the following wherever you need:

```
tfp_printf("foo is set to %s", foo);
```

For more notes (than you want) on this, see [`smartaudio-debug.md`](smartaudio-debug.md).

Pin setup
---------

Certain pins can be associated with timers and this needs to be configured before such pins can e.g. be used for soft serial.

If you're using `USE_UNIFIED_TARGET` (along with `USE_TIMER_MGMT` and `USE_DMA_SPEC` which are defined by default for F4, F7 and H7 targets) then a `fullTimerHardware` array is defined for you, e.g. see [`drivers/timer_stm32f7xx.c`](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/drivers/timer_stm32f7xx.c) for the full F7 table. If you look at the pins PA0 to PA15, you'll see that most of them can be used whereas if you look at the block PF0 to PF15, you'll see that only PF6 and PF7 can be associated with timers.

If you're not using `USE_UNIFIED_TARGET`, i.e. you've got your own custom board setup that goes beyond what can be configured via the CLI and needs its own entry under `src/main/targets`, then you have to define your own `timerHardware` table with entries for the pins you want to use for motors, PWM etc. (see the [`timerUsageFlag_e` enum](https://github.com/betaflight/betaflight/blob/4.2.5/src/main/drivers/timer.h#L54) in `timer.h`). These entries will show up when you enter `resource` in the CLI (unless you use `TIM_USE_ANY`, in which case the pin is ready for use but has to be actively assigned to something particular like a motor etc.).

See `target.c` and the other changes necessary to make a pin available for soft serial in commit [`7f63244`](https://github.com/george-hawkins/betaflight/commit/7f63244).

Note: `fullTimerHardware` specifies everything as `TIM_USE_ANY` and then it's up to you to assign pins to resources via the CLI, i.e. no pins are automatically assigned a purpose.

When creating an entry in your own `timerHardware`, just copy the definition for the pin that you're interested in from `fullTimerHardware`, you can change the usage value from `TIM_USE_ANY` if you want but leave the other values as they are.

If you look carefully, you'll see certain pins defined in `fullTimerHardware` more than once, e.g. PA2 appears three times but each time with a different timer and channel channel combination. I'm not sure what rules you should apply when choosing which definiting to copy when copying such definitions into your own `timerHardware`, e.g. if I look existing targets it _looks_ like people try to choose different channels for the different motors (but the timers don't have to be different). And what happens where you're using a unified target? Via the CLI, you can't say you want the first, second or third definition of e.g. PA2 if you want to assign it to a resource.

It's clear that pins that you intend to use for the usages covered by `timerUsageFlag_e`, i.e. motors etc., need to be defined in `timerHardware`. But for other purposes, one has to work out if an entry is needed or not, e.g. hardware UART pins should not have an entry but pins that you plan to use for soft serial must have an entry (you can specify them as `TIM_USE_ANY` or steal a pin specified for another purpose, e.g. `TIM_USE_PPM`).

Important: when I modified the `timerHardware` table or the related defines here, I really had to reset all settings and then reload a backup (created previously with `diff all`), taking care that the modifications hadn't affected the validity of any of the commands, e.g.:

* If you'd had six motor entries previously and then reduced them to four then any resource command that attempted to release the 6th motor pin for some other use would fail.
* The first `TIM_USE_MOTOR` motor entry in `timerHardware` becomes `resource MOTOR 1` and so on, so changing the order of things in `timerHardware` or knocking out entries affects which pins get assigned to which motor number.

For some more details, see this [question](https://betaflightgroup.slack.com/archives/C3D7R2J0P/p1610196502089800) that I asked on the Betaflight #support Slack channel.

Configuring soft serial pins in code
------------------------------------

In order for a soft serial port to show up in the Configurator, you have to assign at least one pin to it.

You can do this in the CLI, as outlined in the main `README`, like so:

    resource SERIAL_TX 11 B04

Or you can configure a specific pin in `target.h` like so:

```
#define USE_SOFTSERIAL1
#define SOFTSERIAL1_TX_PIN PB4
```

Eliminating the VCP
-------------------

If you've already undefined `USE_USB_CDC_HID` then you can save a significant amount of space by disabling VCP and so removing the need for any USB related support. VCP is the virtual com port behind the USB connection that the Configurator usually uses to talk to a board.

You can instead use a real UART on the board and connect it up to your computer with a [USB-to-serial cable](https://www.adafruit.com/product/954).

It's simple to disable VCP - you just undefine `USE_VCP`. However, if you just do this and switch from a firmware with VCP enabled to one without then things get a little strange. If you don't take care then the board gets confused about how to interpret its existing UART configuration, now that the first port (the VCP port) is gone, and you essentially end up bricking the device.

If you get into a situation where you can't connect to the board anymore do a full chip erase with STM32CubeProgrammer (covered elsewhere) and then copy on a firmware with VCP enabled.

Initially, I thought the issue was that with the first port disappearing, the pins in the existing configuration were being assigned to the wrong ports, e.g. those of the first port were being assigned to what had been the second port but was now the first port. So to keep things aligned I set things up like this:

    #ifndef USE_VCP
    #define USE_UART1
    #define UART1_TX_PIN PB6
    #endif

I.e. `USE_UART1` was only defined if `USE_VCP` was not and so would pop into existence as the first port when the VCP port disappeared and so keep the underlying pin configuration aligned as far as the other ports were concerned.

    // If using USE_SOFTSERIAL1 and/or USE_SOFTSERIAL2, each counts towards the port count.
    #ifdef USE_VCP
    #define USE_USB_DETECT
    #define USB_DETECT_PIN PA9
    #define SERIAL_PORT_COUNT 5 // VCP, USART3, UART4, UART5, UART6
    #else
    #define SERIAL_PORT_COUNT 4 // USART3, UART4, UART5, UART6
    #define USE_TARGET_CONFIG // Enable specifying MSP port in config.c
    #endif

So it's as simple as adjusting `SERIAL_PORT_COUNT` to reflect the disappearance of the VCP port. Before undefining `USE_VCP` you need to have configure the real UART, that you intend to connect to your computer, to use MSP (via the _Ports_ tab in the Configurator). MSP is the protocol that the Configurator uses to talk with the board. Test that you can now also connect via your USB-to-serial cable. Then update the firmware with a firmware where the only difference is that `USE_VCP` has been undefined.

The port that you configured for MSP will continue to work after disabling. However, after connecting with the Configurator, you'll need to do a full reset of all setting to get all expected UARTs (for whatever reason the last one disappears). But this would also lose your MSP configuration for the real UART port that you're now using to connect to the board. This is where `USE_TARGET_CONFIG` (defined above) comes into play, using this and adding a `config.c` file you can hardcode that MSP be set for a particular UART on reset.

See commit [`435d954`](https://github.com/george-hawkins/betaflight/commit/435d954) for all the changes necessary, including the `config.c` file that sets things up.

Note: after a reset MSP is also automatically configured for the first UARTi so you can do without `USE_TARGET_CONFIG` and `config.c` if you're OK with having to use it for connecting from your computer.

Dual use UART
-------------

If you've disabled VCP and are using a real UART to connect to the Configurator then you can imagine a situation where you're so short on UARTs that you'd like the UART used for the Configurator to be useable for something else when not using the Configurator (i.e. the normal case - in the life of a flight controller one connects it to the Configurator relatively rarely).

E.g. it might be nice to use the UART that you usually use for SmartAudio for the Configurator when necessary (and keep the VTX powered down in these situations).

The solution, I came up with for this was to define an additional UART in `target.h` that used pins that weren't actually exposed by the flight controller (flight controllers tend to use the very low pin count MCU packages which means there are mean UART pins that don't actually have a corresponding physical pin).

So say this dummy UART is UART6, then it appears in the Configurator (even though the underlying pins aren't really available) and I can e.g. configure the MSP connection for the Configurator on a real UART, say UART3, and SmartAudio on the dummy UART6.

Then I can set things up such that if I short a particular GPIO pin on the board to ground, it will keep these settings, i.e. MSP on the real UART and SmartAudio on the dummy UART, but if I don't short the GPIO pin to ground then it will swap things such that SmartAudio gets the real UART and MSP the dummy.

So actively shorting the pin makes the flight controller ready for use on the bench with the Configurator and otherwise the Configurator UART can be used for something else, like SmartAudio.

You can see the necessary changes in commit [`9d8c73b`](https://github.com/george-hawkins/betaflight/commit/9d8c73b). Various targets already detect whether a paricular pin is shorted or not to determine the hardware revision of the board.

So I hijack this process and provide my own `detectHardwareRevision` that sets a global variable that can then be picked up in my own `targetPreInit` definition that swaps the ports an whether the global variable indicates the relevant GPIO pin (specified by `HW_PIN`) is low or not.

Then in the CLI the whole process has to be configured, e.g. like so:

    set serial_swap_ports_enabled=ON
    set serial_swap_ports=3,6

Note: I did have this working but there must be slightly more to it as you can't arbitrarily reassign pins, e.g. if you assign valid pins for UART3 to UART6 they won't work, you must use pins that are specified in the MCU datasheet for the UART. I any case if I was doing things again, I wouldn't go for this fancy setup with a dummy additional port and CLI settings like `serial_swap_ports`. I'd just hardcode things in `targetPreInit` to set a given UART to MSP under one condition and to SmartAudio, or whatever, under the other condition.
