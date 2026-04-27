`timescale 1ns / 1ps

// TEST CASE 6: Duplicate module definition
// Two modules with the same name in the same RTL file
// iverilog should fail with a redefinition error

module parity_tile #(
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
    assign data_reg_c  = {31'b0, ^data_reg_a};
    assign csr_out     = {{(CSR_OUT_WIDTH-1){1'b0}}, ^data_reg_a};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule


// DUPLICATE — same module name redefined
// iverilog: error: module 'parity_tile' already declared

module parity_tile #(
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
    assign data_reg_c  = {31'b0, ^data_reg_b};
    assign csr_out     = {{(CSR_OUT_WIDTH-1){1'b0}}, ^data_reg_b};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
