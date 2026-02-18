// GPT Generated testbench

`timescale 1ns/1ps

module tb_daq_top;

    logic clk = 0;
    logic rst;

    always #5 clk = ~clk;   // 100 MHz

    logic [15:0] adc_ch0;
    logic [15:0] adc_ch1;
    logic adc_valid;
    logic trigger_in;

    logic [31:0] timestamp_counter;
    logic [7:0] capture_len_cfg;
    logic [15:0] error_flags;

    logic [7:0] tx_data;
    logic tx_valid;
    logic tx_ready;
    logic tx_last;

    daq_top DUT (
        .clk(clk),
        .rst(rst),
        .adc_ch0(adc_ch0),
        .adc_ch1(adc_ch1),
        .adc_valid(adc_valid),
        .trigger_in(trigger_in),
        .timestamp_counter(timestamp_counter),
        .capture_len_cfg(capture_len_cfg),
        .error_flags(error_flags),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_last(tx_last)
    );

    initial begin
        rst = 1;
        adc_valid = 0;
        trigger_in = 0;
        tx_ready = 1;
        capture_len_cfg = 4;
        error_flags = 16'hABCD;
        timestamp_counter = 32'h12345678;

        #50 rst = 0;

        // Trigger capture
        #20 trigger_in = 1;
        #10 trigger_in = 0;

        // Feed 4 samples
        repeat(4) begin
            @(posedge clk);
            adc_ch0 <= $random;
            adc_ch1 <= $random;
            adc_valid <= 1;
            @(posedge clk);
            adc_valid <= 0;
        end

        #500 $finish;
    end

endmodule
