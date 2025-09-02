// Complete FPGA System Top Level
module fpga_system_top (
    input wire clk,
    input wire reset,
    
    // Basys3 connections
    input wire [15:0]  switches,
    output wire [15:0] leds,
    output wire        uart_tx,
    input wire         uart_rx
);

    // VexRiscv connections
    wire        iBus_cmd_valid;
    wire        iBus_cmd_ready;
    wire [31:0] iBus_cmd_payload_pc;
    wire        iBus_rsp_valid;
    wire        iBus_rsp_payload_error;
    wire [31:0] iBus_rsp_payload_inst;
    
    wire        dBus_cmd_valid;
    wire        dBus_cmd_ready;
    wire        dBus_cmd_payload_wr;
    wire [3:0]  dBus_cmd_payload_mask;
    wire [31:0] dBus_cmd_payload_address;
    wire [31:0] dBus_cmd_payload_data;
    wire [1:0]  dBus_cmd_payload_size;
    wire        dBus_rsp_ready;
    wire        dBus_rsp_error;
    wire [31:0] dBus_rsp_data;
    
    // Internal buses for peripherals
    wire        mem_cmd_valid;
    wire        mem_cmd_ready;
    wire        mem_cmd_wr;
    wire [3:0]  mem_cmd_mask;
    wire [31:0] mem_cmd_address;
    wire [31:0] mem_cmd_data;
    wire        mem_rsp_ready;
    wire [31:0] mem_rsp_data;
    wire        mem_rsp_error;
    
    wire        gpio_cmd_valid;
    wire        gpio_cmd_ready;
    wire        gpio_cmd_wr;
    wire [31:0] gpio_cmd_address;
    wire [31:0] gpio_cmd_data;
    wire [3:0]  gpio_cmd_mask;
    wire        gpio_rsp_ready;
    wire [31:0] gpio_rsp_data;
    
    wire        uart_cmd_valid;
    wire        uart_cmd_ready;
    wire        uart_cmd_wr;
    wire [31:0] uart_cmd_address;
    wire [31:0] uart_cmd_data;
    wire        uart_rsp_ready;
    wire [31:0] uart_rsp_data;
    
    // VexRiscv GenSmallest CPU
    VexRiscv cpu (
        .clk(clk),
        .reset(reset),
        
        .iBus_cmd_valid(iBus_cmd_valid),
        .iBus_cmd_ready(iBus_cmd_ready),
        .iBus_cmd_payload_pc(iBus_cmd_payload_pc),
        .iBus_rsp_valid(iBus_rsp_valid),
        .iBus_rsp_payload_error(iBus_rsp_payload_error),
        .iBus_rsp_payload_inst(iBus_rsp_payload_inst),
        
        .dBus_cmd_valid(dBus_cmd_valid),
        .dBus_cmd_ready(dBus_cmd_ready),
        .dBus_cmd_payload_wr(dBus_cmd_payload_wr),
        .dBus_cmd_payload_mask(dBus_cmd_payload_mask),
        .dBus_cmd_payload_address(dBus_cmd_payload_address),
        .dBus_cmd_payload_data(dBus_cmd_payload_data),
        .dBus_cmd_payload_size(dBus_cmd_payload_size),
        .dBus_rsp_ready(dBus_rsp_ready),
        .dBus_rsp_error(dBus_rsp_error),
        .dBus_rsp_data(dBus_rsp_data),
        
        .timerInterrupt(1'b0),
        .externalInterrupt(1'b0),
        .softwareInterrupt(1'b0)
    );
    
    // Block RAM Memory Controller
    bram_memory_controller memory_controller (
        .clk(clk),
        .reset(reset),
        
        .iBus_cmd_valid(iBus_cmd_valid),
        .iBus_cmd_ready(iBus_cmd_ready),
        .iBus_cmd_payload_pc(iBus_cmd_payload_pc),
        .iBus_rsp_valid(iBus_rsp_valid),
        .iBus_rsp_payload_error(iBus_rsp_payload_error),
        .iBus_rsp_payload_inst(iBus_rsp_payload_inst),
        
        .dBus_cmd_valid(mem_cmd_valid),
        .dBus_cmd_ready(mem_cmd_ready),
        .dBus_cmd_payload_wr(mem_cmd_wr),
        .dBus_cmd_payload_mask(mem_cmd_mask),
        .dBus_cmd_payload_address(mem_cmd_address),
        .dBus_cmd_payload_data(mem_cmd_data),
        .dBus_cmd_payload_size(2'b10), // Always 32-bit
        .dBus_rsp_ready(mem_rsp_ready),
        .dBus_rsp_error(mem_rsp_error),
        .dBus_rsp_data(mem_rsp_data)
    );
    
    // Address Decoder
    address_decoder decoder (
        .clk(clk),
        .reset(reset),
        
        .dBus_cmd_valid(dBus_cmd_valid),
        .dBus_cmd_ready(dBus_cmd_ready),
        .dBus_cmd_payload_wr(dBus_cmd_payload_wr),
        .dBus_cmd_payload_mask(dBus_cmd_payload_mask),
        .dBus_cmd_payload_address(dBus_cmd_payload_address),
        .dBus_cmd_payload_data(dBus_cmd_payload_data),
        .dBus_rsp_ready(dBus_rsp_ready),
        .dBus_rsp_data(dBus_rsp_data),
        
        .mem_cmd_valid(mem_cmd_valid),
        .mem_cmd_ready(mem_cmd_ready),
        .mem_cmd_wr(mem_cmd_wr),
        .mem_cmd_mask(mem_cmd_mask),
        .mem_cmd_address(mem_cmd_address),
        .mem_cmd_data(mem_cmd_data),
        .mem_rsp_ready(mem_rsp_ready),
        .mem_rsp_data(mem_rsp_data),
        
        .gpio_cmd_valid(gpio_cmd_valid),
        .gpio_cmd_ready(gpio_cmd_ready),
        .gpio_cmd_wr(gpio_cmd_wr),
        .gpio_cmd_address(gpio_cmd_address),
        .gpio_cmd_data(gpio_cmd_data),
        .gpio_cmd_mask(gpio_cmd_mask),
        .gpio_rsp_ready(gpio_rsp_ready),
        .gpio_rsp_data(gpio_rsp_data),
        
        .uart_cmd_valid(uart_cmd_valid),
        .uart_cmd_ready(uart_cmd_ready),
        .uart_cmd_wr(uart_cmd_wr),
        .uart_cmd_address(uart_cmd_address),
        .uart_cmd_data(uart_cmd_data),
        .uart_rsp_ready(uart_rsp_ready),
        .uart_rsp_data(uart_rsp_data)
    );
    
    // GPIO Controller
    gpio_controller gpio (
        .clk(clk),
        .reset(reset),
        
        .cmd_valid(gpio_cmd_valid),
        .cmd_ready(gpio_cmd_ready),
        .cmd_wr(gpio_cmd_wr),
        .cmd_address(gpio_cmd_address),
        .cmd_data(gpio_cmd_data),
        .cmd_mask(gpio_cmd_mask),
        .rsp_ready(gpio_rsp_ready),
        .rsp_data(gpio_rsp_data),
        
        .switches(switches),
        .leds(leds)
    );
    
    // UART Controller
    uart_controller uart (
        .clk(clk),
        .reset(reset),
        
        .cmd_valid(uart_cmd_valid),
        .cmd_ready(uart_cmd_ready),
        .cmd_wr(uart_cmd_wr),
        .cmd_address(uart_cmd_address),
        .cmd_data(uart_cmd_data),
        .rsp_ready(uart_rsp_ready),
        .rsp_data(uart_rsp_data),
        
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

endmodule