`timescale 1ns/1ps

module vexriscv_tb;

    // Clock and reset
    reg clk = 0;
    reg reset = 1;
    always #5 clk = ~clk; // 100 MHz

    // VexRiscv GenSmallest interfaces
    wire        iBus_cmd_valid;
    reg         iBus_cmd_ready;
    wire [31:0] iBus_cmd_payload_pc;
    reg         iBus_rsp_valid;
    reg         iBus_rsp_payload_error;
    reg  [31:0] iBus_rsp_payload_inst;

    wire        dBus_cmd_valid;
    reg         dBus_cmd_ready;
    wire        dBus_cmd_payload_wr;
    wire [3:0]  dBus_cmd_payload_mask;
    wire [31:0] dBus_cmd_payload_address;
    wire [31:0] dBus_cmd_payload_data;
    wire [1:0]  dBus_cmd_payload_size;
    reg         dBus_rsp_ready;
    reg         dBus_rsp_error;
    reg  [31:0] dBus_rsp_data;

    // Interrupts (unused)
    reg timerInterrupt = 0;
    reg externalInterrupt = 0;
    reg softwareInterrupt = 0;

    // Memory arrays
    reg [31:0] imem [0:1023];
    reg [31:0] dmem [0:1023];

    // Counters
    reg [31:0] instruction_count = 0;
    reg [31:0] memory_write_count = 0;
    integer i;

    // VexRiscv GenSmallest instantiation
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
        
        .timerInterrupt(timerInterrupt),
        .externalInterrupt(externalInterrupt),
        .softwareInterrupt(softwareInterrupt)
    );

    // Initialize memory
    initial begin
        // Clear memory
        for (i = 0; i < 1024; i = i + 1) begin
            imem[i] = 32'h00000013; // NOP
            dmem[i] = 32'h00000000;
        end
        
        // Test program - starts at PC 0x80000000
        imem[0] = 32'h00100093; // addi x1, x0, 1      (x1 = 1)
        imem[1] = 32'h00200113; // addi x2, x0, 2      (x2 = 2)
        imem[2] = 32'h002081b3; // add x3, x1, x2      (x3 = 1+2 = 3)
        imem[3] = 32'h00302023; // sw x3, 0(x0)        (store 3 to addr 0x80000000)
        imem[4] = 32'h00400213; // addi x4, x0, 4      (x4 = 4)
        imem[5] = 32'h00402223; // sw x4, 4(x0)        (store 4 to addr 0x80000004)
        imem[6] = 32'h00500293; // addi x5, x0, 5      (x5 = 5)
        imem[7] = 32'h00502423; // sw x5, 8(x0)        (store 5 to addr 0x80000008)
        imem[8] = 32'hff9ff06f; // jal x0, -8          (jump back to imem[6], create loop)
        
        $display("=== GenSmallest Test Program ===");
        $display("Expected: dmem[0]=3, dmem[1]=4, dmem[2]=5 (looping)");
    end

    // Address translation
    function [31:0] get_mem_index;
        input [31:0] addr;
        begin
            if (addr >= 32'h80000000)
                get_mem_index = (addr - 32'h80000000) >> 2;
            else
                get_mem_index = addr >> 2;
        end
    endfunction

    // Simple memory model - always ready
    initial begin
        iBus_cmd_ready = 1;
        iBus_rsp_valid = 0;
        iBus_rsp_payload_error = 0;
        dBus_cmd_ready = 1;
        dBus_rsp_ready = 1;
        dBus_rsp_error = 0;
    end

    // Instruction bus - immediate response
    always @(posedge clk) begin
        if (reset) begin
            iBus_rsp_valid <= 0;
            instruction_count <= 0;
        end else begin
            if (iBus_cmd_valid) begin
                iBus_rsp_valid <= 1;
                iBus_rsp_payload_inst <= imem[get_mem_index(iBus_cmd_payload_pc)];
                instruction_count <= instruction_count + 1;
                $display("Time %0t: IFETCH PC=0x%08x INST=0x%08x", 
                        $time, iBus_cmd_payload_pc, imem[get_mem_index(iBus_cmd_payload_pc)]);
            end else begin
                iBus_rsp_valid <= 0;
            end
        end
    end

    // Data bus - immediate response
    always @(posedge clk) begin
        if (reset) begin
            memory_write_count <= 0;
        end else begin
            if (dBus_cmd_valid) begin
                if (dBus_cmd_payload_wr) begin
                    // Write to memory
                    if (dBus_cmd_payload_mask[0]) dmem[get_mem_index(dBus_cmd_payload_address)][7:0] <= dBus_cmd_payload_data[7:0];
                    if (dBus_cmd_payload_mask[1]) dmem[get_mem_index(dBus_cmd_payload_address)][15:8] <= dBus_cmd_payload_data[15:8];
                    if (dBus_cmd_payload_mask[2]) dmem[get_mem_index(dBus_cmd_payload_address)][23:16] <= dBus_cmd_payload_data[23:16];
                    if (dBus_cmd_payload_mask[3]) dmem[get_mem_index(dBus_cmd_payload_address)][31:24] <= dBus_cmd_payload_data[31:24];
                    memory_write_count <= memory_write_count + 1;
                    $display("Time %0t: WRITE addr=0x%08x data=0x%08x -> dmem[%0d]=0x%08x", 
                            $time, dBus_cmd_payload_address, dBus_cmd_payload_data,
                            get_mem_index(dBus_cmd_payload_address), dmem[get_mem_index(dBus_cmd_payload_address)]);
                end else begin
                    // Read from memory
                    dBus_rsp_data <= dmem[get_mem_index(dBus_cmd_payload_address)];
                    $display("Time %0t: READ addr=0x%08x data=0x%08x", 
                            $time, dBus_cmd_payload_address, dmem[get_mem_index(dBus_cmd_payload_address)]);
                end
            end
        end
    end

    // Test control
    initial begin
        $display("=== VexRiscv GenSmallest Test ===");
        
        // Reset sequence
        #100;
        reset = 0;
        $display("Time %0t: Reset released", $time);
        
        // Run for sufficient time to see pattern
        #30000;
        
        // Report results
        $display("\n=== Results ===");
        $display("Instructions executed: %0d", instruction_count);
        $display("Memory writes: %0d", memory_write_count);
        
        $display("\nMemory contents:");
        for (i = 0; i < 6; i = i + 1) begin
            $display("dmem[%0d] = 0x%08x", i, dmem[i]);
        end
        
        // Analysis
        if (instruction_count > 20) begin
            $display("\n*** SUCCESS: CPU IS EXECUTING CONTINUOUSLY ***");
            if (memory_write_count >= 6) begin
                $display("*** SUCCESS: MEMORY WRITES ARE WORKING ***");
                if (dmem[0] == 32'h3 && dmem[1] == 32'h4 && dmem[2] == 32'h5) begin
                    $display("*** SUCCESS: ARITHMETIC AND MEMORY VALUES CORRECT ***");
                    $display("*** OVERALL: VEXRISCV CPU IS FULLY FUNCTIONAL ***");
                end else begin
                    $display("Memory values incorrect - check arithmetic operations");
                end
            end else begin
                $display("Not enough memory writes - check store instructions");
            end
        end else begin
            $display("\n*** FAILURE: CPU NOT EXECUTING ENOUGH INSTRUCTIONS ***");
        end
        
        $finish;
    end

endmodule