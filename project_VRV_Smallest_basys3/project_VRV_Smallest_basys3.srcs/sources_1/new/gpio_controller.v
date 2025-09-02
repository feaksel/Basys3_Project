// GPIO Controller for Basys3 LEDs and Switches
module gpio_controller (
    input wire clk,
    input wire reset,
    
    // Memory-mapped interface
    input wire        cmd_valid,
    output reg        cmd_ready,
    input wire        cmd_wr,
    input wire [31:0] cmd_address,
    input wire [31:0] cmd_data,
    input wire [3:0]  cmd_mask,
    output reg        rsp_ready,
    output reg [31:0] rsp_data,
    
    // Basys3 connections
    input wire [15:0]  switches,
    output reg [15:0]  leds
);

    // Memory map:
    // 0x10000000: LED register (write)
    // 0x10000004: Switch register (read)
    
    always @(posedge clk) begin
        if (reset) begin
            cmd_ready <= 1'b1;
            rsp_ready <= 1'b1;
            rsp_data <= 32'h0;
            leds <= 16'h0;
        end else begin
            cmd_ready <= 1'b1;
            rsp_ready <= 1'b1;
            
            if (cmd_valid) begin
                case (cmd_address)
                    32'h10000000: begin // LED register
                        if (cmd_wr) begin
                            if (cmd_mask[0]) leds[7:0] <= cmd_data[7:0];
                            if (cmd_mask[1]) leds[15:8] <= cmd_data[15:8];
                        end
                        rsp_data <= {16'h0, leds};
                    end
                    32'h10000004: begin // Switch register
                        rsp_data <= {16'h0, switches};
                    end
                    default: begin
                        rsp_data <= 32'h0;
                    end
                endcase
            end
        end
    end

endmodule