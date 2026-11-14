`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 07:44:22 AM
// Design Name: 
// Module Name: FP16Multiplier
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

module FP16Multiplier(
    input logic [15:0] A, B,
    output logic [15:0] X
);

    logic Asign, Bsign;
    logic [4:0] Aexp, Bexp;
    integer Xexp;
    logic [21:0] pp;
    logic [21:0] P;
    logic [10:0] Asig, Bsig;
    logic [9:0] F;
    logic gb, rb, sb, rup;
    logic [11:0] sig;
    integer i, j;

    always_comb begin
        Asign = A[15];
        Bsign = B[15];
        Aexp = A[14:10];
        Bexp = B[14:10];
        Asig = {1'b1, A[9:0]};
        Bsig = {1'b1, B[9:0]};

        pp = 22'b0;
        P = 22'b0;
        F = 10'b0;
        sig = 12'b0;
        Xexp = 0;
        gb = 1'b0;
        rb = 1'b0;
        sb = 1'b0;
        rup = 1'b0;
        X = 16'b0;

        // handle zero inputs
        if (A[14:0] == 0 || B[14:0] == 0) begin
            X[15] = Asign ^ Bsign;
        end
        else begin
            // generate and add partial products
            for (j = 0; j < 11; j = j + 1) begin
                pp = 22'b0;
                for (i = 0; i < 11; i = i + 1) begin
                    pp[i+j] = Asig[i] & Bsig[j];
                end
                P = P + pp;
            end

            // calculate the exponent
                Xexp = Aexp + Bexp - 15;

            // normalize the product
            if (P[21] == 1'b1) begin
                sig = {1'b0, P[21:11]};
                gb = P[10];
                rb = P[9];
                sb = |P[8:0];
                Xexp = Xexp + 1;
            end
            else begin
                sig = {1'b0, P[20:10]};
                gb = P[9];
                rb = P[8];
                sb = |P[7:0];
            end

            // round to nearest even
            rup = gb && (rb || sb || sig[0]);
            sig = sig + rup;

            // handle rounding overflow
            if (sig[11] == 1'b1) begin
                sig = 12'b010000000000; 
                Xexp = Xexp + 1;
            end

            // pack the result
            X[15] = Asign ^ Bsign;
            F = sig[9:0];

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

endmodule