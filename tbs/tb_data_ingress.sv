`timescale 1ns/1ps

module tb_data_ingress;

logic clk;
logic rst;

always #4 clk=~clk;

axi_stream_if #(32) axi_if_tb ();

data_ingress dut(.clk(clk),.rst(rst),.m_axi(axi_if_tb));

logic [31:0] last_data;
int accepted_count;

always_ff@(posedge clk) begin
    if (rst) begin
        axi_if_tb.tready <= 1'b0;
    end
    else begin

    end
end

always_ff @( posedge clk ) begin 
    if(rst) begin
        accepted_count<=0;
        last_data<='0;

    end else begin
        axi_if_tb.tready <= $urandom_range(0,1);
    end
    
end

always_ff @( posedge clk ) begin 
    if (rst) begin
        accepted_count <= 0;
        last_data <= '0;
    end
    else begin
        if (axi_if_tb.tvalid && axi_if_tb.tready) begin
            accepted_count <= accepted_count+1;
            if (accepted_count > 0) begin
                assert (axi_if_tb.tdata == last_data+32'h0001_0001) 
                else $fatal("DATA ERROR: Non-monotonic data at count %0d",accepted_count);
            end

            last_data <= axi_if_tb.tdata;
        end
    end
end

logic [31:0] held_data;

always_ff @( posedge clk ) begin 
    if (rst) begin
        held_data <= '0;
    end else begin
        if (axi_if_tb.tvalid && !axi_if_tb.tready) begin
            if (held_data == '0) begin
                held_data <= axi_if_tb.tdata;
            end
            else begin
                assert(axi_if_tb.tdata == held_data)
                else $fatal("AXI ERROR: tdata changed under backpressure");
            end
        end else begin
            held_data <= '0;
        end
    end
    
end

initial begin
    clk = 0;
    rst = 1;
    
    repeat (10)@(posedge clk);
    rst = 0;
    repeat (2000)@(posedge clk);

    $display("Simulation Passed. Acceped Smaples = %0d", accepted_count);
    $finish;

end

endmodule
// Clock reset