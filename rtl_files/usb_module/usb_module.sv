//==============================================================================
// Module: usb_tx_if
// Description:
//   AXI-Stream to USB FIFO transmit adapter.
//
//   Transfers streaming data from an AXI-Stream source into a USB FIFO
//   interface. Handles backpressure using AXI ready/valid handshake and
//   stalls transmission when the USB FIFO reports full.
//
// AXI-Stream Input:
//   s_tdata  : input data
//   s_tvalid : data valid
//   s_tready : ready for next word
//   s_tlast  : packet boundary (passed through but unused)
//
// USB FIFO Interface:
//   usb_data  : data bus to USB chip
//   usb_wr_en : write strobe
//   usb_full  : FIFO full indicator from USB chip
//==============================================================================

module usb_tx_if #(
    parameter DATA_W = 32
)(
    input  logic clk,
    input  logic rst,
    input  logic [DATA_W-1:0] s_tdata,
    input  logic s_tvalid,
    output logic s_tready,
    input  logic s_tlast,
    output logic [DATA_W-1:0] usb_data,
    output logic usb_wr_en,
    input  logic usb_full
);

    logic write_enable;
    assign s_tready = ~usb_full;
    assign write_enable = s_tvalid & ~usb_full;

    always_ff @(posedge clk) begin
        if (rst) begin
            usb_data <= '0;
            usb_wr_en <= 1'b0;
        end
        else begin
            usb_wr_en <= write_enable;

            if (write_enable) begin
                usb_data <= s_tdata;
            end
        end
    end

endmodule