`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2026 08:17:11 PM
// Design Name: 
// Module Name: mac
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


module mac (
    input  logic [15:0] A,
    input  logic [15:0] B,
    input  logic [15:0] C,
    output logic [15:0] X
);
    logic [15:0] product;

    FP16Multiplier mult (
        .A(A),
        .B(B),
        .X(product)
    );

    FP16Adder adder (
        .A(product),
        .B(C),
        .X(X)
    );
endmodule
