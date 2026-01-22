Arty S7 FPGA FM Synthesizer
* A real-time Frequency Modulation (FM) synthesizer implemented in SystemVerilog for the Arty S7-50 FPGA.

Project Structure
* /hdl: SystemVerilog source files (DDS, UART, I2S, Top Level).
* /scripts: Tcl build scripts and Python visualizer.
* /constraints: Hardware constraints for the Arty S7-50.
* /docs: Hardware Design Document and Roadmap.

Features
* Dual DDS Architecture: Independent Carrier and Modulator engines.
* Musical FM: Smooth vibrato and metallic textures via signed arithmetic.
* Visualizer: Real-time waveform telemetry via UART and Python.
* Standalone Control: Pitch bend and volume cycling via on-board buttons.

How to Build
* open Vivado.
* Run source scripts/build.tcl in the Tcl console.
* Program the Arty S7-50 and connect the Pmod I2S2 to the JB header.
