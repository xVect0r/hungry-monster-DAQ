//==============================================================================
// Module Name : daq_top
// Project     : FPGA-Based DAQ System
// Author      : Soumyadip Roy
// Description : Top-level integration module for the FPGA-based DAQ pipeline.
//               Connects data ingress, capture control, FIFO buffering, and
//               packetization into a complete AXI-Stream based architecture.
//
// Functionality:
//   - Interfaces with external ADC inputs
//   - Performs trigger-based bounded capture
//   - Buffers captured samples through AXI FIFO (FWFT capable)
//   - Packetizes data with timestamp and metadata
//   - Streams final packet over AXI-Stream output
//
// Interfaces:
//   Inputs:
//     - clk               : System clock
//     - rst               : Active-high synchronous reset
//     - adc_ch0/ch1       : ADC input channels
//     - adc_valid         : ADC data valid indicator
//     - trigger_in        : External trigger signal
//     - timestamp_counter : Free-running system timestamp
//     - capture_len_cfg   : Configurable capture length
//     - error_flags       : Status/error metadata for packet header
//     - tx_ready          : Downstream AXI ready signal
//
//   Outputs:
//     - tx_data           : Packetized output data stream
//     - tx_valid          : Output data valid indicator
//     - tx_last           : End-of-packet indicator
//     - capture_active    : Indicates active capture window
//
// Notes:
//   - Structured as a fully streaming AXI-Stream pipeline
//   - Modular architecture enables easy subsystem verification
//   - Designed for clean timing closure and synthesis portability
//==============================================================================

module daq_top (
    input logic clk,
    input logic rst,

    input logic [15:0] adc_ch0,
    input logic [15:0] adc_ch1,
    input logic adc_valid,

    input logic trigger_in,

    input logic [31:0] timestamp_counter,

    input logic [7:0] capture_len_cfg,
    input logic [15:0] error_flags,

    output logic [7:0] tx_data,
    output logic tx_valid,
    input  logic tx_ready,
    output logic tx_last,
    
    output logic capture_active
);

    axi_if ingress_if(clk, rst);
    axi_if capture_if(clk, rst);
    axi_if fifo_if(clk, rst);
    axi_if packet_if(clk, rst);

    logic [31:0] latched_timestamp;

    data_ingress u_ingress (
        .clk(clk),
        .rst(rst),
        .m_axi(ingress_if),
        .adc_ch0(adc_ch0),
        .adc_ch1(adc_ch1),
        .adc_valid(adc_valid)
    );

    axi_capture_controller u_capture (
        .clk(clk),
        .rst(rst),
        .s_axi_if(ingress_if),
        .m_axi_if(capture_if),
        .trigger_in(trigger_in),
        .debounce_cycles(16'd2),
        .capture_length(capture_len_cfg),
        .timestamp_counter(timestamp_counter),
        .latched_timestamp(latched_timestamp),
        .capture_active(capture_active)
    );

    axi_fifo u_fifo (
        .clk(clk),
        .rst(rst),
        .s_axi_if(capture_if),
        .m_axi_if(fifo_if)
    );

    axi_packetizer u_packetizer (
        .clk(clk),
        .rst(rst),
        .s_axi_if(fifo_if),
        .m_axi_if(packet_if),
        .timestamp_latched(latched_timestamp),
        .capture_len_cfg(capture_len_cfg),
        .error_flags(error_flags)
    );

    assign tx_data  = packet_if.tdata;
    assign tx_valid = packet_if.tvalid;
    assign packet_if.tready = tx_ready;
    assign tx_last  = packet_if.tlast;

endmodule
