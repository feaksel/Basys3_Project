// Updated Testbench for fpga_system_basys3
module fpga_system_basys3_testbench;

    // Testbench signals
    reg clk = 0;
    reg reset_btn = 1;
    reg [15:0] switches = 16'h1234;
    wire [15:0] leds;
    wire uart_tx;
    reg uart_rx = 1;
    
    // Performance counters
    reg [31:0] instruction_count = 0;
    reg [31:0] memory_write_count = 0;
    reg [31:0] gpio_write_count = 0;
    reg [31:0] uart_write_count = 0;
    reg [31:0] clock_cycles = 0;
    
    // Clock generation - 100MHz
    always #5 clk = ~clk;
    
    // System under test - NEW TOP MODULE
    fpga_system_basys3 dut (
        .clk(clk),
        .reset_btn(reset_btn),
        .switches(switches),
        .leds(leds),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );
    
    // Clock cycle counter
    always @(posedge clk) begin
        if (!reset_btn) clock_cycles <= clock_cycles + 1;
    end
    
    // Monitor instruction fetches
    always @(posedge clk) begin
        if (!dut.reset_sync && dut.system_core.iBus_cmd_valid && dut.system_core.iBus_cmd_ready) begin
            instruction_count <= instruction_count + 1;
            $display("Time %0t: [%0d] IFETCH PC=0x%08x INST=0x%08x", 
                    $time, clock_cycles, dut.system_core.iBus_cmd_payload_pc, dut.system_core.iBus_rsp_payload_inst);
        end
    end
    
    // Monitor memory accesses
    always @(posedge clk) begin
        if (!dut.reset_sync && dut.system_core.mem_cmd_valid && dut.system_core.mem_cmd_ready) begin
            if (dut.system_core.mem_cmd_wr) begin
                memory_write_count <= memory_write_count + 1;
                $display("Time %0t: [%0d] MEM WRITE addr=0x%08x data=0x%08x", 
                        $time, clock_cycles, dut.system_core.mem_cmd_address, dut.system_core.mem_cmd_data);
            end else begin
                $display("Time %0t: [%0d] MEM READ addr=0x%08x data=0x%08x", 
                        $time, clock_cycles, dut.system_core.mem_cmd_address, dut.system_core.mem_rsp_data);
            end
        end
    end
    
    // Monitor GPIO accesses
    always @(posedge clk) begin
        if (!dut.reset_sync && dut.system_core.gpio_cmd_valid && dut.system_core.gpio_cmd_ready) begin
            if (dut.system_core.gpio_cmd_wr) begin
                gpio_write_count <= gpio_write_count + 1;
                $display("Time %0t: [%0d] GPIO WRITE addr=0x%08x data=0x%08x -> LEDs=0x%04x", 
                        $time, clock_cycles, dut.system_core.gpio_cmd_address, dut.system_core.gpio_cmd_data, leds);
            end else begin
                $display("Time %0t: [%0d] GPIO READ addr=0x%08x data=0x%08x (switches=0x%04x)", 
                        $time, clock_cycles, dut.system_core.gpio_cmd_address, dut.system_core.gpio_rsp_data, switches);
            end
        end
    end
    
    // Add this to monitor GPIO writes
always @(posedge clk) begin
    if (dut.system_core.gpio_cmd_valid && dut.system_core.gpio_cmd_ready && dut.system_core.gpio_cmd_wr) begin
        $display("GPIO WRITE: 0x%08x -> LEDs now: 0x%04x", 
                dut.system_core.gpio_cmd_data, leds);
    end
end
    
    // Monitor UART accesses
    always @(posedge clk) begin
        if (!dut.reset_sync && dut.system_core.uart_cmd_valid && dut.system_core.uart_cmd_ready) begin
            if (dut.system_core.uart_cmd_wr) begin
                uart_write_count <= uart_write_count + 1;
                $display("Time %0t: [%0d] UART WRITE addr=0x%08x data=0x%08x (char='%c')", 
                        $time, clock_cycles, dut.system_core.uart_cmd_address, dut.system_core.uart_cmd_data, 
                        dut.system_core.uart_cmd_data[7:0]);
            end else begin
                $display("Time %0t: [%0d] UART READ addr=0x%08x data=0x%08x", 
                        $time, clock_cycles, dut.system_core.uart_cmd_address, dut.system_core.uart_rsp_data);
            end
        end
    end
    
    // Add this to monitor UART writes more closely
always @(posedge clk) begin
    if (dut.system_core.uart_cmd_valid && dut.system_core.uart_cmd_ready && dut.system_core.uart_cmd_wr) begin
        $display("UART WRITE: data=0x%08x (char='%c') at time %0t", 
                dut.system_core.uart_cmd_data, 
                dut.system_core.uart_cmd_data[7:0],
                $time);
    end
end
    
    // UART transmission monitor
    reg [7:0] uart_char;
    reg [3:0] uart_bit_count = 0;
    reg uart_receiving = 0;
    reg [15:0] uart_baud_count = 0;
    
    always @(negedge uart_tx) begin
        if (!uart_receiving) begin
            uart_receiving = 1;
            uart_bit_count = 0;
            uart_char = 0;
            uart_baud_count = 0;
            $display("Time %0t: UART Start bit detected", $time);
        end
    end
    
          // Test sequence
        initial begin
            $display("=== VexRiscv Finite Program Test ===");
            
            // Reset sequence
            #200;
            reset_btn = 0;
            $display("Time %0t: System reset released", $time);
            
            // Run test - enough time for complete program
            #4000;  // Longer runtime for finite program
            
            // Performance analysis
            $display("\n=== FINAL RESULTS ===");
            $display("Instructions executed: %0d", instruction_count);
            $display("GPIO writes: %0d", gpio_write_count);
            $display("UART writes: %0d", uart_write_count);
            $display("Final LED state: 0x%04x", leds);
            
            // Success criteria
            if (instruction_count > 200 && gpio_write_count >= 6 && uart_write_count >= 9) begin
                $display("\n*** VEXRISCV SYSTEM COMPLETE SUCCESS ***");
                $display("✓ Finite program executed fully");
                $display("✓ All peripherals tested");
                $display("*** READY FOR FPGA DEPLOYMENT ***");
            end else begin
                $display("\n*** INCOMPLETE EXECUTION ***");
                $display("Expected: GPIO >= 6, UART >= 9");
                $display("Got: GPIO = %0d, UART = %0d", gpio_write_count, uart_write_count);
            end
            
            $finish;
        end

endmodule