// Simple UART Controller
module uart_controller (
    input wire clk,
    input wire reset,
    
    // Memory-mapped interface
    input wire        cmd_valid,
    output reg        cmd_ready,
    input wire        cmd_wr,
    input wire [31:0] cmd_address,
    input wire [31:0] cmd_data,
    output reg        rsp_ready,
    output reg [31:0] rsp_data,
    
    // UART pins
    input wire  uart_rx,
    output reg  uart_tx
);

    // Simple UART registers
    // 0x10001000: Data register
    // 0x10001004: Status register (bit 0: tx_ready, bit 1: rx_valid)
    
    reg [7:0] tx_data;
    reg tx_start;
    reg tx_ready;
    
    // Simple transmit state machine
    reg [3:0] tx_state;
    reg [15:0] baud_counter;
    parameter BAUD_DIV = 868; // 100MHz / 115200 ≈ 868
    
    always @(posedge clk) begin
        if (reset) begin
            cmd_ready <= 1'b1;
            rsp_ready <= 1'b1;
            rsp_data <= 32'h0;
            uart_tx <= 1'b1;
            tx_ready <= 1'b1;
            tx_start <= 1'b0;
            tx_state <= 4'h0;
            baud_counter <= 16'h0;
        end else begin
            cmd_ready <= 1'b1;
            rsp_ready <= 1'b1;
            tx_start <= 1'b0;
            
            // Memory interface
            if (cmd_valid) begin
                case (cmd_address)
                    32'h10001000: begin // Data register
                        if (cmd_wr && tx_ready) begin
                            tx_data <= cmd_data[7:0];
                            tx_start <= 1'b1;
                        end
                        rsp_data <= {24'h0, tx_data};
                    end
                    32'h10001004: begin // Status register
                        rsp_data <= {30'h0, 1'b0, tx_ready}; // rx_valid=0, tx_ready
                    end
                    default: rsp_data <= 32'h0;
                endcase
            end
            
            // UART transmit state machine
            case (tx_state)
                4'h0: begin // Idle
                    uart_tx <= 1'b1;
                    if (tx_start) begin
                        tx_ready <= 1'b0;
                        tx_state <= 4'h1;
                        baud_counter <= BAUD_DIV;
                    end
                end
                4'h1: begin // Start bit
                    uart_tx <= 1'b0;
                    if (baud_counter == 0) begin
                        tx_state <= 4'h2;
                        baud_counter <= BAUD_DIV;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
                4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin // Data bits
                    uart_tx <= tx_data[tx_state - 4'h2];
                    if (baud_counter == 0) begin
                        tx_state <= tx_state + 1;
                        baud_counter <= BAUD_DIV;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
                4'hA: begin // Stop bit
                    uart_tx <= 1'b1;
                    if (baud_counter == 0) begin
                        tx_state <= 4'h0;
                        tx_ready <= 1'b1;
                    end else begin
                        baud_counter <= baud_counter - 1;
                    end
                end
                default: tx_state <= 4'h0;
            endcase
        end
    end

endmodule