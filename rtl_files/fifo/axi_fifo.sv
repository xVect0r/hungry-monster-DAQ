//==============================================================================
// Module Name : axi_fifo
// Project     : FPGA-Based DAQ System
// Author      : Soumyadip Roy
// Description : Parameterizable AXI-Stream FIFO with First-Word Fall-Through
//               (FWFT) behavior for pipeline buffering and flow control.
//
// Functionality:
//   - Buffers AXI-Stream data entries (tdata, tlast, tuser)
//   - Implements circular memory with configurable depth
//   - Supports simultaneous push and pop operations
//   - Provides FWFT behavior using output register stage
//   - Maintains internal count for full/empty detection
//
// Parameters:
//   - DATA_W : Width of data bus
//   - USER_W : Width of sideband user signal
//   - DEPTH  : FIFO storage depth
//
// Interfaces:
//   Inputs:
//     - clk        : System clock
//     - rst        : Active-high synchronous reset
//     - s_axi_if   : AXI-Stream slave input interface
//
//   Outputs:
//     - m_axi_if   : AXI-Stream master output interface
//
// Notes:
//   - Fully synthesizable circular buffer implementation
//   - Implements proper AXI handshake-based push/pop logic
//   - Output register ensures stable FWFT data presentation
//   - Designed for deterministic backpressure handling
//==============================================================================

module axi_fifo #(
    parameter int DATA_W = 32,
    parameter int USER_W = 8,
    parameter int DEPTH  = 16
)(
    input logic clk,
    input logic rst,

    axi_if.slave s_axi_if,
    axi_if.master m_axi_if
);

typedef struct packed {
    logic [DATA_W-1:0] data;
    logic last;
    logic [USER_W-1:0] user;
} fifo_entry_t;

fifo_entry_t mem [DEPTH];
fifo_entry_t out_reg;
logic out_valid;

logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
logic [$clog2(DEPTH)-1:0] rd_ptr_next;
logic [$clog2(DEPTH+1)-1:0] count;

wire push = s_axi_if.tvalid && s_axi_if.tready;
wire pop  = m_axi_if.tvalid && m_axi_if.tready;

assign s_axi_if.tready = (count < DEPTH);
assign m_axi_if.tvalid = out_valid;
assign rd_ptr_next = (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;


assign m_axi_if.tdata = out_reg.data;
assign m_axi_if.tlast = out_reg.last;
assign m_axi_if.tuser = out_reg.user;

always_ff @(posedge clk) begin
    if (rst) begin
        wr_ptr    <= '0;
        rd_ptr    <= '0;
        count     <= '0;
        out_valid <= 1'b0;
    end else begin
        if(push) begin
            mem[wr_ptr] <= '{s_axi_if.tdata, s_axi_if.tlast, s_axi_if.tuser};
            wr_ptr<= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
        end
        
        if (!out_valid&& count != 0) begin
            out_reg<= mem[rd_ptr];
            out_valid <= 1'b1;
        end

        else if(pop) begin
            rd_ptr<= rd_ptr_next;
            if(count>1) begin
               out_reg <= mem[rd_ptr_next];
               
            end
            else if(push) begin
                out_reg <= '{s_axi_if.tdata, s_axi_if.tlast, s_axi_if.tuser};

            end
            else begin
                out_valid <= 0;
            end
        end

        case({push, pop})
            2'b10: count <= count + 1'b1;
            2'b01: count <= count - 1'b1;
            default: ;
        endcase
    end
end

endmodule
