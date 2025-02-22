`timescale 1ns / 1ps


module floating_point_arithmetic (
    input [31:0] a,       // First floating-point number
    input [31:0] b,       // Second floating-point number
    input [1:0] op_code,  // Operation code: 2'b00 = Add
    output reg [31:0] result
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
     
    always @(*) begin
        case (op_code)
            // **Addition**
            2'b00: begin
                // Align the exponents
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
                result = {sign_result, exp_result, normalized_mant[22:0]};
            end
           
           
           2'b01: begin
                // Invert the sign of `b` to perform subtraction (a - b = a + (-b))
                inverted_sign_b = ~sign_b;

                // Align the exponents
                if (exp_a > exp_b) begin
                    aligned_mant_a = mant_a;
                    aligned_mant_b = mant_b >> (exp_a - exp_b);
                    exp_result = exp_a;
                end else begin
                    aligned_mant_a = mant_a >> (exp_b - exp_a);
                    aligned_mant_b = mant_b;
                    exp_result = exp_b;
                end

                // Add or subtract mantissas based on the effective signs
                if (sign_a == inverted_sign_b) begin
                    // Same sign after inversion: add mantissas
                    mant_diff = aligned_mant_a + aligned_mant_b;
                    sign_result = sign_a;
                end else begin
                    // Different signs: subtract smaller mantissa from larger one
                    if (aligned_mant_a >= aligned_mant_b) begin
                        mant_diff = aligned_mant_a - aligned_mant_b;
                        sign_result = sign_a;
                    end else begin
                        mant_diff = aligned_mant_b - aligned_mant_a;
                        sign_result = inverted_sign_b;
                    end
                end

                // Normalize the result
                if (mant_diff[24]) begin
                    // Mantissa overflow, shift right
                    normalized_mant = mant_diff[24:1];
                    exp_result = exp_result + 1;
                end else begin
                    // Normalize left
                    normalized_mant = mant_diff[23:0];
                    while (normalized_mant[23] == 0 && exp_result > 0) begin
                        normalized_mant = normalized_mant << 1;
                        exp_result = exp_result - 1;
                    end
                end

                // Assemble the result
                result = {sign_result, exp_result, normalized_mant[22:0]};
            end
 
            // **Multiplication**
               2'b10: begin 
                // Handle special cases
                sign_result = sign_a ^ sign_b; // Result sign is XOR of input signs

            // Check for special cases such as zero and infinity
            if ((exp_a == 0 && a[22:0] == 0) || (exp_b == 0 && b[22:0] == 0)) begin
                // Both inputs are zero
                result = {sign_result, 31'b0};
            end else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
                // At least one input is infinity
                result = {sign_result, 8'hFF, 23'b0};
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
                    result = {sign_result, 8'hFF, 23'b0};
                end else if (exp_temp <= 0) begin
                    // Underflow, set result to zero
                    result = {sign_result, 8'b0, 23'b0};
                end else begin
                    // Valid exponent, pack the result into IEEE 754 format
                    result = {sign_result, exp_temp[7:0], normalized_mant[22:0]};
                end
            end
        end 
        
        2'b11: begin  // Division operation
                sign_result = sign_a ^ sign_b;  // Determine the sign of the result

            // Handle special cases
            if (b == 32'b0) begin
                // Division by zero (return infinity)
                result = {sign_result, 8'hFF, 23'b0};
            end else if (exp_b == 8'hFF) begin
                // Dividing by infinity results in zero
                result = {sign_result, 31'b0};
            end else if (exp_a == 8'hFF) begin
                // Infinity divided by any finite number results in infinity
                result = {sign_result, 8'hFF, 23'b0};
            end else begin
                // Normal division of mantissas
                mant_div = ({24'b0, mant_a} << 23) / mant_b; // Perform division with shifted dividend for precision

                // Calculate new exponent
                exp_result = exp_a - exp_b + 127; // Adjust for the exponent bias

                // Normalize the result
                while (mant_div[47] == 0 && exp_result > 0) begin
                    mant_div = mant_div << 1; // Normalize the mantissa to start with '1'
                    exp_result = exp_result - 1;
                end

                normalized_mant = mant_div[46:24]; // Get the top 23 bits as normalized mantissa

                if (exp_result >= 255) begin
                    // Overflow condition
                    result = {sign_result, 8'hFF, 23'b0};
                end else if (exp_result <= 0) begin
                    // Underflow condition
                    result = {sign_result, 31'b0};
                end else begin
                    // Proper normalized result
                    result = {sign_result, exp_result[7:0], normalized_mant};
                end
            end
        end
            default: result = 32'b0; // Default case
        endcase
    end
endmodule
