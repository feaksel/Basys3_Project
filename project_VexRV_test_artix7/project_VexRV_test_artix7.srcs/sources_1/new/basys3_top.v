module basys3_top(
    input wire clk,           // 100MHz Basys3 clock
    input wire btnC,          // Center button (reset)
    output wire [15:0] led,   // 16 LEDs
    input wire [15:0] sw,     // 16 switches
    
    // 7-segment display (unused for now)
    output wire [6:0] seg,
    output wire [3:0] an,
    
    // UART (for debugging)
    input wire RsRx,
    output wire RsTx
);

    // Clock and reset
    wire reset_n = ~btnC;  // Active low reset for VexRiscv
    
    // VexRiscv bus signals (Wishbone)
    wire [31:0] iBusWishbone_ADR;
    wire [31:0] iBusWishbone_DAT_MISO;
    wire [31:0] iBusWishbone_DAT_MOSI;
    wire [3:0]  iBusWishbone_SEL;
    wire        iBusWishbone_CYC;
    wire        iBusWishbone_STB;
    wire        iBusWishbone_ACK;
    wire        iBusWishbone_WE;
    wire [2:0]  iBusWishbone_CTI;
    wire [1:0]  iBusWishbone_BTE;
    wire        iBusWishbone_ERR;
    
    wire [31:0] dBusWishbone_ADR;
    wire [31:0] dBusWishbone_DAT_MISO;
    wire [31:0] dBusWishbone_DAT_MOSI;
    wire [3:0]  dBusWishbone_SEL;
    wire        dBusWishbone_CYC;
    wire        dBusWishbone_STB;
    wire        dBusWishbone_ACK;
    wire        dBusWishbone_WE;
    wire [2:0]  dBusWishbone_CTI;
    wire [1:0]  dBusWishbone_BTE;
    wire        dBusWishbone_ERR;
    
    // Interrupt signals (tied off for basic implementation)
    wire timerInterrupt = 1'b0;
    wire externalInterrupt = 1'b0;
    wire softwareInterrupt = 1'b0;
    
    // Debug signals (tied off - no debug for now)
    wire DebugPlugin_debugClkDomain_external_clk = clk;
    wire DebugPlugin_debugClkDomain_external_reset = btnC;
    wire [31:0] DebugPlugin_bus_cmd_payload_address = 32'h0;
    wire        DebugPlugin_bus_cmd_payload_wr = 1'b0;
    wire [31:0] DebugPlugin_bus_cmd_payload_data = 32'h0;
    wire        DebugPlugin_bus_cmd_valid = 1'b0;
    wire        DebugPlugin_bus_cmd_ready;
    wire [31:0] DebugPlugin_bus_rsp_data;
    wire        DebugPlugin_resetOut;
    
    // VexRiscv processor instance
    VexRiscv cpu (
        .clk(clk),
        .reset(~reset_n),  // VexRiscv expects active high reset
        
        // Instruction bus (Wishbone)
        .iBusWishbone_ADR(iBusWishbone_ADR),
        .iBusWishbone_DAT_MISO(iBusWishbone_DAT_MISO),
        .iBusWishbone_DAT_MOSI(iBusWishbone_DAT_MOSI),
        .iBusWishbone_SEL(iBusWishbone_SEL),
        .iBusWishbone_CYC(iBusWishbone_CYC),
        .iBusWishbone_STB(iBusWishbone_STB),
        .iBusWishbone_ACK(iBusWishbone_ACK),
        .iBusWishbone_WE(iBusWishbone_WE),
        .iBusWishbone_CTI(iBusWishbone_CTI),
        .iBusWishbone_BTE(iBusWishbone_BTE),
        .iBusWishbone_ERR(iBusWishbone_ERR),
        
        // Data bus (Wishbone)
        .dBusWishbone_ADR(dBusWishbone_ADR),
        .dBusWishbone_DAT_MISO(dBusWishbone_DAT_MISO),
        .dBusWishbone_DAT_MOSI(dBusWishbone_DAT_MOSI),
        .dBusWishbone_SEL(dBusWishbone_SEL),
        .dBusWishbone_CYC(dBusWishbone_CYC),
        .dBusWishbone_STB(dBusWishbone_STB),
        .dBusWishbone_ACK(dBusWishbone_ACK),
        .dBusWishbone_WE(dBusWishbone_WE),
        .dBusWishbone_CTI(dBusWishbone_CTI),
        .dBusWishbone_BTE(dBusWishbone_BTE),
        .dBusWishbone_ERR(dBusWishbone_ERR),
        
        // Interrupts
        .timerInterrupt(timerInterrupt),
        .externalInterrupt(externalInterrupt),
        .softwareInterrupt(softwareInterrupt),
        
        // Debug interface (minimal connection)
        .DebugPlugin_debugClkDomain_external_clk(DebugPlugin_debugClkDomain_external_clk),
        .DebugPlugin_debugClkDomain_external_reset(DebugPlugin_debugClkDomain_external_reset),
        .DebugPlugin_bus_cmd_payload_address(DebugPlugin_bus_cmd_payload_address),
        .DebugPlugin_bus_cmd_payload_wr(DebugPlugin_bus_cmd_payload_wr),
        .DebugPlugin_bus_cmd_payload_data(DebugPlugin_bus_cmd_payload_data),
        .DebugPlugin_bus_cmd_valid(DebugPlugin_bus_cmd_valid),
        .DebugPlugin_bus_cmd_ready(DebugPlugin_bus_cmd_ready),
        .DebugPlugin_bus_rsp_data(DebugPlugin_bus_rsp_data),
        .DebugPlugin_resetOut(DebugPlugin_resetOut)
    );
    
    // Simple memory subsystem (64KB Block RAM)
    memory_subsystem mem_sys (
        .clk(clk),
        .reset(~reset_n),
        
        // Connect both instruction and data buses to same memory
        // Instruction bus
        .iBus_ADR(iBusWishbone_ADR),
        .iBus_DAT_MISO(iBusWishbone_DAT_MISO),
        .iBus_DAT_MOSI(iBusWishbone_DAT_MOSI),
        .iBus_SEL(iBusWishbone_SEL),
        .iBus_CYC(iBusWishbone_CYC),
        .iBus_STB(iBusWishbone_STB),
        .iBus_ACK(iBusWishbone_ACK),
        .iBus_WE(iBusWishbone_WE),
        .iBus_ERR(iBusWishbone_ERR),
        
        // Data bus
        .dBus_ADR(dBusWishbone_ADR),
        .dBus_DAT_MISO(dBusWishbone_DAT_MISO),
        .dBus_DAT_MOSI(dBusWishbone_DAT_MOSI),
        .dBus_SEL(dBusWishbone_SEL),
        .dBus_CYC(dBusWishbone_CYC),
        .dBus_STB(dBusWishbone_STB),
        .dBus_ACK(dBusWishbone_ACK),
        .dBus_WE(dBusWishbone_WE),
        .dBus_ERR(dBusWishbone_ERR)
    );
    
    // Simple GPIO - echo switches to LEDs for testing
    assign led = sw;
    
    // Unused outputs
    assign seg = 7'h7F;    // Turn off 7-segment
    assign an = 4'hF;      // Turn off all digits  
    assign RsTx = 1'b1;    // UART TX idle high
    
endmodule