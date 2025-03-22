## Progetto di Reti Logiche – Final Project (PFRL 23/24)
This repository contains the final project for the "Progetto di Reti Logiche" course. The project involves designing a VHDL-based hardware module that processes a sequence of words stored in memory, replacing undefined values (zeros) with the last valid non-zero value, and computing a credibility value for each word.

&nbsp;
## Project Description
* Input: A sequence of K words (each between 0 and 255) stored in memory. Zeros indicate undefined values.

* Processing:

  * Replace each zero with the most recent non-zero value.

  * Compute a credibility value: assign 31 for non-zero words; for zeros, decrement the previous credibility (with a minimum of 0).

* Control Signals:

  * START: Triggers the processing with specified memory address and sequence length.

  * DONE: Indicates the completion of processing.

* Operation: The module supports consecutive sequence processing without requiring a reset between runs.


&nbsp;
## Simulation and Synthesis
* Simulation: Use the provided testbench to verify the module’s functionality.

* Synthesis: The design is synthesized using Xilinx Vivado WebPACK (recommended version 2016.4, targeting the Artix-7 FPGA family).

&nbsp;
## Setup and Usage
1. Environment: Open the project in your VHDL development environment.

2. Simulation: Run the testbench to simulate and verify functionality.

3. Synthesis: Use Xilinx Vivado WebPACK to synthesize the design and target your FPGA.

&nbsp;
## Author
* [Valerio Grillo](https://github.com/Valegrl) | valerio.grillo@mail.polimi.it
