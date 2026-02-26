//==============================================================================
// Interface Name : axi_if
// Project        : FPGA-Based DAQ System
// Author         : Soumyadip Roy
// Description    : Parameterizable AXI-Stream interface definition used for
//                  internal module communication within the DAQ pipeline.
//
// Functionality:
//   - Encapsulates AXI-Stream signals (tdata, tvalid, tready, tlast, tuser)
//   - Provides master and slave modports
//   - Ensures structured and reusable streaming connections
//
// Parameters:
//   - DATA_W : Width of AXI-Stream data bus
//   - USER_W : Width of AXI-Stream user sideband signal
//
// Signals:
//   - tdata  : Streaming data payload
//   - tvalid : Indicates valid data from transmitter
//   - tready : Indicates ready from receiver
//   - tlast  : End-of-packet indicator
//   - tuser  : User-defined sideband information
//
// Modports:
//   - master : Drives data and control, receives tready
//   - slave  : Receives data/control, drives tready
//
// Notes:
//   - Fully synthesizable
//   - AXI-Stream compliant handshake (tvalid & tready)
//   - Designed for modular streaming architecture
//==============================================================================

interface axi_if #(
    parameter int DATA_W = 32,
    parameter int USER_W = 8
)(
    input logic clk,
    input logic rst
);

    logic [DATA_W-1:0]tdata;
    logic tvalid;
    logic tready;
    logic tlast;
    logic [USER_W-1:0]tuser;

    modport master (
    input clk,
    input rst,
    input tready,
    
    output tdata,
    output tvalid,
    
    output tlast,
    output tuser

    );

    modport slave (
        input clk,
        input rst,
        input tdata,
        input tvalid,
        input tlast,
        input tuser,

        output tready
    );
    
endinterface
