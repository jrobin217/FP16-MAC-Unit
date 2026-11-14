`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 10:30:55 PM
// Design Name: 
// Module Name: FP16Adder
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

module FP16Adder(
    input logic [15:0] A, B,
    output logic [15:0] X
);

    logic Asign, Bsign, result_sign;
    logic [4:0] Aexp, Bexp;
    logic [9:0] Af, Bf;
    logic [10:0] Asig, Bsig;
    logic [13:0] large_ext, small_ext, small_aligned;
    logic [14:0] add_large, add_small, sum_ext;
    logic [15:0] carry;
    logic [13:0] result_ext;
    logic [9:0] F;
    logic [11:0] sig;
    logic gb, rb, sb, rup;
    logic sticky_align;
    integer Xexp, shift_amt, i;

    always_comb begin
        Asign = A[15];
        Bsign = B[15];
        Aexp = A[14:10];
        Bexp = B[14:10];
        Af = A[9:0];
        Bf = B[9:0];
        Asig = {1'b1, Af};
        Bsig = {1'b1, Bf};

        large_ext = 14'b0;
        small_ext = 14'b0;
        small_aligned = 14'b0;
        add_large = 15'b0;
        add_small = 15'b0;
        sum_ext = 15'b0;
        carry = 16'b0;
        result_ext = 14'b0;
        F = 10'b0;
        sig = 12'b0;
        gb = 1'b0;
        rb = 1'b0;
        sb = 1'b0;
        rup = 1'b0;
        sticky_align = 1'b0;
        result_sign = 1'b0;
        Xexp = 0;
        shift_amt = 0;
        X = 16'b0;

        // handle zero inputs
        if (A[14:0] == 0) begin
            X = B;
        end
        else if (B[14:0] == 0) begin
            X = A;
        end
        else begin
            // select the larger magnitude
            if ((Aexp > Bexp) || ((Aexp == Bexp) && (Af >= Bf))) begin
                large_ext = {Asig, 3'b000};
                small_ext = {Bsig, 3'b000};
                Xexp = Aexp;
                shift_amt = Aexp - Bexp;
                result_sign = Asign;
            end
            else begin
                large_ext = {Bsig, 3'b000};
                small_ext = {Asig, 3'b000};
                Xexp = Bexp;
                shift_amt = Bexp - Aexp;
                result_sign = Bsign;
            end

            // align the smaller significand
            small_aligned = small_ext >> shift_amt;

            // collect discarded bits
            for (i = 0; i < 14; i = i + 1) begin
                if (i < shift_amt) begin
                    sticky_align = sticky_align | small_ext[i];
                end
            end
            small_aligned[0] = small_aligned[0] | sticky_align;

            // prepare the rca inputs
            add_large = {1'b0, large_ext};
            if (Asign != Bsign) begin
                add_small = {1'b0, ~small_aligned};
                carry[0] = 1'b1;
            end
            else begin
                add_small = {1'b0, small_aligned};
                carry[0] = 1'b0;
            end

            // ripple carry adder
            for (i = 0; i < 15; i = i + 1) begin
                sum_ext[i] = add_large[i] ^ add_small[i] ^ carry[i];
                carry[i+1] = (add_large[i] & add_small[i]) |
                             (add_large[i] & carry[i]) |
                             (add_small[i] & carry[i]);
            end

            // normalize the result
            if (Asign == Bsign && sum_ext[14] == 1'b1) begin
                result_ext = sum_ext[14:1];
                result_ext[0] = result_ext[0] | sum_ext[0];
                Xexp = Xexp + 1;
            end
            else begin
                result_ext = sum_ext[13:0];
                if (Asign != Bsign) begin
                    if (result_ext == 0) begin
                        X = 16'b0;
                    end
                    else begin
                        for (i = 0; i < 14; i = i + 1) begin
                            if (result_ext[13] == 1'b0 && Xexp > 1) begin
                                result_ext = result_ext << 1;
                                Xexp = Xexp - 1;
                            end
                        end
                    end
                end
            end

            // round and pack the result
            if (result_ext == 0) begin
                X = 16'b0;
            end
            else begin
                gb = result_ext[2];
                rb = result_ext[1];
                sb = result_ext[0];
                sig = {1'b0, result_ext[13:3]};
                rup = gb && (rb || sb || sig[0]);
                sig = sig + rup;

                // handle rounding overflow
                if (sig[11] == 1'b1) begin
                    sig = 12'b010000000000; 
                    Xexp = Xexp + 1;
                end

                F = sig[9:0];
                X[15] = result_sign;

                if (Xexp <= 0) begin
                    X[14:0] = 15'b0;
                end
                else if (Xexp >= 31) begin
                    X[14:10] = 5'b11110;
                    X[9:0] = 10'b1111111111;
                end
                else begin
                    X[14:10] = Xexp[4:0];
                    X[9:0] = F;
                end
            end
        end
    end

endmodule