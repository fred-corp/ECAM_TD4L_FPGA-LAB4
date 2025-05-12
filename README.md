# FPGA Lab 4 - Robot

## Overview

## Description

## How to `make`

### Prerequisites

You need the following software installed on your computer :

- [ICE40 Open SOurce Toolchain](https://github.com/dloubach/ice40-opensource-toolchain)
- [Yosys with GHDL](https://github.com/ghdl/ghdl-yosys-plugin)
- [Vunit](https://vunit.github.io/installing.html)

Clone the repository :

```zsh
git clone https://github.com/fred-corp/ECAM_TD4L_FPGA-LAB4.git
```

Change directory to the cloned repository :

```zsh
cd ECAM_TD4L_FPGA-LAB4
```

Run the `make` command :

```zsh
make bitstream
```

If you want to flash the bitstream to the FPGA, you can run :

```zsh
make flash
```

If you want to run the tests, you can run :

```zsh
make testbench
```

> Note :  You'll need Surfer installed on your device, as well as the correct VUnit version which supports Surfer. Otherwise you'll need to modify the Makefile to use GTKWave instead.


## License & Acknowledgements

Made with ❤️, lots of ☕️, and lack of 🛌  
Published under CreativeCommons BY-SA 4.0

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)  
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).
