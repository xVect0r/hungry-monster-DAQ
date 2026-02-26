//==============================================================================
// Module Name : axi_capture_controller
// Project     : FPGA-Based DAQ System
// Author      : Soumyadip Roy
// Description : Controls triggered data acquisition over AXI-Stream.
//               Latches timestamp on trigger event and forwards a fixed
//               number of samples while maintaining AXI handshake integrity.
//
// Functionality:
//   - Synchronizes and debounces external trigger input
//   - Latches timestamp at trigger event
//   - Enables sample capture for configurable capture length
//   - Propagates AXI-Stream data with proper tvalid/tready flow control
//   - Generates tlast on final captured sample
//
// Interfaces:
//   Inputs:
//     - clk                : System clock
//     - rst                : Active-high synchronous reset
//     - trigger_in         : External trigger input
//     - debounce_cycles    : Trigger debounce duration
//     - capture_length     : Number of samples per capture window
//     - timestamp_counter  : Free-running timestamp reference
//     - s_axi_if           : AXI-Stream slave input interface
//
//   Outputs:
//     - m_axi_if           : AXI-Stream master output interface
//     - latched_timestamp  : Timestamp captured at trigger event
//     - capture_active     : High while capture FSM is active
//
// Notes:
//   - Fully synthesizable
//   - Implements edge detection and programmable debounce logic
//   - AXI handshake propagation avoids combinational flow issues
//   - Designed for deterministic sample-bounded acquisition
//==============================================================================

`timescale 1ns/1ps

module axi_capture_controller #(
    parameter int DATA_W = 32,
    parameter int USER_W = 8,
    parameter int TS_W   = 32
)(
    input  logic clk,
    input  logic rst,

    axi_if.slave  s_axi_if,
    axi_if.master m_axi_if,

    input  logic trigger_in,
    input  logic [15:0] debounce_cycles,
    input  logic [15:0] capture_length,

    
    input  logic [TS_W-1:0]timestamp_counter,
    output logic [TS_W-1:0]latched_timestamp,

    output logic capture_active
);

    typedef enum logic[1:0] {
        IDLE,
        CAPTURE
    } state_val;

    state_val state_curr, state_next;

    logic [15:0]debounce_cnt;
    logic trigger_sync, trigger_prev;
    logic trigger_rise;
    logic [15:0] sample_count;

    wire trigger_valid = (debounce_cnt == 16'd1);
    
    assign trigger_rise = trigger_sync & ~trigger_prev;

    assign capture_active = (state_curr == CAPTURE);
    assign s_axi_if.tready = (state_curr == CAPTURE) && m_axi_if.tready;

    assign m_axi_if.tvalid = (state_curr == CAPTURE) && s_axi_if.tvalid;
    assign m_axi_if.tdata  = s_axi_if.tdata;
    assign m_axi_if.tuser  = s_axi_if.tuser;

    assign m_axi_if.tlast =(state_curr == CAPTURE) && (sample_count == capture_length - 1) && s_axi_if.tvalid && s_axi_if.tready;

    always_ff @(posedge clk) begin
        if (rst) begin
            trigger_sync <= 1'b0;
            trigger_prev <= 1'b0;
        end
        else begin
            trigger_sync <= trigger_in;
            trigger_prev <= trigger_sync;
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            debounce_cnt <= 16'd0;
        else if (trigger_rise) debounce_cnt <= (debounce_cycles == 0) ? 16'd1 : debounce_cycles;
        else if (debounce_cnt != 0) debounce_cnt <= debounce_cnt - 1;
    end

    always_ff @(posedge clk) begin
        if (rst) state_curr <= IDLE;
        else state_curr <= state_next;
    end

    always_comb begin
        state_next = state_curr;

        case (state_curr)
            IDLE: begin
                if (trigger_valid) state_next =CAPTURE;
            end
            CAPTURE: begin
                if (m_axi_if.tvalid && m_axi_if.tready && (sample_count == capture_length-1)) state_next = IDLE;
            end
            default: state_next = IDLE;

        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) sample_count <= 16'd0;
        else if (state_curr == IDLE) sample_count <= 16'd0;
        else if (state_curr == CAPTURE && s_axi_if.tvalid && s_axi_if.tready) sample_count <= sample_count + 1'b1;
    end

    always_ff @(posedge clk) begin
        if (rst) latched_timestamp <= '0;
        else if (state_curr == IDLE && trigger_valid) latched_timestamp <= timestamp_counter;
    end


endmodule
