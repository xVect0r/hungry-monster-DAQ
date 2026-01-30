// Data Ingress Module
module data_ingress #(
    parameter int DATA_W = 32
) (
    input logic clk,
    input logic rst,
    axi_if.master m_axi
);

    // Internal Sample Generators

    logic [15:0] ch0_count;
    logic [15:0] ch1_count;

    // -- AXI Holding Registers
    logic tvalid_reg;
    logic [DATA_W-1:0] tdata_reg;

    // AXI assignments

    assign m_axi.tvalid = tvalid_reg;
    assign m_axi.tdata = tdata_reg;
    assign m_axi.tlast = 1'b0;
    assign m_axi.tuser = '0;

    //AXI Source Behaviour

    always_ff @( posedge clk ) begin 
        if (rst) begin
            ch0_count<=16'd0;
            ch1_count<=16'd0;
            tvalid_reg<=1'b0;
            tdata_reg<='0;

        end
        else begin
            if(!tvalid_reg) begin
                tdata_reg<={ch1_count,ch0_count};
                tvalid_reg<=1'b1;
                ch0_count<= ch0_count+16'd1;
                ch1_count<= ch1_count+16'd1;

            end

            else if(tvalid_reg && m_axi.tready) begin
                tdata_reg<={ch1_count,ch0_count};
                tvalid_reg<=1'b1;
                ch0_count<= ch0_count+16'd1;
                ch1_count<= ch1_count+16'd1;

            end
        end        
end



    
endmodule