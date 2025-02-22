`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.02.2025 12:56:32
// Design Name: 
// Module Name: FPU_multiplier
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


`timescale 1ns / 1ps


module floating_point_arithmetic (
    input [31:0] a,       // First floating-point number
    input [31:0] b,       // Second floating-point number
   
    output[31:0] result
);

    // Split input floating-point numbers into sign, exponent, and mantissa
    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    wire [23:0] mant_a = (exp_a != 8'd0) ? {1'b1, a[22:0]} : {1'b0, a[22:0]}; // Add implicit 1 for normalized numbers
    wire [23:0] mant_b = (exp_b != 8'd0) ? {1'b1, b[22:0]} : {1'b0, b[22:0]}; // Add implicit 1 for normalized numbers
    reg inverted_sign_b = 0;
    reg [24:0] mant_diff;
    // Temporary variables
    reg [23:0] aligned_mant_a;
    reg [23:0] aligned_mant_b;
    reg [24:0] mant_sum;  // Extra bit for carry
    reg [47:0] mant_mult; // Product of mantissas (24-bit * 24-bit = 48-bit)
    reg [7:0] exp_result;
    reg [23:0] normalized_mant;
    reg sign_result;
    reg guard_bit, round_bit, sticky; // Rounding bits
    reg [8:0] exp_temp;
    reg [47:0] mant_div; // Extended mantissa for division to increase precision
     reg [31:0]result_r;
    always @(*) begin


         // Handle special cases
                sign_result = sign_a ^ sign_b; // Result sign is XOR of input signs

            // Check for special cases such as zero and infinity
            if ((exp_a == 0 && a[22:0] == 0) || (exp_b == 0 && b[22:0] == 0)) begin
                // Both inputs are zero
                result_r = {sign_result, 31'b0};
            end else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
                // At least one input is infinity
                result_r = {sign_result, 8'hFF, 23'b0};
            end else begin
                // Normal multiplication of mantissas
                mant_mult = mant_a * mant_b;

                // Compute the new exponent, adjust for the bias
                exp_temp = exp_a + exp_b - 127;

                // Normalize the result
                if (mant_mult[47]) begin
                    normalized_mant = mant_mult[47:24]; // Normalize right shift by 24 bits
                    exp_temp = exp_temp + 1; // Adjust exponent due to normalization
                end else begin
                    normalized_mant = mant_mult[46:23]; // Normalize right shift by 23 bits
                end

                // Check for exponent overflow or underflow
                if (exp_temp >= 255) begin
                    // Overflow, set result to infinity
                    result_r = {sign_result, 8'hFF, 23'b0};
                end else if (exp_temp <= 0) begin
                    // Underflow, set result to zero
                    result_r = {sign_result, 8'b0, 23'b0};
                end else begin
                    // Valid exponent, pack the result into IEEE 754 format
                    result_r = {sign_result, exp_temp[7:0], normalized_mant[22:0]};
                end
            end
        end 
        
        assign result= result_r;
        
        endmodule