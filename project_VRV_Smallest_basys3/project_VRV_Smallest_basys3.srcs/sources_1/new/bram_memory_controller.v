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
    
    // Address calculation with 0x80000000 mapping - FIXED!
    wire [31:0] ibus_physical_addr = iBus_cmd_payload_pc - 32'h80000000;
    wire [31:0] dbus_physical_addr = dBus_cmd_payload_address - 32'h80000000;
    
    wire [MEM_ADDR_BITS-1:0] ibus_addr = ibus_physical_addr[MEM_ADDR_BITS+1:2];
    wire [MEM_ADDR_BITS-1:0] dbus_addr = dbus_physical_addr[MEM_ADDR_BITS+1:2];
        
    // Memory bounds checking with 0x80000000 base - FIXED!
    wire ibus_in_range = (ibus_physical_addr < (MEM_SIZE_WORDS * 4));
    wire dbus_in_range = (dbus_physical_addr < (MEM_SIZE_WORDS * 4));
        
    // Pipeline registers for instruction fetch
    reg [31:0] pending_inst_addr;
    reg        pending_inst_valid;
    reg        pending_inst_error;
    
    integer i;
    
    // Initialize memory
    initial begin
        // Clear memory first
        for (i = 0; i < MEM_SIZE_WORDS; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP
        end

        $readmemh("blink.mem", memory);
        $display("mem[0]=%08x mem[1]=%08x mem[2]=%08x", memory[0], memory[1], memory[2]);
    
    
    
    end
    
    // Instruction fetch logic - FIXED
    always @(posedge clk) begin
        if (reset) begin
            iBus_cmd_ready <= 1'b1;
            iBus_rsp_valid <= 1'b0;
            iBus_rsp_payload_error <= 1'b0;
            iBus_rsp_payload_inst <= 32'h00000013;
            pending_inst_valid <= 1'b0;
        end else begin
            // Always ready to accept commands
            iBus_cmd_ready <= 1'b1;
            
            // Handle new instruction fetch requests
            if (iBus_cmd_valid && iBus_cmd_ready) begin
                // Capture the request - response will come next cycle
                pending_inst_valid <= 1'b1;
                if (ibus_in_range) begin
                    pending_inst_addr <= ibus_addr;
                    pending_inst_error <= 1'b0;
                end else begin
                    pending_inst_addr <= 0;
                    pending_inst_error <= 1'b1;
                end
            end else begin
                pending_inst_valid <= 1'b0;
            end
            
            // Provide response (one cycle latency)
            if (pending_inst_valid) begin
                iBus_rsp_valid <= 1'b1;
                iBus_rsp_payload_error <= pending_inst_error;
                if (pending_inst_error) begin
                    iBus_rsp_payload_inst <= 32'h00000013; // NOP for error
                end else begin
                    iBus_rsp_payload_inst <= memory[pending_inst_addr];
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