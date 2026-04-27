`timescale 1ns / 1ps

// TEST CASE 5: Width mismatch via submodule instantiation
//
// A submodule with an 8-bit output port is instantiated and its output
// is connected directly to a 32-bit wire using named port connection.
// iverilog reports a port width mismatch error during elaboration.
//
// Expected: FAIL — connectivity (elaboration error, before synthesis)

// ── Submodule: 8-bit adder ────────────────────────────────────────────────
module narrow_adder (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum   // 8-bit output
);
    assign sum = a + b;
endmodule


// ── Top module: correct SemiCoLab interface ───────────────────────────────
module adder_tile #(
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

    // 32-bit wire connected to an 8-bit submodule port — width mismatch
    wire [REG_WIDTH-1:0] wide_result;  // 32-bit

    narrow_adder u_adder (
        .a   (data_reg_a[7:0]),
        .b   (data_reg_b[7:0]),
        .sum (wide_result)      // ERROR: 8-bit port connected to 32-bit wire
    );

    assign data_reg_c  = wide_result;
    assign csr_out     = {{(CSR_OUT_WIDTH-1){1'b0}}, csr_in[0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
