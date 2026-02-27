//==============================================================================
// Module Name : axi_packetizer
// Project     : FPGA-Based DAQ System
// Author      : Soumyadip Roy
// Description : Formats captured AXI-Stream data into a structured byte-level
//               packet containing header, timestamp, metadata, payload, and
//               error information.
//
// Functionality:
//   - Waits for captured sample stream
//   - Generates fixed header signature
//   - Inserts latched timestamp
//   - Appends channel ID and sample count
//   - Serializes multi-byte payload into byte-wise stream
//   - Appends error/status information
//   - Generates tlast at packet completion
//
// Packet Structure (Byte-Oriented):
//   [HEADER][TIMESTAMP][CHANNEL_ID][SAMPLE_COUNT]
//   [PAYLOAD...][ERROR_FLAGS][END]
//
// Interfaces:
//   Inputs:
//     - clk                : System clock
//     - rst                : Active-high synchronous reset
//     - s_axi_if           : AXI-Stream slave input (captured samples)
//     - timestamp_latched  : Timestamp captured at trigger event
//     - capture_len_cfg    : Configured number of samples per packet
//     - error_flags        : Error/status metadata
//     - m_axi_if.tready    : Downstream ready signal
//
//   Outputs:
//     - m_axi_if           : Byte-wise AXI-Stream packet output
//
// Notes:
//   - Fully synthesizable FSM-based packet generator
//   - Byte-serialization of 32-bit words via internal indexing
//   - Uses handshake-based state transitions (no combinational triggers)
//   - Designed for deterministic packet framing and timing closure
//==============================================================================

`timescale 1ns/1ps

module axi_packetizer #(
    parameter int DATA_W = 32,
    parameter int USER_W = 8
) (
    input logic clk,
    input logic rst,

    axi_if.slave s_axi_if,
    axi_if.master m_axi_if,

    input logic [31:0] timestamp_latched,
    input logic [7:0] capture_len_cfg,
    input logic [15:0] error_flags
);

typedef enum logic [3:0]{
    ST_IDLE,
    ST_HEADER,
    ST_TIMESTAMP,
    ST_CHNID,
    ST_SAMPLECOUNT,
    ST_PAYLOAD,
    ST_INFO,
    ST_DONE
} trans_state ;

trans_state state_curr, state_next;


logic [31:0] header=32'h30415144;
logic [31:0] payload_reg;
logic word_active;

logic [7:0] channel_id;
logic [7:0] sample_cnt;
logic [1:0] byte_idx;
logic [7:0] payload_byte_cnt;
logic[1:0] sample_byte_idx;
logic [7:0] capture_len_latched;
logic [31:0] timestamp_reg;
logic [15:0] error_flags_reg;

wire notify_out = m_axi_if.tvalid && m_axi_if.tready;
wire notify_in = s_axi_if.tvalid && s_axi_if.tready;


always_ff @(posedge clk) begin
    if(rst) state_curr <= ST_IDLE;
    else state_curr <= state_next;

end
    
always_ff @( posedge clk ) begin 
    if (rst) begin
        byte_idx <= 0;
        sample_cnt <= '0;
        payload_byte_cnt <= 0;
        word_active <= 0;
        sample_byte_idx<='0;
    end

    else begin

        if (state_curr != state_next) byte_idx<=0;
        else if (notify_out) byte_idx<=byte_idx + 1;

        if (state_curr == ST_IDLE && notify_in && state_next == ST_HEADER) begin
            payload_byte_cnt<= 0;
            sample_cnt<=0;
            channel_id <= s_axi_if.tuser[3:0];
            capture_len_latched <= capture_len_cfg;
            timestamp_reg <= timestamp_latched;
            error_flags_reg <= error_flags;

        end
        if (state_curr == ST_PAYLOAD && notify_in && !word_active) begin
            payload_reg<= s_axi_if.tdata;
            
            payload_byte_cnt<= payload_byte_cnt+1;
            sample_byte_idx <= 0;
            word_active <= 1;
            sample_cnt <= sample_cnt+1;
        end
        if (state_curr == ST_PAYLOAD && notify_out && word_active) begin
            sample_byte_idx<=sample_byte_idx+1;
            if (sample_byte_idx == 2'd3) word_active <=0;
            
        end
        end
end

always_ff @(posedge clk) begin
    if (rst) begin
        m_axi_if.tvalid <= 1'b0;
        m_axi_if.tdata  <= 8'h0;
        m_axi_if.tlast  <= 1'b0;
    end else begin
        m_axi_if.tvalid <= 1'b0;
        m_axi_if.tlast  <= 1'b0;

        case (state_next) 
            ST_IDLE: begin
                m_axi_if.tdata <= 8'h0;
            end
            
            ST_HEADER: begin
                m_axi_if.tvalid <= 1'b1;
                m_axi_if.tdata  <= header >> (8 * (state_curr == ST_HEADER ? (notify_out ? byte_idx + 1 : byte_idx) : 0));
            end

            ST_TIMESTAMP: begin
                m_axi_if.tvalid <= 1'b1;
                m_axi_if.tdata  <= timestamp_reg >> (8 * (state_curr == ST_TIMESTAMP ? (notify_out ? byte_idx + 1 : byte_idx) : 0));
            end

            ST_CHNID: begin
                m_axi_if.tvalid <= 1'b1;
                m_axi_if.tdata  <= channel_id;
            end

            ST_SAMPLECOUNT: begin
                m_axi_if.tvalid <= 1'b1;
                m_axi_if.tdata  <= capture_len_latched;
            end

            ST_PAYLOAD: begin
                if (word_active || (state_curr == ST_IDLE && notify_in)) begin
                    m_axi_if.tvalid <= 1'b1;
                    m_axi_if.tdata  <= (word_active) ? (payload_reg >> (8 * sample_byte_idx)) : s_axi_if.tdata[7:0];
                end
            end

            ST_INFO: begin
                m_axi_if.tvalid <= 1'b1;
                m_axi_if.tdata  <= error_flags_reg >> (8 * (state_curr == ST_INFO ? (notify_out ? byte_idx + 1 : byte_idx) : 0));
            end

            ST_DONE: begin
                m_axi_if.tvalid <= 1'b1;
                m_axi_if.tdata  <= 8'h00;
                m_axi_if.tlast  <= 1'b1;
            end
        endcase
    end
end

always_comb begin
    state_next = state_curr;
    s_axi_if.tready = 1'b0;

    case (state_curr)
        ST_IDLE: begin
            s_axi_if.tready = 1'b1;
            if (notify_in) state_next = ST_HEADER;
        end

        ST_HEADER: begin
            if (notify_out && byte_idx == 2'd3) state_next = ST_TIMESTAMP;
        end

        ST_TIMESTAMP: begin
            if (notify_out && byte_idx == 2'd3) state_next = ST_CHNID;
        end

        ST_CHNID: begin
            if (notify_out) state_next = ST_SAMPLECOUNT;
        end

        ST_SAMPLECOUNT: begin
            if (notify_out) state_next = ST_PAYLOAD;
        end

        ST_PAYLOAD: begin
            s_axi_if.tready = !word_active;
            if (notify_out && sample_byte_idx == 2'd3 && sample_cnt == capture_len_latched) 
                state_next = ST_INFO;
        end

        ST_INFO: begin
            if (notify_out && byte_idx == 1'd1) state_next = ST_DONE; 
        end

        ST_DONE: begin
            if (notify_out) state_next = ST_IDLE;
        end
    endcase
end


endmodule