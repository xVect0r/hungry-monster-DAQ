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

    // Source Modport 
    modport master (
    input clk,
    input rst,
    input tready,
    
    output tdata,
    output tvalid,
    
    output tlast,
    output tuser

    );
    // Sink Modport
    modport slave (
        input clk,
        input rst,
        input tdata,
        input tvalid,
        input tlast,
        input tuser,

        output tready
    );
    
endinterface //axi_stream_if
