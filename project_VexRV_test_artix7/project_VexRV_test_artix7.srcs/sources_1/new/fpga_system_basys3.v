//==============================================================================
// Enhanced FPGA Top Module with Clock Management
//==============================================================================

module fpga_system_basys3 (
    input wire clk,              // 100MHz Basys3 clock
    input wire reset_btn,        // Center button (active high)
    
    // Basys3 connections
    input wire [15:0]  switches,
    output wire [15:0] leds,
    output wire        uart_tx,
    input wire         uart_rx
);

    // Clock and reset management
    wire clk_cpu;        // CPU clock (can be different from board clock)
    wire reset_sync;     // Synchronized reset
    wire locked;         // PLL locked signal
    
    // Clock generation (optional - can use 100MHz directly)
    // For now, use direct connection
    assign clk_cpu = clk;
    assign locked = 1'b1;
    
    // Reset synchronizer for proper reset release
    reg [3:0] reset_sync_reg = 4'hF;
    always @(posedge clk_cpu or posedge reset_btn) begin
        if (reset_btn) begin
            reset_sync_reg <= 4'hF;
        end else if (locked) begin
            reset_sync_reg <= {reset_sync_reg[2:0], 1'b0};
        end
    end
    assign reset_sync = reset_sync_reg[3];
    
    // Instantiate the main FPGA system
    fpga_system_top system_core (
        .clk(clk_cpu),
        .reset(reset_sync),
        .switches(switches),
        .leds(leds),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

endmodule