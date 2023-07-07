# Absolute-Logic

This repository contains the source code for a VHDL implementation of the inversion, absolute logic (sign-and-magnitude), and two's complement algorithms described in the paper "High Precision Carry Look-Ahead Logic for Absolute Value and Two's Complement." The folders in this repository are named according to their outputs. For instance, the codes in `/Sign-and-Magnitude` take a two's complement input and produce a sign-and-magnitude output.

### Implementation
The codes in this repository are designed for integration with our [Serial Transceiver](https://github.com/ALUminaries/Serial-Transceiver). Please follow the instructions there to implement these algorithms for an actual FPGA. The codes in this repository alone are suitable for synthesis and simulation. Alternatively, these codes can be modified to work with a Xilinx Virtual IO IP core.

The subfolder in each primary folder contains a Kotlin script to generate various precisions of its respective algorithm. It also contains several prefabricated runs of this script. To create new bit precisions, simply modify and re-run the `Main.kt` file in the IntelliJ project. These scripts are not guaranteed to work for sizes that are not a power of 2 or sizes less than 32 bits, but have been tested on all powers of 2 between 32 and 4096 bits, and should work for higher precisions.