`timescale 1ns/1ps

module axi_packetizer #(
    parameter int DATA_W = 32,
    parameter int USER_W = 8
) (
    input logic clk,
    input logic rst,

    axi_if.slave s_axi_if,
    axi_if.master m_axi_if
);

logic [7:0] sample_count;
logic tlast_reg;

wire notify = s_axi_if.tvalid && m_axi_if.tready;

assign m_axi_if.tdata = s_axi_if.tdata;
assign m_axi_if.tuser = s_axi_if.tuser;
assign m_axi_if.tvalid = s_axi_if.tvalid;
assign m_axi_if.tready = s_axi_if.tready;
assign m_axi_if.tlast = tlast_reg ;
    
always_ff @( posedge clk ) begin : blockName
    if (rst) begin
        sample_count <= '0;
        tlast_reg <= 1'b0;

    
    end
    else begin
        tlast_reg <= notify && (sample_count == 254) ;
        if(notify) begin
            if (sample_count == 8'd255) begin
               
                sample_count <= '0;
            end
            else begin
                sample_count <= sample_count+1'b1;
            end
        end
    end
end
endmodule