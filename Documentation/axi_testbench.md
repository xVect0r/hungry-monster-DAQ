# Testbench_FIFO_Document

## Design:

The Design shall have 3 components :
1. AXI Source
    - A continuously increasing data counter
    - Randomly assert and deassert tvalid
    - Doesnt violate AXI rules
2. AXI Sink
    - Randomly assert and deassert tready
    - Apply a few long stalls
    - Accept the data when ready
3. Scorekeeping Module
    - Track what was sent
    - Track what was recieved
    - Compare sequence integrity
    - Count both successful and failed data packets seperately

## Test Scenarios:

1. No backpressure test:
    - Forms the baseline for performance
    - tready is always high
    - fifo behaves like a wire
    - count should be within 5% of 0

2. Output stalled-Input running:
    - s_axi_if.tvalid is set high
    - m_axi_if.tready is set low
    - Expectations:
        - Fifo gets filled
        - s_axi_if gets deasserted
        - Minimal data corruption takes place
3. Input Stalled-Output open:
    - Stop write
    - Allow read to continue
    - Expectation:
        - FIFO empties out
        - m_axi_if.tvalid deasserts when fifo is empty

4. Random push/pop Events :
    - Random tvalid and tready assertions and deassertions
    - Tested over a thousand cycles
    - Expectations:
        - No assertion failure
        - Sequence integrity preserved

## Checkpoints:

1. Data stability under backpressure:\
If { m_axi_if.tvalid == 1 and m_axi_if.tready == 0 }==>{ tdata, tlast, tuser **must not change** }\

2. No underflow:\
If {count == 0} ==> {**m_axi_if.tvalid == 0**}\

3. No overflow:\
If {count==DEPTH} ==> {**s_axi_if.tready == 0**}\

4. Sequence Correctness:\
Sequence of Input must Match the Sequence of Output

## Failure Definitions

### 1. Simulation Failure
### 2. $fatal signal
### 3. Checkpoint Failure
### 4. Count exceeds [0,DEPTH]
### 5. Output sequence matches input sequence


