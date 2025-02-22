`timescale 1ns / 1ps


module floating_point_add (
    input [31:0] a,       // First floating-point number
    input [31:0] b,       // Second floating-point number
     
    output  [31:0] result
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
    reg [31:0]result_r =0;
     always @(*) begin
    if (exp_a > exp_b) begin
                    aligned_mant_a = mant_a;
                    aligned_mant_b = mant_b >> (exp_a - exp_b);
                    exp_result = exp_a;
                end else begin
                    aligned_mant_a = mant_a >> (exp_b - exp_a);
                    aligned_mant_b = mant_b;
                    exp_result = exp_b;
                end

                // Add or subtract mantissas based on signs
                if (sign_a == sign_b) begin
                    // Same sign: add mantissas
                    mant_sum = aligned_mant_a + aligned_mant_b;
                    sign_result = sign_a;
                end else begin
                    // Different signs: subtract smaller mantissa from larger one
                    if (aligned_mant_a >= aligned_mant_b) begin
                        mant_sum = aligned_mant_a - aligned_mant_b;
                        sign_result = sign_a;
                    end else begin
                        mant_sum = aligned_mant_b - aligned_mant_a;
                        sign_result = sign_b;
                    end
                end

                // Normalize the result
                if (mant_sum[24]) begin
                    // Mantissa overflow, shift right
                    normalized_mant = mant_sum[24:1];
                    exp_result = exp_result + 1;
                end else begin
                    // Normalize left
                    normalized_mant = mant_sum[23:0];
                    while (normalized_mant[23] == 0 && exp_result > 0) begin
                        normalized_mant = normalized_mant << 1;
                        exp_result = exp_result - 1;
                    end
                end

                // Assemble the result
                result_r = {sign_result, exp_result, normalized_mant[22:0]};
            
end
            assign result = result_r;
            
            endmodule
           