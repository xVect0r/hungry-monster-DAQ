// Version--2
// Refined the ingress module according to initial planning 
// Added 2 channels which provide dual channel data pairs per clock cycle 

module data_ingress #(
    parameter int DATA_W = 32,
    //Addition v2:
    parameter int ADC_W = 16
) (
    input logic clk,
    input logic rst,
    axi_if.master m_axi,

    // Additions v2:
    input logic [15:0]adc_ch0,
    input logic [15:0]adc_ch1,
    input logic adc_valid

    

);
    // Splitting into two channels so deleting count generators v2
    // logic [ADC_W-1:0] ch0_count;
    // logic [ADC_W-1:0] ch1_count;

    logic tvalid_reg;
    logic [DATA_W-1:0] tdata_reg;
    


    assign m_axi.tvalid = tvalid_reg;
    assign m_axi.tdata = tdata_reg;
    assign m_axi.tlast = 1'b0;
    assign m_axi.tuser = '0;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            //Deleting count generators v2
            // ch0_count<=16'd0;
            // ch1_count<=16'd0;
            tvalid_reg<=1'b0;
            tdata_reg<='0;

        end
        else begin
            if(!tvalid_reg && adc_valid) begin
                tdata_reg<={adc_ch1,adc_ch0};
                tvalid_reg<=1'b1;
                // Deleting count generators v2
                // ch0_count<= ch0_count+16'd1;
                // ch1_count<= ch1_count+16'd1;


            end

            else if(tvalid_reg && m_axi.tready) begin
                
                // tdata_reg<={ch1_count,ch0_count};
                tvalid_reg<=1'b0;
                // ch0_count<= ch0_count+16'd1;
                // ch1_count<= ch1_count+16'd1;
            end
        end        
end



    
endmodule