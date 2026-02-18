// Version #2 
/*
The packeteizer will isolate input and output handshakes, will also see that the sample_cnt is used to control flow
The current state machine will be fixed with more isolation and packetizer flow control

*/

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

//Version #2 Control
logic word_active;

logic [7:0] channel_id;
logic [7:0] sample_cnt;
logic [1:0] byte_idx;
logic [7:0] payload_byte_cnt;
logic[1:0] sample_byte_idx;

// logic tlast_reg;

// wire notify = s_axi_if.tvalid && m_axi_if.tready;

//Version #2 Control signals to isolate input and output handshake

wire notify_out = m_axi_if.tvalid && m_axi_if.tready;
wire notify_in = s_axi_if.tvalid && s_axi_if.tready;


// always_comb header = 32'h30415144;

// assign m_axi_if.tdata = s_axi_if.tdata;
// assign m_axi_if.tuser = s_axi_if.tuser;
// assign m_axi_if.tvalid = s_axi_if.tvalid;
// assign m_axi_if.tready = s_axi_if.tready;
// assign m_axi_if.tlast = tlast_reg ;


//V2 state ff
always_ff @(posedge clk) begin
    if(rst) state_curr <= ST_IDLE;
    else state_curr <= state_next;

end
    
always_ff @( posedge clk ) begin 
    if (rst) begin

        //V2 changes
        // state_curr<= ST_IDLE;
        byte_idx <= 0;
        sample_cnt <= '0;
        payload_byte_cnt <= 0;
        word_active <= 0;
        sample_byte_idx<='0;
        // tlast_reg <= 1'b0;
    end

    else begin
        // tlast_reg <= notify && (sample_cnt == 254) ;
        // state_curr <= state_next;

        if (state_curr != state_next) byte_idx<=0;
        else if (notify_out) byte_idx<=byte_idx + 1;


        // if(notify) begin
        //     if (sample_count == 8'd255) begin
        //         sample_count <= '0;
        //     end
        //     else begin
        //         sample_count <= sample_count+1'b1;
        //     end

        //V2 Changes
        // if (state_curr == ST_IDLE && s_axi_if.tvalid && s_axi_if.tready) begin
        if (state_curr == ST_IDLE && notify_in && state_next == ST_HEADER) begin
            payload_byte_cnt<= 0;
            sample_cnt<=0;
            channel_id <= s_axi_if.tuser[3:0];
        end

        // if (state_curr == ST_PAYLOAD && s_axi_if.tvalid && s_axi_if.tready) begin
        if (state_curr == ST_PAYLOAD && notify_in && !word_active) begin
            payload_reg<= s_axi_if.tdata;
            
            payload_byte_cnt<= payload_byte_cnt+1;
            sample_byte_idx <= 0;
            word_active <= 1;
            sample_cnt <= sample_cnt+1;
        end
        //V2 Changes
        // if (state_curr == ST_PAYLOAD && notify) sample_byte_idx<=sample_byte_idx+1;
        if (state_curr == ST_PAYLOAD && notify_out && word_active) begin
            sample_byte_idx<=sample_byte_idx+1;
            // if(state_curr == ST_PAYLOAD && s_axi_if.tvalid && s_axi_if.tready) sample_cnt <= sample_cnt+1;
            // sample_cnt <= sample_cnt+1;
            if (sample_byte_idx == 2'd3) word_active <=0;
            
        end
        end
end

always_comb begin
    state_next = state_curr;

    m_axi_if.tvalid = 1'b0;
    m_axi_if.tdata = 8'h0;
    m_axi_if.tlast = 1'b0;
    s_axi_if.tready = 1'b0;

    case (state_curr)


        ST_IDLE: begin
            s_axi_if.tready = 1'b1;
            if (notify_in) state_next = ST_HEADER;

        end 

        ST_HEADER: begin
            m_axi_if.tvalid = 1'b1;
            m_axi_if.tdata = header >> (8*byte_idx);
            // if (notify && byte_idx == 3) state_next = ST_TIMESTAMP;
            if (notify_out && byte_idx == 2'd3) state_next = ST_TIMESTAMP;
        end

        ST_TIMESTAMP: begin
            m_axi_if.tvalid = 1'b1;
            m_axi_if.tdata = timestamp_latched >> (8*byte_idx);
            // if (notify && byte_idx == 3) state_next = ST_CHNID;
            if (notify_out && byte_idx == 2'd3) state_next = ST_CHNID;
        end

        ST_CHNID: begin
            m_axi_if.tvalid = 1'b1;
            m_axi_if.tdata = channel_id;
            // if (notify) state_next = ST_SAMPLECOUNT;
            if (notify_out) state_next = ST_SAMPLECOUNT;

        end

        ST_SAMPLECOUNT: begin
            m_axi_if.tvalid = 1'b1;
            m_axi_if.tdata = capture_len_cfg;

            // if (notify) state_next = ST_PAYLOAD;
            if (notify_out) state_next = ST_PAYLOAD;
            
        end
        ST_PAYLOAD: begin
            // s_axi_if.tready = m_axi_if.tready;
            s_axi_if.tready =!word_active;

            // if(s_axi_if.tready) begin
            if(word_active) begin
                m_axi_if.tvalid = 1'b1;
                m_axi_if.tdata = payload_reg >> (8*sample_byte_idx);
                // if(notify && payload_byte_cnt == 3) begin
                if(notify_out && sample_byte_idx == 2'd3) begin
                    // if (s_axi_if.tlast) state_next = ST_INFO;
                    if (sample_cnt == capture_len_cfg) state_next = ST_INFO;
                end
            end
        end
        ST_INFO: begin

            m_axi_if.tvalid = 1'b1;
            m_axi_if.tdata = error_flags >> (8* byte_idx);


            // if (notify && byte_idx == 2'd3) state_next = ST_DONE;
            if (notify_out && byte_idx == 2'd3) state_next = ST_DONE;
                
        end

        ST_DONE: begin
            m_axi_if.tvalid = 1'b1;
            m_axi_if.tdata = 8'h00;
            m_axi_if.tlast = 1'b1;

            // if(notify) state_next = ST_IDLE;
            if(notify_out) state_next = ST_IDLE;

        end
        default: state_next = ST_IDLE;

    endcase

end



endmodule