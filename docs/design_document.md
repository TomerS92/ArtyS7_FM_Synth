# Hardware Design Document (HDD): Arty S7 FM Synthesizer IP

**Project Name:** Arty S7 Frequency Modulation (FM) Synthesizer  
**Version:** 1.0  
**Target Device:** Xilinx Spartan-7 (XC7S50-CSGA324)  
**Author:** Lead RTL Architect

---

## 1. System Overview

The Arty S7 FM Synthesizer is a high-precision digital signal processing (DSP) core capable of real-time FM synthesis. It utilizes a dual-oscillator architecture where a **Modulator** signal dynamically warps the frequency of a **Carrier** signal.

### 1.1 Key Features

- **Dual 32-bit DDS Engines** – Frequency resolution of `0.023 Hz @ 100 MHz`
- **Arithmetic FM Synthesis** – Signed modulation with saturation guards to prevent overflow
- **Hybrid Control Interface** – UART (remote) and Button/Switch (tactile) inputs
- **High-Fidelity Output** – 24-bit I2S Master @ 48 kHz
- **Telemetry Stream** – Sub-sampled 8-bit UART output for real-time visualization

---

## 2. Clocking and Reset Strategy

### 2.1 Clock Domains

| Clock Name   | Frequency   | Source     | Usage                                   |
|-------------|------------|------------|-----------------------------------------|
| `clk_100mhz` | 100.00 MHz | MMCM (IP) | Main system logic, UART, DSP pipeline   |
| `clk_audio`  | 12.288 MHz | MMCM (IP) | I2S master clock (256 × 48 kHz)         |

### 2.2 Reset Strategy

- **Hardware Reset:** `reset_n` (active low) via Pin C18  
  Synchronously clears all phase accumulators and command registers.

- **Software Reset:** `BTN3` triggers a prioritized reset of `carrier_offset`
  and `mod_offset`, restoring the **440 Hz** default state instantly.

---

## 3. Micro-Architecture

### 3.1 DDS Engine (Direct Digital Synthesis)

The core uses a **32-bit phase accumulator** to index a sine Look-Up Table (LUT).

**Phase Resolution:**

$$
f_{out} = \frac{FCW \cdot f_{clk}}{2^{32}}
$$

- **Phase Truncation:** Top 12 bits used for LUT addressing (4096 entries)
- **LUT Content:** 24-bit signed fixed-point sine values pre-calculated via `sin()`

---

### 3.2 FM Modulation Pipeline

The synthesis follows the operator equation:

$$
Final\_FCW = Base\_FCW + \frac{S_{mod} \times Depth}{2^{24}}
$$

- **Modulator:** 24-bit signed output
- **Multiplier:** 40-bit signed product (`Signal × Depth`)
- **Arithmetic Shift (`>>>`)** preserves sign while scaling modulation
- **Saturation Guard:** `always_comb` clamp prevents negative frequencies

---

## 4. Register Map & UART Interface

Remote control is achieved via an **8-digit Hex-ASCII UART** interface  
at **115,200 baud**.

| Command | Register     | Width  | Default | Description                              |
|--------|-------------|--------|---------|------------------------------------------|
| `F`    | CAR_FCW     | 32-bit | 49D2    | Carrier frequency (base pitch)           |
| `M`    | MOD_FCW     | 32-bit | 00D7    | Modulator frequency (wobble speed)       |
| `D`    | MOD_DEPTH   | 16-bit | 0200    | FM modulation depth                      |
| `A`    | AMPLITUDE   | 16-bit | FFFF    | Master digital gain                      |
| `W`    | WAVE_SEL    | 2-bit  | 00      | 0:Sine, 1:Saw, 2:Square, 3:Triangle      |

---

## 5. DSP Data Path & Precision

### 5.1 Volume Scaling

- **Input:** 24-bit signed waveform
- **Gain:** 16-bit unsigned value (UART amplitude × HW volume step)
- **Bit-Slicing:** Extract bits `[38:15]` from 40-bit product  
  Ensures unity gain and prevents clipping

---

### 5.2 Telemetry (Visualizer)

To bypass UART bandwidth limits, the audio stream is sub-sampled **1:10**.

- **Mapping:** `{ ~Audio[23], Audio[22:16] }`
- **Result:** 24-bit signed → 8-bit unsigned (centered at 128)

---

## 6. Verification & Implementation Details

- **Timing:** All paths meet 10 ns setup at 100 MHz
- **DRC:** No multiple-driver conflicts on UART TX
- **Debounce:** All physical inputs filtered using a 17-bit counter

---