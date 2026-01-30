### DAQ Module Contract:

#### Requirements:

- ADC Target: 16 bit
- Data Source: Generated Noise+Signal File
- Rate: 125 Msps
- Channels: 2
- Channel Packing: Parallel

- External Button Trigger
- Timestamped Data
- 1 clock Domain

- Throughput output: 16x25Mx2 = 800Mb/s = 100MB/s
- USB output
- csv file format
- Packet alignment: byte-aligned
- Endianness: little

- Trigger Type: Rising Edge
- Trigger Debounce: N Clock Cycles
- Trigger behaviour:
    - Arms capture
    - Starts sample window
    - Generated packet boundary (tlast)

- Capture Length:
    - Fixed: 16 samples per trigger
    - Configurable via register

- Timestamp:
    - Width: 32 bits
    - Resolution: 8 ns (125 MHz clock)
    - Reset: power-on
    - Latched at trigger

#### Output Format:
1. Timestamp
2. Channel_ID
3. Sample_Index
4. Sample_Value
5. Error_Flag

#### Modules:
- Module 1: Data Ingress Module
- Module 2:Clock and CDC Layer
- Module 3:Buffering Layer
    - FIFO: BRAM
    - Minimum Depth: 8 Samples
    - Overflow policy: drop packet + Update Flag

- Module 4:Processing Blocks
    - Decimation (configurable factor)
    - Simple FIR (enable/disable)
    - Threshold detector (future)
    - All processing blocks must preserve AXI-Stream handshake

- Module 5:Packetization
- Module 6:Transport Adapter
    -Backpressure Handling:
        - Data continues in FIFO 
        - If limit reached, drop all incoming packets and update the error flag
#### Control Interface:
- Mode Select (debug/burst)
- Capture length
- Decimation factor
- Enable/Disable processing blocks
- Status & Error Flags

#### Reset Behaviours:
- Clear FIFOs
- Resets timestamp counter
- Disarms trigger

#### Communication Protocols:
- Internal Protocol: AXI Stream
    - tdata
    - tvalid
    - tready
    - tlast
    - tuser

- Outer Protocol: USB FIFO bridge

#### Data Packet Structure:

- [Header] - 4
- [Timestamp] - 4
- [Channel_ID] - 1
- [Sample_Count] - 5
- [Payload] - 16
- [Info_Failure] - 2

#### Error Handling:
- FIFO Overflow:
    - Flush FIFO and Resume
- Missed Trigger:
    - Last assumed Value with Failure Flag
- USB Backpressure:
    - Detection and data storage for temporary data relief






