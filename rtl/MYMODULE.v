`timescale 1ns / 1ps

// TEST CASE 9: Non-standard naming conventions
//
// Internal signals use ambiguous or non-standard names:
// - Clock not prefixed with clk_
// - Reset not prefixed with rst_ or arst_
// - Generic signal names (x, y, z, tmp, foo)
// - Module name does not follow SemiCoLab tile naming convention
//
// Interface is complete and correct — all 9 SemiCoLab ports present.
// Neither iverilog nor Yosys validate naming conventions.
//
// Expected: PASS (gap — no naming lint implemented)

module MYMODULE #(                   // non-standard: uppercase, no _tile suffix
    parameter REG_WIDTH     = 32,
    parameter CSR_IN_WIDTH  = 16,
    parameter CSR_OUT_WIDTH = 16
)(
    input  wire                      clk,
    input  wire                      arst_n,
    input  wire [CSR_IN_WIDTH-1:0]   csr_in,
    input  wire [REG_WIDTH-1:0]      data_reg_a,
    input  wire [REG_WIDTH-1:0]      data_reg_b,
    output wire [REG_WIDTH-1:0]      data_reg_c,
    output wire [CSR_OUT_WIDTH-1:0]  csr_out,
    output wire                      csr_in_re,
    output wire                      csr_out_we
);

    // Non-standard internal naming
    wire       CLK_SIG  = clk;       // uppercase, redundant alias
    wire       RST      = arst_n;    // ambiguous reset name
    wire [REG_WIDTH-1:0] x;          // single-letter signal name
    wire [REG_WIDTH-1:0] y;          // single-letter signal name
    wire [REG_WIDTH-1:0] tmp;        // generic temporary name
    wire [REG_WIDTH-1:0] foo;        // meaningless name

    assign x   = data_reg_a + data_reg_b;
    assign y   = data_reg_a & data_reg_b;
    assign tmp = csr_in[0] ? x : y;
    assign foo = tmp ^ data_reg_a;

    assign data_reg_c  = foo;
    assign csr_out     = {{(CSR_OUT_WIDTH-2){1'b0}}, csr_in[1:0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
