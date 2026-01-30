`timescale 1ns/1ps

module tb_packetizer;

    localparam DATA_W = 32;
    localparam USER_W = 8;

    logic clk = 0;
    logic rst;

    always #5 clk = ~clk;

    axi_if #(DATA_W, USER_W) s_axi (.clk(clk),.rst(rst));
    axi_if #(DATA_W, USER_W) m_axi(.clk(clk),.rst(rst));

    axi_packetizer dut(.clk(clk),.rst(rst),.s_axi_if(s_axi),.m_axi_if(m_axi));

    initial begin
        rst = 1;
        s_axi.tvalid = 0;
        s_axi.tdata = '0;
        s_axi.tuser = 8'hA5;
        #40;
        rst = 0;

        repeat(600) begin
            @(posedge clk);
            s_axi.tvalid <= 1;
            s_axi.tdata <= s_axi.tdata+1;

        end

        s_axi.tvalid <= 0;
    
    end

    initial begin
        m_axi.tready = '1;

    end

    int axi_beat_count = 0;
    int axi_pkt_count = 0;

    always_ff @( posedge clk ) begin 
        
        if(rst) begin
            axi_beat_count <= 0;
            axi_pkt_count <= 0;

        end
        else if(m_axi.tvalid && m_axi.tready) begin
            if(m_axi.tlast) begin
                if(axi_beat_count != 255) begin
                    $fatal("TLAST EARLY/LATE AT AXI BEAT=%0d ", axi_beat_count);

                end
                axi_pkt_count <= axi_pkt_count+1;
                axi_beat_count <= 0;
            end
            else begin
                axi_beat_count <= axi_beat_count +1'b1;
            end
        end
    end

    initial begin
        #500000;
        $display("PACKETS RECIEVED = %0d", axi_pkt_count);
        $display("PACKETIZER TEST PASSED");
        $finish;
    end
endmodule