//==============================================================================
// Enhanced Memory Controller with Proper BRAM Inference (0x80000000 mapping)
//==============================================================================

module bram_memory_controller (
    input wire clk,
    input wire reset,
    
    // VexRiscv Instruction Bus
    input wire        iBus_cmd_valid,
    output reg        iBus_cmd_ready,
    input wire [31:0] iBus_cmd_payload_pc,
    output reg        iBus_rsp_valid,
    output reg        iBus_rsp_payload_error,
    output reg [31:0] iBus_rsp_payload_inst,
    
    // VexRiscv Data Bus  
    input wire        dBus_cmd_valid,
    output reg        dBus_cmd_ready,
    input wire        dBus_cmd_payload_wr,
    input wire [3:0]  dBus_cmd_payload_mask,
    input wire [31:0] dBus_cmd_payload_address,
    input wire [31:0] dBus_cmd_payload_data,
    input wire [1:0]  dBus_cmd_payload_size,
    output reg        dBus_rsp_ready,
    output reg        dBus_rsp_error,
    output reg [31:0] dBus_rsp_data
);

    // Memory parameters
    parameter MEM_SIZE_WORDS = 16384;  // 64KB
    parameter MEM_ADDR_BITS = 14;      // log2(16384)
    
    // Dual-port Block RAM for simultaneous I/D access
    (* ram_style = "block" *) reg [31:0] memory [0:MEM_SIZE_WORDS-1];
    
    // Address calculation with 0x80000000 mapping
    wire [MEM_ADDR_BITS-1:0] ibus_addr =
        (iBus_cmd_payload_pc >= 32'h80000000) ?
            (iBus_cmd_payload_pc - 32'h80000000) >> 2 :
            iBus_cmd_payload_pc[MEM_ADDR_BITS+1:2];

    wire [MEM_ADDR_BITS-1:0] dbus_addr =
        (dBus_cmd_payload_address >= 32'h80000000) ?
            (dBus_cmd_payload_address - 32'h80000000) >> 2 :
            dBus_cmd_payload_address[MEM_ADDR_BITS+1:2];
    
    // Memory bounds checking with 0x80000000 base
    wire ibus_in_range =
        (iBus_cmd_payload_pc >= 32'h80000000) &&
        (iBus_cmd_payload_pc < 32'h80000000 + (MEM_SIZE_WORDS*4));

    wire dbus_in_range =
        (dBus_cmd_payload_address >= 32'h80000000) &&
        (dBus_cmd_payload_address < 32'h80000000 + (MEM_SIZE_WORDS*4));
    
    integer i;
    // Initialize with enhanced test program
    initial begin
        $readmemh("C:/VexRiscv-Project/software/build/blink.hex", memory);
    end
    
    // Instruction fetch logic
    always @(posedge clk) begin
        if (reset) begin
            iBus_cmd_ready <= 1'b1;
            iBus_rsp_valid <= 1'b0;
            iBus_rsp_payload_error <= 1'b0;
            iBus_rsp_payload_inst <= 32'h00000013;
        end else begin
            iBus_cmd_ready <= 1'b1;
            
            if (iBus_cmd_valid) begin
                iBus_rsp_valid <= 1'b1;
                if (ibus_in_range) begin
                    iBus_rsp_payload_inst <= memory[ibus_addr];
                    iBus_rsp_payload_error <= 1'b0;
                end else begin
                    iBus_rsp_payload_inst <= 32'h00000013; // NOP for out-of-bounds
                    iBus_rsp_payload_error <= 1'b1;
                end
            end else begin
                iBus_rsp_valid <= 1'b0;
                iBus_rsp_payload_error <= 1'b0;
            end
        end
    end
    
    // Data access logic with byte-level writes
    always @(posedge clk) begin
        if (reset) begin
            dBus_cmd_ready <= 1'b1;
            dBus_rsp_ready <= 1'b1;
            dBus_rsp_error <= 1'b0;
            dBus_rsp_data <= 32'h0;
        end else begin
            dBus_cmd_ready <= 1'b1;
            dBus_rsp_ready <= 1'b1;
            
            if (dBus_cmd_valid && dbus_in_range) begin
                if (dBus_cmd_payload_wr) begin
                    // Write with byte enables
                    if (dBus_cmd_payload_mask[0]) 
                        memory[dbus_addr][7:0] <= dBus_cmd_payload_data[7:0];
                    if (dBus_cmd_payload_mask[1]) 
                        memory[dbus_addr][15:8] <= dBus_cmd_payload_data[15:8];
                    if (dBus_cmd_payload_mask[2]) 
                        memory[dbus_addr][23:16] <= dBus_cmd_payload_data[23:16];
                    if (dBus_cmd_payload_mask[3]) 
                        memory[dbus_addr][31:24] <= dBus_cmd_payload_data[31:24];
                    dBus_rsp_error <= 1'b0;
                end else begin
                    // Read
                    dBus_rsp_data <= memory[dbus_addr];
                    dBus_rsp_error <= 1'b0;
                end
            end else begin
                dBus_rsp_error <= dBus_cmd_valid; // Error only if access attempted
                dBus_rsp_data <= 32'h0;
            end
        end
    end

endmodule
