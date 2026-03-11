`timescale 1ns/1ps

module tb_usb_tx_if;

    logic clk;
    logic rst;

    logic [31:0] s_tdata;
    logic s_tvalid;
    logic s_tready;
    logic s_tlast;

    logic [31:0] usb_data;
    logic usb_wr_en;
    logic usb_full;

    // DUT
    usb_tx_if dut (
        .clk(clk),
        .rst(rst),

        .s_tdata(s_tdata),
        .s_tvalid(s_tvalid),
        .s_tready(s_tready),
        .s_tlast(s_tlast),

        .usb_data(usb_data),
        .usb_wr_en(usb_wr_en),
        .usb_full(usb_full)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    // Test sequence
    initial begin

        rst = 1;
        s_tvalid = 0;
        usb_full = 0;

        #20;
        rst = 0;

        // Send 10 data words
        repeat (10) begin
            @(posedge clk);
            s_tdata  = $random;
            s_tvalid = 1;
            s_tlast  = 0;

            wait(s_tready);
        end

        s_tvalid = 0;

        // Simulate USB FIFO becoming full
        @(posedge clk);
        usb_full = 1;

        repeat(5) @(posedge clk);

        usb_full = 0;

        // Send more data
        repeat (5) begin
            @(posedge clk);
            s_tdata  = $random;
            s_tvalid = 1;
            wait(s_tready);
        end

        s_tvalid = 0;

        #100;
        $finish;

    end

endmodule