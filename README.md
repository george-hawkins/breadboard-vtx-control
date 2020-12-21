The NUCLEO F722ZE has two USB ports - one, labeled _CN1_, on the small subboard at one end and one, labeled _CN13_, on the main board at the other end.

The small subboard is the ST-LINK. 

Oddly, the two USB connectors use components - the one on the ST-LINK is clearly a micro-USB connector, the other is also micro-USB but upside-down relative to the other one.

So plug the a USB cable into the ST-LINK connector (plugging it into the other one does nothing due to the default jumper settings) - it appears as a USB drive.

Find the latest LINK updater under <https://www.st.com/en/development-tools/stm32-programmers.html#products>. Currently, it's [STWS-LINK007](https://www.st.com/en/development-tools/stsw-link007.html).

Register with the STM site, download the application and...

    $ cd Downloads
    $ unzip en.stsw-link007_V2-37-26.zip 
    $ cd stsw-link007
    $ cd AllPlatforms
    $ type java
    ... ~/.sdkman/candidates/java/current/bin/java ...
    $ sudo ~/.sdkman/candidates/java/current/bin/java -jar STLinkUpgrade.jar

It needs to be run with `sudo` in order to open USB devices. The GUI should detect the device, click the _Open in update mode_ and click _Upgrade_ if the _Version_ shown isn't the same as the one that is proposes as an update.

The default application will flash the red user LED madly, press the button labeled _USER_ to cycle thru the other user LEDs.

---

    $ git clone git@github.com:betaflight/betaflight.git
    $ cd betaflight

Checkout the latest [tag](https://github.com/betaflight/betaflight/tags):

    $ git checkout 4.2.5

Copy in my `Dockerfile`. At any point you can clean everything with:

    $ docker run --rm --volume $PWD:/betaflight betaflight:latest rm -rf downloads obj tools

The Betaflight Ubuntu build instructions are [here](https://github.com/betaflight/betaflight/blob/master/docs/development/Building%20in%20Ubuntu.md).

First step:

    $ docker run --rm --volume $PWD:/betaflight betaflight:latest make arm_sdk_install

This just downloads `gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2` into the `downloads` directory and unpacks it into the `tools` directory.

Instead, you can probably just `apt` install `gcc-arm-none-eabi`.

Find the appropriate target:

    $ ls src/main/target
    ... NUCLEOF722 ...

Then make sure everything is clean:

    $ docker run --rm --volume $PWD:/betaflight betaflight:latest make clean TARGET=NUCLEOF722

Then build the hex target:

    $ docker run --rm --volume $PWD:/betaflight betaflight:latest make hex TARGET=NUCLEOF722
    $ ls obj/betaflight_4.2.5_NUCLEOF722_afdac08b3.hex

Copy the target to the board:

    $ cp obj/betaflight_4.2.5_NUCLEOF722_afdac08b3.hex /media/ghawkins/NODE_F722ZE

The drive unmounts and remounts. After remounting the red and green LEDs were lit and the blue one flashed on and off.

---

Download the latest Betaflight Configurator from [releases](https://github.com/betaflight/betaflight-configurator/releases). Then...

    $ mv ~/Downloads/betaflight-configurator_10.7.0_amd64.deb /tmp
    $ sudo apt install /tmp/betaflight-configurator_10.7.0_amd64.deb

The Configurator ends up in `/opt/betaflight/betaflight-configurator`:

    $ apt list --installed | fgrep -i betaflight
    betaflight-configurator/now 10.7.0 amd64 [installed,local]
    $ dpkg-query -L betaflight-configurator
    ...
    /opt/betaflight/betaflight-configurator/betaflight-configurator
    ...

The Configurator communicates with the board via the other USB connector. So keep the board powered via the LINK and plug in another USB cable to the second USB connector.

Monitor what's output when it's plugged in:

    $ tail -f /var/log/syslog
    Dec  8 17:11:52 systemd[1490]: Started VTE child process 30338 launched by gnome-terminal-server process 2758.
    Dec  8 17:15:03 kernel: [12304.704318] usb 3-4.4: new full-speed USB device number 10 using xhci_hcd
    Dec  8 17:15:03 kernel: [12304.806319] usb 3-4.4: New USB device found, idVendor=0483, idProduct=5740, bcdDevice= 2.00
    Dec  8 17:15:03 kernel: [12304.806322] usb 3-4.4: New USB device strings: Mfr=1, Product=2, SerialNumber=3
    Dec  8 17:15:03 kernel: [12304.806323] usb 3-4.4: Product: STM32 Virtual ComPort in FS Mode
    Dec  8 17:15:03 kernel: [12304.806323] usb 3-4.4: Manufacturer: Betaflight
    Dec  8 17:15:03 kernel: [12304.806324] usb 3-4.4: SerialNumber: 3986356B3037
    Dec  8 17:15:03 kernel: [12304.814015] cdc_acm 3-4.4:1.0: ttyACM1: USB ACM device
    Dec  8 17:15:03 mtp-probe: checking bus 3, device 10: "/sys/devices/pci0000:00/0000:00:14.0/usb3/3-4/3-4.4"
    Dec  8 17:15:03 mtp-probe: bus: 3, device: 10 was not an MTP device
    Dec  8 17:15:03 snapd[691]: hotplug.go:199: hotplug device add event ignored, enable experimental.hotplug
    Dec  8 17:15:03 mtp-probe: checking bus 3, device 10: "/sys/devices/pci0000:00/0000:00:14.0/usb3/3-4/3-4.4"
    Dec  8 17:15:03 mtp-probe: bus: 3, device: 10 was not an MTP device
    Dec  8 17:15:06 ModemManager[779]: <info>  Couldn't check support for device '/sys/devices/pci0000:00/0000:00:14.0/usb3/3-4/3-4.4': not supported by any plugin

And create a suitable `udev` rule to add to `/etc/udev/rules.d/50-serial-ports.rules`:

    # STM - virtual COM port.
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", \
        SYMLINK+="stm-virtual-com", MODE="0666"

    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", ENV{ID_MM_DEVICE_IGNORE}="1"

    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", ENV{MTP_NO_PROBE}="1"

Now you can open the port with needing `sudo` (you'd be able to do this without a `udev` rule if you're already in the `dialout` group):

    $ /opt/betaflight/betaflight-configurator/betaflight-configurator

If you leave it for a second or two, it automatically chooses a device - sometimes it gets things right and sometimes it doesn't. With the `udev` rule you can always see which is the right port:

    $ ls -l /dev/stm-virtual-com 
    lrwxrwxrwx 1 root root 7 Dec  8 17:34 /dev/stm-virtual-com -> ttyACM1

**Update:** the Configurator consistently chooses the right port if you always wait for the board to fully start up - when the board is ready it turns on the green LED.

Click the _Connect_ button and ignore the warning about the _motor output protocol_ and the _accelerometer_.

Note: if you exit out of the CLI tab or do anything else that causes the board to reboot the port can become available before it's really ready and you get the following if you try to connect:

    [31442:31447:1208/173427.273442:ERROR:serial_io_handler.cc(145)] Failed to open serial port: FILE_ERROR_ACCESS_DENIED

Just wait and try again.

Now you can update the firmware via the Configurator as an alternative to copying via the LINK.

There don't seem to be any really nice pinout diagrams for the F722ZE - the best is the one that you can find in the user manual in the board's [documentation area](https://www.st.com/en/evaluation-tools/nucleo-f722ze.html#documentation).

The diagram in the _Hardware layout and configuration_ is just the same as the one that comes with the board's blister pack.

---

Setup receiver
--------------

Look at `/src/main/target/NUCLEOF722/target.h`, there you'll see:

    #define USE_UART2
    #define UART2_RX_PIN PD6
    #define UART2_TX_PIN PD5

If you look at the pinout diagram mentioned above you can find PD6 and PD5.

*Important:* each header consists of two rows of pins (unlike the Arduino UNO with its single rows) - initially I didn't realize that the two rows aren't just the same pins doubled up. PD6 and PD5 are on the inner row - initially, I had things plugged into the outside row.

So PD6 and PD5 are in the area labeled _UART_, more usefully on the outer row are the labels _A1_ and _A2_.

So connect the SBUS signal pin to the inner pin corresponding to _A1_ and the SPORT signal pin to the inner pin corresponding to _A2_.

In the Configurator, go to _Ports_ and click the _UART2_ _Serial RX_ toggle to on and under _Telemetry Output_ select _FrSky_. The _Configuration/MSP_ toggle can be left unselected, i.e. off.

Click _Save and Reboot_. Go to _Configuration_ and under _Other Features_ select _Telemetry_ and click _Save and Reboot_ again. According to other sources, you shouldn't need to save and reboot twice but I found it lost my unsaved port settings on switching tabs.

The other necessary settings in the _Receiver_ section of _Configuration_ already had the appropriate values.

*Credit:* these instructions are derived from Oscar Liang's instructions for the F3 [here](https://oscarliang.com/sbus-smartport-telemetry-naze32).

After reboot and reconnecting, go to the _Receiver_ tab and confirm that the bars move as you move the sticks on the bound transmitter.

---

Telemetry
---------

On my OpenTX transmitter I created a new model - all I did was give it a name and bind it to the receiver as described [here](https://george-hawkins.github.io/arf-drone/docs/binding).

Note: to get the TX to stop complaining about no failsafe being set when it starts up, go to the model's _SETUP_ page, scroll to _Failsafe_ and set it to _No pulses_ (which with a real drone would mean you then need to configure how to respond in a failsafe situation of the flight controller itself).

I then went to the _TELEMETRY_ page and selected _Discover new sensors_, it just discovered RSSI and RxBt, i.e. values reported by the receiver.

TODO: can I do anything to indicate that the board itself can report telemetry values via its SPORT connection?

It may need inversion - the F7 can do this automatically, I thought but I could get this to work as described here:

<https://github.com/betaflight/betaflight/blob/master/docs/Telemetry.md>

And I couldn't get the two soft serial porsts that I should supposedly get if I enable _Soft Serial_ as described here:

<https://oscarliang.com/betaflight-soft-serial/>

Although, I wonder if you have to assign pins for _Soft Serial_ to use - there are no obvious pins set up in `/src/main/target/NUCLEOF722/target.h`.

Or maybe simply try moving telemetry onto another UART - though I don't see why that should matter.

---

SoftSerial
----------

For you need to first choose some pins to use - the usual thing to do is to steal them from something that isn't being used.

I suspect with the Nucleo F722ZE there are lots of pins that aren't assigned to anything which you could just as well use.

But...

In Configurator, go to the CLI and:

    # resource
    ...
    resource MOTOR 5 E06
    resource MOTOR 6 B04
    resource PPM 1 B15
    ...

The pins suggested for stealing in Oscar's [guide](https://oscarliang.com/betaflight-resource-remapping/) are `LED_STRIP`, `PPM` and spare motor outputs. There's no `LED_STRIP` resource for the F722ZE so let's use the motor outputs 5 and 6 (not that we're intending to even use 1 to 4).

Actually, let's just free 6 first:

    # resource MOTOR 6 none
    Resource is freed

And assign it to SoftSerial and save:

    # resource SERIAL_TX 11 B04
    Resource is set to B04
    # save

Note: SoftSerial port number starts from 11, 11 being Softserial #1 and 12 being Softserial #2.

Once it has rebooted and you've reconnected go to _Configuration_ and under _Other Features_ turn on _SOFTSERIAL_.

After _Save and Reboot_ go to ports and _SOFTSERIAL1_ should now be there (if not go to the `tlm_halfduplex` section of Oscar's guide, at this stage, I'm not sure if I had to actively change anything related to this). TODO: reset are parameters and re-setup Softserial and see if `tlm_halfduplex` is relevant.

---

I finally got telemetry with:

    # set tlm_inverted=OFF
    # set tlm_halfduplex=ON
    # save

But it doesn't seem possible to have both _Serial RX_ and _SmartPort_ on a single UART.

So, I just toggled on _Serial RX_ for _UART2_ and connected the SBUS signal out to the inner pin corresponding to _A0_.

**Update:** using the silkscreened pin names like _A0_ turns out to be very confusing - for the outer pins on the headers these correspond to Arduino pin names, so _A0_ corresponds to the similarly positioned _A0_ pin on an Arduino header. However, the STM32 also has an A0 pin (referred to as PA0 in the Nucleo manual and as A00 within Betaflight) that is totally unrelated to this silkscreened pin _A0_.

And I setup SoftSerial as described above and set _SOFTSERIAL1_ _Telemetry Output_ to _SmartPort_ (leaving _AUTO_ unchanged) and connected the SPORT signal in to pin PB4.

Note: using `resource` above the pin is called `B04`, there's no pin `B04` if you look in the Nucleo user manual. I worked out that `B04` must be `PB4` from how the names seen in `target.h` seem to map to other resource values but I couldn't find anything that formally described how pin names are mapped. It seems to be as simple as take `B04`, knock out any leading zeros to get `B4` and then prepend `P` to get `PB4`.

Oddly, the UART3 and UART4 pins in `target.h` aren't pins exposed via the Nucleo header so I didn't have any choice but to use SoftSerial.

TODO: the UART5 pins do seem to be exposed via the header - reassign these to UART3 and see if you can use it for telemetry. See if you can do this mapping via `resource` rather than by rebuilding the firmware.

TODO: why does Betaflight allow you to specify SPORT and SBUS on a single port? They use different baud rates so surely their coexistance on one port is impossible? Once you reboot it undoes your attempt to set SPORT on a UART that you've also marked as SBUS - shouldn't it do this when you actually make the change?

So as `tlm_inverted` has to be `OFF` does this mean its saying telemetry is *not* inverted by an external inverter (and so is in its default inverted form rather than univerted)?

Telemetry on hardware UART TX pin
---------------------------------

You don't appear to have complete freedom to assign pins to UARTs (as e.g. you do with the ESP32). I couldn't work out the scheme to what is and isn't allowed.

In the `target.h` various pins are assigned to UARTs 5, 6, 7 and 8 but those UARTs are not actually enabled.

Of the pins assigned to those UARTs, only the following are accessible via the board's headers - pins PE8 (TX) and PE7 (RX) of UART7 and pin PE0 (RX) of UART8.

Of the UARTs that are actually enabled, i.e. UART2, UART3 and UART4, only the pins PD6 (RX) and PD5 (TX) of UART2 and pin PA0 (TX) of UART4 are accessible.

I could use UART4 (with pin PA0) for _SmartPort_ telemetry but I could not e.g. use PE8 by reassigning it to UART3. This _may_ be because UART3 is used for ST-LINK (search for _USART3_ in the F722ZE manual) - this assumes there's some connection between Betaflight's UART numbering and the devices of the MPU but I don't believe there is.

I also tried reassigning other pins to UART4 TX to other pins but this didn't work.

It is not the case that PA0, i.e. UART4 TX, is described as a UART pin in the F722ZE manual.

In the manual's _Hardware layout and configuration_ section for the F722ZE, the pins PD6 and PD5 are described as being the RX and TX pins of _USART_2_ and indeed are used as the RX and TX pins of of UART 2 in `target.h`.

However, the only other pins described as _USART_ pins are PG14 (TX) and PG9 (RX) for _USART6_ (notice the inconsistent naming _USART_2_ vs _USART6_) and these pins are out of bounds to the Betaflight CLI as it doesn't recognise pin names about F15.

PA0, i.e. UART4 TX, is described as having signal name `TIMER_C_PWM1` and function `TIM2_CH1`.

PB0 has signal name `TIMER_D_PWM1` and function `TIM3_CH3` but can't be substituted for PA0. Neither can PE9 (`TIMER_A_PWM1` and `TIM1_CH1`) nor PE8 (assigned to UART7 TX in `target.h`).

I tried reassigning PA0 to UART3 but it doesn't work there. And I tried assigning it to SoftSerial (replacing B04 used above) and that didn't work either.

So only PA0 as TX for UART4 works. It may simply be that despite seeming to be able to set `resource` values for UARTs via the CLI that this doesn't actually change anything.

Hmmm... that doesn't seem to be the case - it isn't the case that UART related `resource` changes don't affect anything, e.g. if you assign PA0 to UART3 but leave _SmartPort_ set for UART4 (and nothing set for UART3), it's not the case that things keep on working, i.e. it's not that under the covers UART4 is still really using PA0 as if it hadn't been reassigned to UART3.

So what exactly the rules are here is quite unclear.

Using hardware serial doesn't introduce any increased flexibility with regards `tlm_halfduplex` and `tlm_inverted` - they have to be the same values as above for SoftSerial.

SmartAudio
----------

I left SPORT connected to the hardware UART4 TX.

And connected the SmartAudio pin on my VTX to B04, i.e. the SoftSerial 1 TX pin.

Then, following Oscar Liang's [guide](https://oscarliang.com/vtx-control/):

* Under _Ports_, I set the _Perpherals_ drop down for _SOFTSERIAL1_ to _VTX (TBS SmartAudio)_ (and clicked _Save and Reboot_).
* Under the _Other Features_ section of _Configuration_, I toggled _OSD_ to on (and clicked _Save and Reboot_).

This didn't result in an OSD appearing as I hoped it might.

I noticed that plugging out and in the 12V supply for the VTX caused the Nucleo board to reset which wasn't very reassuring, i.e. the signal it saw on B04 was enough to trigger this reset.

I then checked the voltage of the SmartAudio pin of the VTX using my Arduino oscilloscope and it showed a signal with a 5V peak - not good! However, I don't seem to have destroyed the pin.

Looking at the Nucleo manual, it clearly says:

> Caution:1 The I/Os of STM32 microcontroller are 3.3 V compatible instead of 5 V for ARDUINO&reg; Uno V3.

**Update:** this all proved to be nonsense. The problem was with the grounds - once you connected the ground of the VTX to the ground of the Arduino oscilloscope there was no such peak - in fact there were no peaks, the VTX seems to produce no output when not connected to something that interacts with it.

Once I connected the ground of the VTX to one of the ground pins of the Nucleo board, I could finally see the VTX show up in the debug sensor view (as described next). **Connecting the grounds was the crucial missing element.**

Then continuing with Oscar's guide I went about setting up the _VTX table_. First, I determined the SmartAudio version (as described in the video linked to from the Betaflight _VTX Tables_ [wiki page](https://github.com/betaflight/betaflight/wiki/VTX-tables)):

* Under _Blackbox_, I set the _Blackbox debug mode_ to _SMARTAUDIO_ (and clicked _Save and Reboot_).
* Then I toggled _Enable Expert Mode_ to on (it's to the left of the _Update Firmware_ and _Connect_ buttons).
* Then under the _Sensors_ tab, I unselected everything already selected (_Gyroscope_ and _Accelerometer_) and selected only _Debug_.

The value I saw for _Debug 0_ was 216 - which correspond to the value for "SA 2.0 unlocked" shown in the wiki page (rather than the values mentioned in the video).

**Note:** if PR [#10413](https://github.com/betaflight/betaflight/pull/10413) (and its related Configurator PR) are merged, you'll be able to see the SmartAudio version directly in the VTX tab without all this debug stuff.

Note: Oscar's summary of the values in this [post](https://intofpv.com/t-what-smartaudio-version-do-i-have) also covers what you see in the _Debug 1_ and _Debug 2_ channels.

If I adjust the bands then, I see the following values:

* Band = 1, Debug 1 = 0
* Band = 2, Debug 1 = 15
* Band = 3, Debug 1 = 23
* Band = 4, Debug 1 = 31
* Band = 5, Debug 1 = 39

Changing the channel should have changed the output of _Debug 2_ but it seemed to always be 5865.

So given that my VTX is SmartAudio 2.0, I downloaded the _SmartAudio 2.0 (EU)_ JSON file from the _VTX Tables_ wiki page and loaded it in the Configurator by going to _Video Transmitter_, selecting _Load from file_ and, once it was loaded, selecting _Save_.

It looks like in the EU, you can't have frequencies below ~5732 and above ~5866, so the top A band channel is unavailable as are the lower two and higher two race band channels.

I reduced the number of bands to 5 (and then pressed _Save_) to knock out the I band that isn't mentioned in the TX805 mini-manual.

Band E is not legal in the EU, hence it appears as _UNKNOWN_ between bands B and F.

TODO: under _Video Transmitter_, you can select _Save LUA Scipt_ which save a file that I presume can then be loaded into OpenTX. Hmmm... why is this option here, as discovered below, the Betaflight script on the transmitter automatically downloads the table using the MSP protocol.

Now one can control the VTX via the _Selected Mode_ section of the _Video Transmitter_ tab. E.g. select band _BOSCAM_A_, channel _Channel 1_ and power _25_ and press _Save_ and you'll see the LEDs change accordingly on the VTX.

TODO: you can set `vtx_low_power_disarm` - will this push you into pit mode when you power up or does toggling pit mode mean you always start in pit mode? I couldn't switch to pit mode via the _Selected Mode_ section, try and work out why not.

Note: you can just enter part of a value name and get all values containing that substring:

    # get vtx_
    osd_vtx_channel_pos = 234
    Allowed range: 0 - 15359

    vtx_band = 1
    Allowed range: 0 - 8
    Default value: 0

    vtx_channel = 1
    Allowed range: 0 - 8
    Default value: 0

    vtx_power = 1
    Allowed range: 0 - 7
    Default value: 0

    vtx_low_power_disarm = OFF
    Allowed values: OFF, ON, UNTIL_FIRST_ARM

    vtx_freq = 5865
    Allowed range: 0 - 5999
    Default value: 0

    vtx_pit_mode_freq = 0
    Allowed range: 0 - 5999

    vtx_halfduplex = ON
    Allowed values: OFF, ON

Aside: the VTX seemed to default to 600mW (blue LED on). I switched it down to 25mW as it's the legal limit and in the hope it wouldn't get so hot. And indeed, it runs much cooler and isn't painful to touch while running.

Transmitter setup
-----------------

Assuming you've got your transmitter and receiver upgraded to the latest OpenTX firmware releases (in the case of OpenTX and its bootloader) and FrSky firmware releases (in the case of the receiver and the transmitter's underlying radio hardware) then, following the Betaflight TX Lua Scripts [instructions](https://github.com/betaflight/betaflight-tx-lua-scripts#installing):

* Download the latest zip file from the releases [page](https://github.com/betaflight/betaflight-tx-lua-scripts/releases).
* Mount the _OPENTX_ SD card and...

    $ cd ~/Downloads/
    $ unzip betaflight-tx-lua-scripts_1.5.0.zip 
    $ cd obj
    $ cp -r * /media/$USER/OPENTX
    $ ls /media/ghawkins/OPENTX/SCRIPTS/TOOLS
    bf.lua ...

If `bf.lua` is there then all is good.

Aside: `obj` seems an odd name for the root directory of the extracted zip file.

Once the transmitter is restarted, long press _MENU_, this takes you to the _TOOLS_ page. Scroll down and select _Betaflight setup_, the first time it runs it goes through a one-time setup process, once this has happened select _Betaflight setup_ again. Now when you select it, it will display _Downloading VTX tables_ for a while (it communicates with the flight controller using MSP (MultiWii Serial Protocol).

Note: MSP seems to be rather poorly documented, you can find the protocol described [here](http://www.multiwii.com/forum/viewtopic.php?f=8&t=1516) and Betaflight implementation [here](https://github.com/betaflight/betaflight/tree/master/src/main/msp).

This line in the [README](https://github.com/betaflight/betaflight-tx-lua-scripts/blob/master/README.md) took me a while to work out:

> If you change the VTX table, you have to re-load the updated VTX table in the script, by choosing the 'vtx tables' option in the function menu.

If you update the VTX tables in Betaflight Configurator then on your transmitter go to _TOOLS_ / _Betaflight setup_ / _VTX Settings_ and then press and hold _ENTER_ (it doesn't matter what item under _VTX Settings_ is currently selected), this will bring up a popup menu where one of the options is _vtx tables_ - simply select it and the VTX table (with your updates) will be re-downloaded.

You can reach this popup menu (what they call the _function menu_) from any of the subpages of _Betaflight Config_, e.g. _VTX Settings_, _PIDs 1_ etc., but not from the main page itself.

The menu items are:

* _save page_ - any changes you make on a page, e.g. to the _Band_ etc., are only actually applied after you select _save page_.
* _reload_ - reload the value displayed on the page from the flight controller.
* _reboot_ - reboot the flight controller.
* _vtx tables_ - described above. 

Note: once upon a time it was possible to configure things such that one could interact with the Betaflight script via the OpenTX telemetry screens and this is covered in many existing tutorials - however, this in no longer possible - you can only access it now via the _TOOLS_ page (as just described) - for more details see issue [#306](https://github.com/betaflight/betaflight-tx-lua-scripts/pull/306). This change came with version 1.5.0 of the scripts that was released May 2020.

Now everything is set up, you can change _Band_ etc. under _VTX Settings_. As already noted, your changes only come into affect when you long press _ENTER_ and select _save page_. You can change everything except the _Protocol_ values of _SA_, i.e. SmartAudio.

Aside: once this is all set up, one essentially gives up the ability to configure the VTX by its push button. You can still change VTX settings via the pushbutton but then, in OpenTX, if you press _reload_ via the _function menu_, nothing changes. And if you reboot the flight controller it will restore the settings on the VTX to those seen under _VTX Settings_.

So it seems that while there is two way communication between the flight controller and the the transmitter, the flight controller only sets values for the VTX but doesn't try to read them. As we saw above, we can read the Smart Audio version from the VTX so there does seem to be two way communication between the flight controller and the VTX - but the flight controller simply doesn't use this capability to read values from the VTX.

Note: if you change VTX values via OpenTX and Betaflight Configurator is open at the same time, there's no equivalent of _reload_ in Configurator - if you're on the Configurator _Video Transmitter_ tab and you change the settings via OpenTX then you have to switch to another tab and then back to _Video Transmitter_ to force it to load the changes.

Note: very strangely, it doesn't seem to be possible to configure the VTX to start in pit mode. My VTX is a SmartAudio 2.0 device, it was only with SmartAudio 2.1 that it became possible to actively enter pit mode, previous to that you could only configure the device such that it would start in pit mode. To do this one should set `RACE` mode (not to be confused with the race band) via the OSD as described [here](https://github.com/betaflight/betaflight/wiki/Unify-Smartaudio#op-model). According to some source you have to power cycle the VTX straight after setting the `OP MODEL` to `RACE` or it'll be forgotten. However, as I haven't got an OSD, this isn't possible. Oddly, while one can do nearly everything, that one can do via the OSD, using the CLI or Configurator, it doesn't seem possible to set the `OP MODEL`. I've asked about this on RcGroups [here](https://www.rcgroups.com/forums/showthread.php?3787149) and on the Betaflight Slack channel [here](https://betaflightgroup.slack.com/archives/C3D7R2J0P/p1608487449360200).

Voltages
--------

SBUS is a signal output by the RX and I've tested it with my Arduino oscilloscope setup to check that it's 3.3V.

SPORT is a signal output by one of the Nucleo pins and so by definition has to be 3.3V.

Pins
----

If we take the pin `PE13`, used in `target.h`, we can track where it appears in the source:

    src/main/target/NUCLEOF722/target.h:#define SPI4_MISO_PIN PE13

    src/main/drivers/io_def_generated.h:# define DEFIO_TAG__PE13 DEFIO_TAG_MAKE(DEFIO_GPIOID__E, 13)
    src/main/drivers/io_def_generated.h:# define DEFIO_TAG_E__PE13 DEFIO_TAG_MAKE(DEFIO_GPIOID__E, 13)
    src/main/drivers/io_def_generated.h:# define DEFIO_REC__PE13 DEFIO_REC_INDEXED(BITCOUNT(DEFIO_PORT...

    src/main/drivers/timer_stm32f7xx.c: DEF_TIM(TIM1, CH3, PE13, TIM_USE_ANY, 0, 0),
    src/main/drivers/bus_spi_pinconfig.c: { DEFIO_TAG_E(PE13), GPIO_AF5_SPI4 },
    src/main/drivers/timer_def.h:#define DEF_TIM_AF__PE13__TCH_TIM1_CH3 D(1, 1)

