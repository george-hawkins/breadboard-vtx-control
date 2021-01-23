Nucleo-F722ZE Zio header pins
=============================

The Nucleo-F722ZE has two rows of female headers - these are called the Zio headers. Outside them are longer sets of plain thru-hole pins, i.e. without headers - these are called the morpho connectors.

This file lists the default pins on the Zio headers - some of these (as noted below) can be changed via solder bridges.

CN8
---

1 NC
3 IOREF
5 RESET - NRST
7 +3.3 V
9 +5 V
11 GND
13 GND
15 VIN

2 PC8
4 PC9
6 PC10
8 PC11
10 PC12
12 PD2
14 PG2
16 PG3

CN9
---

1 PA3
3 PC0
5 PC3
7 PF3
9 PF5
11 PF10
13 NC
15 NC
17 PF2
19 PF1
21 PF0
23 GND
25 PD0
27 PD1
29 PG0

Notes: pins 9 and 11 can be rooted thru instead to PB9 and PB8 respectively with SB138 and SB143.

2 PD7
4 PD6
6 PD5
8 PD4
10 PD3
12 GND
14 PE2
16 PE4
18 PE5
20 PE6
22 PE3
24 PF8
26 PF7
28 PF9
30 PG1

Notes: PE2 is connected to both CN9 pin 14 and CN10 pin 25. Only one must be used at any given time.

CN7
---

1 PC6
3 PB15
5 PB13
7 PB12
9 PA15
11 PC7
13 PB5
15 PB3
17 PA4
19 PB4

2 PB8
4 PB9
6 AREF
8 GND
10 PA5
12 PA6
14 PA7
16 PD14
18 PD15
20 PF12

Notes: pin 14 can be rooted thru instead to PB5 with SB121 and SB122.

CN10
----

1 AVDD
3 AGND
5 GND
7 PB1
9 PC2
11 PF4
13 PB6
15 PB2
17 GND
19 PD13
21 PD12
23 PD11
25 PE2
27 GND
29 PA0
31 PB0
33 PE0

2 PF13
4 PE9
6 PE11
8 PF14
10 PE13
12 PF15
14 PG14
16 PG9
18 PE8
20 PE7
22 GND
24 PE10
26 PE12
28 PE14
30 PE15
32 PB10
34 PB11
