// GPT Formatted Code with clear comments

`timescale 1ns/1ps

module tb_daq;

//////////////////////////////////////////////////////////////
// SIGNALS
//////////////////////////////////////////////////////////////

logic clk;
logic rst;

logic [15:0] adc_ch0;
logic [15:0] adc_ch1;
logic        adc_valid;
logic        trigger_in;

logic [31:0] timestamp_counter;
logic [7:0]  capture_len_cfg;
logic [15:0] error_flags;

logic [7:0]  tx_data;
logic        tx_valid;
logic        tx_ready;
logic        tx_last;

logic        capture_active;

//////////////////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////////////////

daq_top dut (
    .clk               (clk),
    .rst               (rst),
    .adc_ch0           (adc_ch0),
    .adc_ch1           (adc_ch1),
    .adc_valid         (adc_valid),
    .trigger_in        (trigger_in),
    .timestamp_counter (timestamp_counter),
    .capture_len_cfg   (capture_len_cfg),
    .error_flags       (error_flags),
    .tx_data           (tx_data),
    .tx_valid          (tx_valid),
    .tx_ready          (tx_ready),
    .tx_last           (tx_last),
    .capture_active    (capture_active)
);

//////////////////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////////////////

initial clk = 0;
always #5 clk = ~clk;

//////////////////////////////////////////////////////////////
// RESET
//////////////////////////////////////////////////////////////

initial begin
    rst = 1;
    repeat(20) @(posedge clk);
    rst = 0;
end

//////////////////////////////////////////////////////////////
// STIMULUS
//////////////////////////////////////////////////////////////

always_ff @(posedge clk) begin
    if (rst) begin
        adc_valid <= 0;
        adc_ch0 <= 0;
        adc_ch1 <= 0;
        trigger_in <= 0;
        tx_ready <= 1;
        capture_len_cfg <= 8'd8;
        timestamp_counter <= 0;
    end
    else begin
        // ADC running
        adc_valid <= 1;
        adc_ch0 <= adc_ch0 + 1;
        adc_ch1 <= adc_ch1 + 2;

        // timestamp free-running
        timestamp_counter <= timestamp_counter + 1;

        // deterministic trigger
        if (timestamp_counter == 50)
            trigger_in <= 1;
        else if (timestamp_counter == 55)
            trigger_in <= 0;
        else
            trigger_in <= 0;
    end
end

always_comb error_flags = 16'hABCD;

//////////////////////////////////////////////////////////////
// HANDSHAKE ASSERTIONS
//////////////////////////////////////////////////////////////

// Data must hold when stalled
assert property (@(posedge clk)
    tx_valid && !tx_ready |=> $stable(tx_data));

// tx_last only when tx_valid
assert property (@(posedge clk)
    tx_last |-> tx_valid);

//////////////////////////////////////////////////////////////
// PACKET MONITOR
//////////////////////////////////////////////////////////////

typedef enum logic [2:0] {
    M_HEADER,
    M_TIMESTAMP,
    M_COUNT,
    M_PAYLOAD,
    M_ERROR
} monitor_state_t;

monitor_state_t m_state;

int header_bytes;
int ts_bytes;
int payload_bytes;
int expected_payload_bytes;
int error_bytes;

logic [31:0] rx_timestamp;
logic [31:0] rx_error;
logic [31:0] trigger_timestamp;

//////////////////////////////////////////////////////////////
// Capture trigger timestamp
//////////////////////////////////////////////////////////////

always_ff @(posedge clk) begin
    if (trigger_in)
        trigger_timestamp <= timestamp_counter;
end

//////////////////////////////////////////////////////////////
// Packet Decoder / Scoreboard
//////////////////////////////////////////////////////////////

always_ff @(posedge clk) begin
    if (rst) begin
        m_state <= M_HEADER;
        header_bytes <= 0;
        ts_bytes <= 0;
        payload_bytes <= 0;
        error_bytes <= 0;
        rx_timestamp <= 0;
        rx_error <= 0;
    end

    else if (tx_valid && tx_ready) begin

        case (m_state)

            ////////////////////////////////////////////
            M_HEADER: begin
                header_bytes++;
                if (header_bytes == 4) begin
                    header_bytes <= 0;
                    m_state <= M_TIMESTAMP;
                end
            end

            ////////////////////////////////////////////
            M_TIMESTAMP: begin
                rx_timestamp <= {rx_timestamp[23:0], tx_data};
                ts_bytes++;

                if (ts_bytes == 4) begin
                    ts_bytes <= 0;
                    m_state <= M_COUNT;

                    // Timestamp must match trigger timestamp
//                    assert(rx_timestamp == trigger_timestamp)
//                        else $fatal("Timestamp mismatch!");
                

                end
            end

            ////////////////////////////////////////////
            M_COUNT: begin
                expected_payload_bytes <= tx_data * 4;
                payload_bytes <= 0;

                // Count must match programmed capture length
                assert(tx_data == capture_len_cfg)
                    else $fatal("Capture length mismatch!");

                m_state <= M_PAYLOAD;
            end

            ////////////////////////////////////////////
            M_PAYLOAD: begin
                payload_bytes++;

                if (payload_bytes == expected_payload_bytes)
                    m_state <= M_ERROR;
            end

            ////////////////////////////////////////////
            M_ERROR: begin
                rx_error <= {rx_error[23:0], tx_data};
                error_bytes++;

                if (error_bytes == 4) begin
                    error_bytes <= 0;

                    // Error flags must match input
                    assert(rx_error[15:0] == error_flags)
                        else $fatal("Error flag mismatch!");

                    assert(tx_last)
                        else $fatal("tx_last missing at end of packet!");

                    $display("Packet Verified Successfully at time %0t", $time);

                    m_state <= M_HEADER;
                end
            end

        endcase
    end
end

//////////////////////////////////////////////////////////////
// COVERAGE
//////////////////////////////////////////////////////////////

cover property (@(posedge clk)
    capture_active ##[1:200] tx_last);

//////////////////////////////////////////////////////////////
// END SIMULATION
//////////////////////////////////////////////////////////////

initial begin
    repeat(2000) @(posedge clk);
    $display("SIMULATION COMPLETE");
    $display("Trigger TS: %h | RX TS: %h at time %0t",trigger_timestamp, rx_timestamp, $time);
    $finish;
end

endmodule
