`timescale 1ns/1ps

module axi_capture_controller #(
    parameter int DATA_W = 32,
    parameter int USER_W = 8,
    parameter int TS_W   = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [DATA_W-1:0] s_tdata,
    input  logic s_tvalid,
    output logic s_tready,
    input  logic s_tlast,
    input  logic [USER_W-1:0] s_tuser,
    output logic [DATA_W-1:0] m_tdata,
    output logic m_tvalid,
    input  logic m_tready,
    output logic m_tlast,
    output logic [USER_W-1:0] m_tuser,
    input  logic trigger_in,
    input  logic [15:0] debounce_cycles,
    input  logic [15:0] capture_length,
    input  logic [TS_W-1:0] timestamp_counter,
    output logic [TS_W-1:0] latched_timestamp,
    output logic capture_active
);

    typedef enum logic [1:0] {
        IDLE,
        ARMED,
        CAPTURE
    } state_t;

    state_t state, next_state;

    logic [15:0]debounce_cnt;
    logic trigger_sync, trigger_prev;
    logic trigger_rise;
    logic [15:0] sample_count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            trigger_sync <= 0;
            trigger_prev <= 0;
        end
        else begin
            trigger_sync <= trigger_in;
            trigger_prev <= trigger_sync;
        end
    end

    assign trigger_rise = trigger_sync & ~trigger_prev;

    always_ff @(posedge clk) begin
        if (!rst_n) debounce_cnt <= 0;
        else if (trigger_rise) debounce_cnt <= debounce_cycles;
        else if (debounce_cnt != 0) debounce_cnt <= debounce_cnt - 1;
    end

    wire trigger_valid = (debounce_cnt == 1);
    

    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (trigger_valid) next_state = CAPTURE;
            end

            CAPTURE: begin
                if (sample_count == capture_length && m_tvalid && m_tready) next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    assign capture_active = (state == CAPTURE);

    always_ff @(posedge clk) begin
        if (!rst_n) sample_count <= 0;
        else if (state == IDLE) sample_count <= 0;
        else if (state == CAPTURE && s_tvalid && s_tready) sample_count <= sample_count + 1;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) latched_timestamp <= 0;
        else if (state == IDLE && trigger_valid) latched_timestamp <= timestamp_counter;
    end

    assign s_tready = (state == CAPTURE) && m_tready;
    assign m_tvalid = (state == CAPTURE) && s_tvalid;
    assign m_tdata  = s_tdata;
    assign m_tuser  = s_tuser;
    assign m_tlast  = (state == CAPTURE) &&(sample_count == capture_length - 1) && s_tvalid && s_tready;

endmodule
