Working with Betaflight in Eclipse
==================================

Download the Eclipse IDE for Embedded C/C++ Developers as covered [here](https://eclipse-embed-cdt.github.io/plugins/install/).

    $ tar -xf ~/Downloads/eclipse-embedcdt-2020-09-R-linux.gtk.x86_64.tar.gz 
    $ mv eclipse eclipse-embedcdt-2020-09-R
    $ cd eclipse-embedcdt-2020-09-R
    $ ./eclipse

Import the checked out Betaflight repository - _File_ / _New_ / _Makefile Project with Existing Code_ - choose a _Project Name_, e.g. "betaflight", specify the location and select _Arm Cross GCC_ as the toolchain.

Go to _Project_ / _Properties_, then _C/C++ Build_ and select the _Behavior_ tab.

Change the _Build (incremental build)_ from _all_ to _TARGET=NUCLEOF722_ (replacing _NUCLEOF722_ with your desired target).

TODO: actually, you should set _TARGET_ as an environment variable and _hex_ as the target.

Expand _C/C++ Build_ and select _Settings_, under _Toolchains_, select _GNU Tools for Arm Embedded Processors_.

Note: _GNU Tools for Arm Embedded Processors_ seems to have been the name used up to and including 9-2019-q4-major in the release notes. After that they just call it _GNU Arm Embedded Toolchain_.

Note: the default is to use a toolchain installed using [xPack](https://xpack.github.io/). This seems to be the Eclipse project's preferred way to manage toolchains for cross platform projects. To install the _GNU Arm Embedded GCC binaries_ xPack see [here](https://xpack.github.io/arm-none-eabi-gcc/install/). I chose instead to use the toolchain installed by the Ubuntu `gcc-arm-none-eabi` package.
