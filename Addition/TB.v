`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.02.2025 12:19:56
// Design Name: 
// Module Name: TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module floating_point_add_tb;

    // Inputs
    reg [31:0] a;
    reg [31:0] b;

    // Output
    wire [31:0] result;

    // Instantiate the floating point adder
    floating_point_add uut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Function to convert IEEE 754 to decimal (for debugging)
    function real ieee_to_real;
        input [31:0] ieee;
        reg sign;
        reg [7:0] exponent;
        reg [22:0] mantissa;
        real fraction;
        integer i;
        begin
            sign = ieee[31];
            exponent = ieee[30:23] - 127; // Exponent with bias removed
            mantissa = ieee[22:0];
            fraction = 1.0;
            for (i = 0; i < 23; i = i + 1) begin
                if (mantissa[i]) 
                    fraction = fraction + (2.0 ** -(23 - i));
            end
            ieee_to_real = (sign ? -1.0 : 1.0) * fraction * (2.0 ** exponent);
        end
    endfunction

    // Apply test cases
    initial begin
        $display("Floating Point Addition Testbench");

        // Case 1: Positive + Positive (1.5 + 2.5)
        a = 32'h3FC00000; // 1.5 in IEEE 754
        b = 32'h40200000; // 2.5 in IEEE 754
        #10;
        $display("Test 1: Positive + Positive (1.5 + 2.5) = %h (%.5f)", result, ieee_to_real(result));

        // Case 2: Negative + Negative (-1.5 + -2.5)
        a = 32'hBFC00000; // -1.5 in IEEE 754
        b = 32'hC0200000; // -2.5 in IEEE 754
        #10;
        $display("Test 2: Negative + Negative (-1.5 + -2.5) = %h (%.5f)", result, ieee_to_real(result));

        // Case 3: Zero + Zero (0 + 0)
        a = 32'h00000000; // 0.0 in IEEE 754
        b = 32'h00000000; // 0.0 in IEEE 754
        #10;
        $display("Test 3: Zero + Zero (0 + 0) = %h (%.5f)", result, ieee_to_real(result));

        // Case 4: Positive + Negative (3.0 + -1.5)
        a = 32'h40400000; // 3.0 in IEEE 754
        b = 32'hBFC00000; // -1.5 in IEEE 754
        #10;
        $display("Test 4: Positive + Negative (3.0 + -1.5) = %h (%.5f)", result, ieee_to_real(result));

        // Case 5: Negative + Positive (-2.5 + 4.0)
        a = 32'hC0200000; // -2.5 in IEEE 754
        b = 32'h40800000; // 4.0 in IEEE 754
        #10;
        $display("Test 5: Negative + Positive (-2.5 + 4.0) = %h (%.5f)", result, ieee_to_real(result));

        // Case 6: Different exponent values (1.0 + 100.0)
        a = 32'h3F800000; // 1.0 in IEEE 754
        b = 32'h42C80000; // 100.0 in IEEE 754
        #10;
        $display("Test 6: Different exponent values (1.0 + 100.0) = %h (%.5f)", result, ieee_to_real(result));

        $finish;
    end

endmodule
