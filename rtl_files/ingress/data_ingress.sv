//==============================================================================
// Module Name : data_ingress
// Project     : FPGA-Based DAQ System
// Author      : Soumyadip Roy
// Description : Converts parallel ADC samples into AXI-Stream formatted data.
//               Packs dual-channel ADC inputs into a single streaming word
//               and generates valid handshake signals.
//
// Functionality:
//   - Captures ADC samples when adc_valid is asserted
//   - Packs adc_ch1 and adc_ch0 into DATA_W-wide word
//   - Generates AXI-Stream tvalid
//   - Clears tvalid upon downstream handshake completion
//   - Drives constant tlast and tuser defaults
//
// Parameters:
//   - DATA_W : AXI-Stream data width
//   - ADC_W  : Width of individual ADC channel
//
// Interfaces:
//   Inputs:
//     - clk       : System clock
//     - rst       : Active-high synchronous reset
//     - adc_ch0   : ADC channel 0 input
//     - adc_ch1   : ADC channel 1 input
//     - adc_valid : ADC data valid indicator
//     - m_axi.tready : Downstream ready signal
//
//   Outputs:
//     - m_axi     : AXI-Stream master interface
//
// Notes:
//   - Fully synthesizable
//   - Maintains proper AXI handshake discipline
//   - Designed for continuous streaming ADC front-end integration
//==============================================================================

module data_ingress #(
    parameter int DATA_W = 32,
    parameter int ADC_W = 16
) (
    input logic clk,
    input logic rst,
    axi_if.master m_axi,
    input logic [15:0]adc_ch0,
    input logic [15:0]adc_ch1,
    input logic adc_valid

    

);

    logic tvalid_reg;
    logic [DATA_W-1:0] tdata_reg;
    


    assign m_axi.tvalid = tvalid_reg;
    assign m_axi.tdata = tdata_reg;
    assign m_axi.tlast = 1'b0;
    assign m_axi.tuser = '0;

    always_ff @( posedge clk ) begin 
        if (rst) begin
            tvalid_reg<=1'b0;
            tdata_reg<='0;

        end
        else begin
            if(!tvalid_reg && adc_valid) begin
                tdata_reg<={adc_ch1,adc_ch0};
                tvalid_reg<=1'b1;


            end

            else if(tvalid_reg && m_axi.tready) begin
                tvalid_reg<=1'b0;
            end
        end        
end



    
endmodule