`timescale 1ns/1ps
module tb_axi_fifo;
localparam int DATA_W = 32 ;
localparam int USER_W = 8;
localparam int DEPTH = 16;
logic clk;
logic rst;
always #4 clk =~clk;
axi_if #(DATA_W) s_axi (.clk(clk),.rst(rst));
axi_if #(DATA_W) m_axi (.clk(clk),.rst(rst));
axi_fifo #(
    .DATA_W(DATA_W),
    .USER_W(USER_W),
    .DEPTH(DEPTH)
) dut (
    .clk(clk),
    .rst(rst),
    .s_axi_if(s_axi),
    .m_axi_if(m_axi)
);
typedef struct packed {
    logic [DATA_W-1:0] data;
    logic last;
    logic [USER_W-1:0] user;
} sb_entry_t;
sb_entry_t sb_queue [$];
logic [15:0] ch0_count, ch1_count;

assign s_axi.tvalid = $urandom_range(0,1);

always_ff @( posedge clk ) begin 
    if(rst) begin
        s_axi.tvalid <= 0;
        s_axi.tdata <= '0;
        s_axi.tlast <= 0;
        s_axi.tuser <= '0;
        ch0_count <= 0;
        ch1_count <= 1;
    end
    else begin
        
        if(s_axi.tvalid && s_axi.tready) begin
            s_axi.tdata <= {ch1_count, ch0_count};
            s_axi.tlast <= 0;
            s_axi.tuser <= 8'hAA;
            sb_queue.push_back('{data:{ch1_count,ch0_count},last:0,user:8'hAA});
            ch0_count <= ch0_count+1;
            ch1_count <= ch1_count+1;
        end
    end
    
end
always_ff @( posedge clk ) begin
    if(rst) begin
        m_axi.tready <= 0;
    end
    else begin
        m_axi.tready <= $urandom_range(0,1);
    end
end

// CHANGE: Added sampling registers to avoid race condition
logic [DATA_W-1:0] sampled_tdata;
logic sampled_tvalid, sampled_tready;
logic [USER_W-1:0] sampled_tuser;
logic sampled_tlast;

always_ff @(posedge clk) begin
    if(rst) begin
        sampled_tdata <= '0;
        sampled_tvalid <= 0;
        sampled_tready <= 0;
        sampled_tuser <= '0;
        sampled_tlast <= 0;
    end
    else begin
        sampled_tdata <= m_axi.tdata;
        sampled_tvalid <= m_axi.tvalid;
        sampled_tready <= m_axi.tready;
        sampled_tuser <= m_axi.tuser;
        sampled_tlast <= m_axi.tlast;
    end
end

sb_entry_t exp;
// CHANGE: Modified checker to use sampled signals
always_ff @( posedge clk ) begin
    if(!rst && sampled_tvalid && sampled_tready) begin
        assert (sb_queue.size()>0)
        else $fatal(1, "UNDERFLOW_DETECTED:FIFO produceed data with empty score monitor");
        exp = sb_queue[0];
        assert(sampled_tdata == exp.data)
        else $fatal(1,"DATA MISMATCH");
        assert(sampled_tlast == exp.last)
        else $fatal(1, "TLAST MISMATCH");
        assert(sampled_tuser == exp.user)
        else $fatal(1, "TUSER MISMATCH");
        sb_queue.pop_front();
    end
end

logic [DATA_W-1:0] held_data;
logic holding;
always_ff @( posedge clk ) begin 
    if (rst) begin
        holding <= 0;
        held_data <= '0;
    end
    else begin
        if (m_axi.tvalid && !m_axi.tready) begin
            if(!holding) begin
                holding <= 1;
                held_data <= m_axi.tdata;
            end
            else begin
                assert(m_axi.tdata == held_data)
                else $fatal(1, "AXI VIOLATION: tdata changed under backpressure");
            end
        end
        else begin
            holding <= 0;
        end
    end
end
initial begin
    clk = 0;
    rst = 1;
    repeat(10)@(posedge clk);
    rst = 0;
    repeat (5000)@(posedge clk);
    while(sb_queue.size()>0) begin
        @(posedge clk);
        m_axi.tready = 1;
    end
    $display("FIFO TEST PASSED");
    $finish;
end
endmodule