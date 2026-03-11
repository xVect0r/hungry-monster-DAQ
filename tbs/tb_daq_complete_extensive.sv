`timescale 1ns/1ps

module tb_daq_top;

logic clk;
logic rst;
logic [15:0]adc_ch0;
logic [15:0]adc_ch1;
logic adc_valid;
logic trigger;
logic [31:0]timestamp_counter;
logic [7:0]capture_len_cfg;
logic [15:0]error_flags;
logic usb_full;
logic [7:0]tx_data;
logic tx_valid;
logic tx_ready;
logic tx_last;
logic capture_active;
logic [31:0]usb_data;
logic usb_wr_en;


daq_top dut(
    .clk(clk),
    .rst(rst),
    .adc_ch0(adc_ch0),
    .adc_ch1(adc_ch1),
    .adc_valid(adc_valid),
    .trigger_in(trigger),
    .timestamp_counter(timestamp_counter),
    .capture_len_cfg(capture_len_cfg),
    .error_flags(error_flags),
    .usb_full(usb_full),
    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready),
    .tx_last(tx_last),
    .capture_active(capture_active),
    .usb_data(usb_data),
    .usb_wr_en(usb_wr_en)
);

initial begin
    clk = 1'b0;
    forever #5 clk=~clk;
end

always @(posedge clk) begin
    if(rst) begin
        timestamp_counter<=0;
    
    end
    else begin
        timestamp_counter <= timestamp_counter+1'b1;
    end
    
end

task adc_stream;
integer i;

begin
    for(i=0;i<200;i++)begin
        @(posedge clk);
        adc_valid = 1;
        adc_ch0 = $random;
        adc_ch1 = $random;
    end
    adc_valid = 0;
end
    
endtask //adc_stream

task send_trigger;
begin
    @(posedge clk);
    trigger = 1;
    @(posedge clk);
    trigger = 0;

end

endtask

initial begin
    clk=0;
    rst=1;
    adc_ch0=0;
    adc_ch1=0;
    adc_valid=0;

    trigger = 0;
    tx_ready = 1;
    usb_full=0;
    capture_len_cfg=8'd16;
    error_flags=0;

    #50 rst=0;
    fork
        adc_stream();
    join_none

    #100

    send_trigger();

    #2000

    $finish;

end

endmodule



