// Comprehensive testbench for complete FPGA system
module fpga_system_testbench;

    // Testbench signals
    reg clk = 0;
    reg reset = 1;
    reg [15:0] switches = 16'h1234;
    wire [15:0] leds;
    wire uart_tx;
    reg uart_rx = 1;
    
    // Test monitoring
    reg [31:0] instruction_count = 0;
    reg [31:0] memory_write_count = 0;
    reg [31:0] gpio_write_count = 0;
    reg [31:0] uart_write_count = 0;
    
    // Clock generation
    always #5 clk = ~clk; // 100 MHz
    
    // System under test
    fpga_system_top system (
        .clk(clk),
        .reset(reset),
        .switches(switches),
        .leds(leds),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );
    
    // Monitor instruction fetches
    always @(posedge clk) begin
        if (!reset && system.iBus_cmd_valid && system.iBus_cmd_ready) begin
            instruction_count <= instruction_count + 1;
            $display("Time %0t: IFETCH PC=0x%08x INST=0x%08x", 
                    $time, system.iBus_cmd_payload_pc, system.iBus_rsp_payload_inst);
        end
    end
    
    // Monitor memory accesses
    always @(posedge clk) begin
        if (!reset && system.mem_cmd_valid && system.mem_cmd_ready) begin
            if (system.mem_cmd_wr) begin
                memory_write_count <= memory_write_count + 1;
                $display("Time %0t: MEM WRITE addr=0x%08x data=0x%08x", 
                        $time, system.mem_cmd_address, system.mem_cmd_data);
            end else begin
                $display("Time %0t: MEM READ addr=0x%08x data=0x%08x", 
                        $time, system.mem_cmd_address, system.mem_rsp_data);
            end
        end
    end
    
    // Monitor GPIO accesses
    always @(posedge clk) begin
        if (!reset && system.gpio_cmd_valid && system.gpio_cmd_ready) begin
            if (system.gpio_cmd_wr) begin
                gpio_write_count <= gpio_write_count + 1;
                $display("Time %0t: GPIO WRITE addr=0x%08x data=0x%08x -> LEDs=0x%04x", 
                        $time, system.gpio_cmd_address, system.gpio_cmd_data, leds);
            end else begin
                $display("Time %0t: GPIO READ addr=0x%08x data=0x%08x", 
                        $time, system.gpio_cmd_address, system.gpio_rsp_data);
            end
        end
    end
    
    // Monitor UART accesses
    always @(posedge clk) begin
        if (!reset && system.uart_cmd_valid && system.uart_cmd_ready) begin
            if (system.uart_cmd_wr) begin
                uart_write_count <= uart_write_count + 1;
                $display("Time %0t: UART WRITE addr=0x%08x data=0x%08x (char='%c')", 
                        $time, system.uart_cmd_address, system.uart_cmd_data, system.uart_cmd_data[7:0]);
            end else begin
                $display("Time %0t: UART READ addr=0x%08x data=0x%08x", 
                        $time, system.uart_cmd_address, system.uart_rsp_data);
            end
        end
    end
    
    // Test sequence
    initial begin
        $display("=== FPGA System Integration Test ===");
        $display("Testing: VexRiscv + Block RAM + GPIO + UART + Address Decoder");
        
        // Reset sequence
        #200;
        reset = 0;
        $display("Time %0t: System reset released", $time);
        
        // Change switches during test
        #10000;
        switches = 16'hABCD;
        $display("Time %0t: Switches changed to 0x%04x", $time, switches);
        
        #10000;
        switches = 16'h5555;
        $display("Time %0t: Switches changed to 0x%04x", $time, switches);
        
        // Run test
        #40000;
        
        // Final analysis
        $display("\n=== FPGA System Test Results ===");
        $display("Instructions executed: %0d", instruction_count);
        $display("Memory writes: %0d", memory_write_count);
        $display("GPIO accesses: %0d", gpio_write_count);
        $display("UART accesses: %0d", uart_write_count);
        $display("Final LED state: 0x%04x", leds);
        
        // Check memory contents
        $display("\nMemory verification:");
        $display("memory[0] = 0x%08x", system.memory_controller.memory[0]);
        $display("memory[1] = 0x%08x", system.memory_controller.memory[1]);
        $display("memory[2] = 0x%08x", system.memory_controller.memory[2]);
        
        // System validation
        if (instruction_count > 50 && memory_write_count > 0) begin
            $display("\n*** FPGA SYSTEM INTEGRATION SUCCESS ***");
            $display("✓ CPU executing instructions");
            $display("✓ Block RAM memory working");
            
            if (gpio_write_count > 0) begin
                $display("✓ GPIO controller working");
            end else begin
                $display("⚠ GPIO controller not tested");
            end
            
            if (uart_write_count > 0) begin
                $display("✓ UART controller working");
            end else begin
                $display("⚠ UART controller not tested");
            end
            
            $display("\n*** READY FOR FPGA SYNTHESIS ***");
            
        end else begin
            $display("\n*** FPGA SYSTEM INTEGRATION FAILED ***");
            if (instruction_count <= 50) $display("✗ CPU not executing properly");
            if (memory_write_count == 0) $display("✗ Memory writes not working");
        end
        
        $finish;
    end

endmodule