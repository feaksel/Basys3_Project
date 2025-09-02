
// Address Decoder and Bus Arbiter
module address_decoder (
    input wire clk,
    input wire reset,
    
    // VexRiscv Data Bus input
    input wire        dBus_cmd_valid,
    output reg        dBus_cmd_ready,
    input wire        dBus_cmd_payload_wr,
    input wire [3:0]  dBus_cmd_payload_mask,
    input wire [31:0] dBus_cmd_payload_address,
    input wire [31:0] dBus_cmd_payload_data,
    output reg        dBus_rsp_ready,
    output reg [31:0] dBus_rsp_data,
    
    // Memory controller interface
    output reg        mem_cmd_valid,
    input wire        mem_cmd_ready,
    output reg        mem_cmd_wr,
    output reg [3:0]  mem_cmd_mask,
    output reg [31:0] mem_cmd_address,
    output reg [31:0] mem_cmd_data,
    input wire        mem_rsp_ready,
    input wire [31:0] mem_rsp_data,
    
    // GPIO interface
    output reg        gpio_cmd_valid,
    input wire        gpio_cmd_ready,
    output reg        gpio_cmd_wr,
    output reg [31:0] gpio_cmd_address,
    output reg [31:0] gpio_cmd_data,
    output reg [3:0]  gpio_cmd_mask,
    input wire        gpio_rsp_ready,
    input wire [31:0] gpio_rsp_data,
    
    // UART interface  
    output reg        uart_cmd_valid,
    input wire        uart_cmd_ready,
    output reg        uart_cmd_wr,
    output reg [31:0] uart_cmd_address,
    output reg [31:0] uart_cmd_data,
    input wire        uart_rsp_ready,
    input wire [31:0] uart_rsp_data
);

    // Address decode
    wire mem_select  = (dBus_cmd_payload_address < 32'h10000000);
    wire gpio_select = (dBus_cmd_payload_address >= 32'h10000000) && (dBus_cmd_payload_address < 32'h10001000);
    wire uart_select = (dBus_cmd_payload_address >= 32'h10001000) && (dBus_cmd_payload_address < 32'h10002000);
    
    // Route commands to appropriate controller
    always @(*) begin
        // Default values
        mem_cmd_valid = 1'b0;
        gpio_cmd_valid = 1'b0;
        uart_cmd_valid = 1'b0;
        
        mem_cmd_wr = dBus_cmd_payload_wr;
        mem_cmd_mask = dBus_cmd_payload_mask;
        mem_cmd_address = dBus_cmd_payload_address;
        mem_cmd_data = dBus_cmd_payload_data;
        
        gpio_cmd_wr = dBus_cmd_payload_wr;
        gpio_cmd_mask = dBus_cmd_payload_mask;
        gpio_cmd_address = dBus_cmd_payload_address;
        gpio_cmd_data = dBus_cmd_payload_data;
        
        uart_cmd_wr = dBus_cmd_payload_wr;
        uart_cmd_address = dBus_cmd_payload_address;
        uart_cmd_data = dBus_cmd_payload_data;
        
        if (dBus_cmd_valid) begin
            if (mem_select) begin
                mem_cmd_valid = 1'b1;
                dBus_cmd_ready = mem_cmd_ready;
                dBus_rsp_ready = mem_rsp_ready;
                dBus_rsp_data = mem_rsp_data;
            end else if (gpio_select) begin
                gpio_cmd_valid = 1'b1;
                dBus_cmd_ready = gpio_cmd_ready;
                dBus_rsp_ready = gpio_rsp_ready;
                dBus_rsp_data = gpio_rsp_data;
            end else if (uart_select) begin
                uart_cmd_valid = 1'b1;
                dBus_cmd_ready = uart_cmd_ready;
                dBus_rsp_ready = uart_rsp_ready;
                dBus_rsp_data = uart_rsp_data;
            end else begin
                dBus_cmd_ready = 1'b1;
                dBus_rsp_ready = 1'b1;
                dBus_rsp_data = 32'h0;
            end
        end else begin
            dBus_cmd_ready = 1'b1;
            dBus_rsp_ready = 1'b1;
            dBus_rsp_data = 32'h0;
        end
    end

endmodule