# FPGA-Based Triggered DAQ System

A fully synthesizable, AXI-Stream based Data Acquisition (DAQ) pipeline implemented in SystemVerilog.  
Designed for deterministic, trigger-driven capture, structured packet framing, and clean timing closure.

---

##  Overview

This project implements a modular FPGA-based DAQ architecture with:

- Trigger-based bounded capture
- Timestamp latching
- AXI-Stream compliant data movement
- First-Word Fall-Through (FWFT) FIFO buffering
- Structured byte-level packetization
- Full handshake-driven flow control
- Clean synthesis and timing closure in Vivado

The system is designed with portability, verification robustness, and architectural clarity in mind.

---

##  Architecture

ADC → Data Ingress → Capture Controller → AXI FIFO → Packetizer → TX Stream

### Module Breakdown

| Module | Description |
|--------|-------------|
| `data_ingress` | Packs dual-channel ADC samples into AXI-Stream format |
| `axi_capture_controller` | Trigger synchronization, debounce logic, bounded capture window |
| `axi_fifo` | Circular FWFT AXI-Stream FIFO with backpressure support |
| `axi_packetizer` | Byte-level FSM-based packet formatter |
| `daq_top` | Top-level integration wrapper |

---

##  Packet Format

Each acquisition produces a structured byte-oriented packet:

[HEADER][TIMESTAMP][CHANNEL_ID][SAMPLE_COUNT]
[PAYLOAD...][ERROR_FLAGS][END]


### Field Description

- **HEADER**: 32-bit fixed signature
- **TIMESTAMP**: Latched system timestamp at trigger
- **CHANNEL_ID**: Source channel identifier
- **SAMPLE_COUNT**: Capture length
- **PAYLOAD**: Serialized ADC samples
- **ERROR_FLAGS**: Status/diagnostic metadata
- **END**: Packet termination (`tlast` asserted)

---

##  AXI-Stream Compliance

All modules follow strict AXI-Stream handshake discipline:

- `tvalid` asserted only when data is stable
- `tready` fully respected
- No combinational handshake paths
- State transitions occur only on valid handshakes

This ensures deterministic timing and clean synthesis behavior.

---

##  Design Highlights

### Trigger Handling
- Edge detection with synchronization
- Programmable debounce window
- Timestamp latched at trigger event

### Capture Control
- Fixed-length capture window
- Clean return to idle
- Deterministic `tlast` generation

### FIFO
- Parameterizable depth
- Circular memory structure
- First-Word Fall-Through (FWFT) behavior
- Simultaneous push/pop support

### Packetizer
- Multi-state FSM-based packet framing engine
- Byte-level serialization of 32-bit words
- Metadata insertion (timestamp, channel ID, sample count)
- Error/status field embedding
- Deterministic packet termination using `tlast`

---

##  Timing & Synthesis

The design is fully synthesizable and has been implemented in Xilinx Vivado with:

- Target Clock: **100 MHz**
- Single clock domain architecture
- Clean timing closure (no failing paths)
- No inferred latches
- No combinational handshake loops

The architecture prioritizes:

- Register-based state transitions  
- Controlled data movement  
- Minimal combinational depth  

This enables predictable timing behavior and straightforward closure.

---

##  Throughput Characteristics

- ADC Width: 16-bit
- Channels: 2 (parallel packed)
- Internal Data Width: 32-bit AXI-Stream
- Packetized Output: Byte-oriented stream
- Triggered bounded capture (configurable length)

The architecture supports deterministic packet generation with backpressure-safe propagation through all modules.

---

##  Flow Control Strategy

The entire pipeline respects AXI-Stream flow control:

- Backpressure propagates upstream
- FIFO absorbs short bursts
- Packetizer only advances on valid handshake
- No data is dropped silently

This ensures:

- Stable streaming behavior
- Safe interaction with slower downstream transport layers
- Deterministic packet boundaries

---

##  Verification Strategy

The system was verified using:

- Self-checking SystemVerilog testbench
- Handshake-aware stimulus generation
- Corner-case trigger scenarios
- Assertion-based failure detection
- Timestamp validation checks
- Packet boundary verification (`tlast` alignment)

Simulation validated:

- Proper trigger arming/disarming
- Correct sample window length
- Accurate timestamp latching
- Proper packet structure
- No handshake violations

---

## 🛠 Reset Behavior

On reset:

- Capture FSM returns to IDLE
- Timestamp latch clears
- FIFO pointers reset
- Trigger is disarmed
- Output stream becomes idle

This ensures deterministic startup behavior.

---

##  Transport Layer (Next Stage)

The current implementation provides a clean AXI-Stream packet output suitable for:

- USB FIFO bridges
- UART adapters
- Ethernet MAC layers
- DMA engines
- Custom transport modules

The transport adapter is intentionally modular to allow hardware-specific integration without modifying the core DAQ logic.

---

##  Future Extensions

The architecture is designed for extensibility. Planned enhancements include:

- BRAM-backed deep FIFO
- Configurable decimation block
- Optional FIR filtering
- Threshold detection logic
- AXI-Lite control interface
- Multi-channel scalability
- Dedicated transport adapter (USB/Ethernet)

---

##  Project Objective

This project demonstrates:

- Structured FPGA system architecture
- AXI-Stream protocol discipline
- FSM-based packet framing
- Trigger-driven deterministic capture
- Flow-control-safe streaming design
- Clean timing closure methodology

The goal was not just to “stream data,” but to build a robust, modular, and timing-safe DAQ core suitable for real hardware deployment.

---

##  License

Open-source for learning and educational purposes.  
Attribution appreciated.

---

##  Author

**Soumyadip Roy**  
FPGA / Embedded Systems Engineer  
SystemVerilog | AXI | Digital Design | Verification
