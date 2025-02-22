`timescale 1ns / 1ps

module tb_FPU_subtractor;

    // Define input and output signals
    reg [31:0] a, b;
    wire [31:0] result;

    // Instantiate the floating point subtractor
    floating_point_subtract uut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Monitor values in simulation
    initial begin
        $monitor("Time=%0t | a=%h | b=%h | result=%h", $time, a, b, result);

        // Apply test values
        #10 a = 32'h40400000; // 3.0  
            b = 32'h40000000; // 2.0  
            // Expected result: 32'h3F800000 (1.0)
        #10;

        #10 a = 32'hC1200000; // -10.0  
            b = 32'h41200000; // 10.0  
            // Expected result: 32'hc1a00000 (-20.0)
        #10;

        #10 a = 32'h3FC00000; // 1.5  
            b = 32'h3F800000; // 1.0  
            // Expected result: 32'h3F000000 (0.5)
        #10;

        #10 a = 32'h42C80000; // 100.0  
            b = 32'h3EAAAAAB; // 0.3333  
            // Expected result: 32'h42c75556 (~99.6667)
        #10;

        #10 a = 32'hC2480000; // -50.0  
            b = 32'hC1C00000; // -24.0  
            // Expected result: 32'hc1d00000 (-26.0)
        #10;

        #10 a = 32'h3F800000; // 1.0  
            b = 32'h3F800000; // 1.0  
            // Expected result: 32'h00000000 (0.0)
        #10;

        #10 a = 32'hBF800000; // -1.0  
            b = 32'h3F800000; // 1.0  
            // Expected result: 32'hC0000000 (-2.0)
        #10;

        #10 a = 32'h7F800000; // Inf  
            b = 32'h40000000; // 2.0  
            // Expected result: 32'h7F800000 (Inf)
        #10;

        #10 a = 32'hFF800000; // -Inf  
            b = 32'h40000000; // 2.0  
            // Expected result: 32'hFF800000 (-Inf)
        #10;

        #10 a = 32'h7F800000; // Inf  
            b = 32'h7F800000; // Inf  
            // Expected result: 32'hFFC00000 (NaN, Inf - Inf is undefined)
        #10;

        #50;
        $display("Test Completed.");
        $finish;
    end

endmodule
