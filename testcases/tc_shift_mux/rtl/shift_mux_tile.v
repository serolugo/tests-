`timescale 1ns / 1ps

// TEST CASE tc_shift_mux — Baseline functional
//
// Simple shift multiplexer. Shifts data_reg_a right or data_reg_b left
// by the amount in csr_in[4:1]. Direction selected by csr_in[0].
// Clean design, complete interface, no issues.
//
// Expected: PASS — serves as regression baseline

module shift_mux_tile #(
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

    // csr_in[0]   = direction (0=left shift B, 1=right shift A)
    // csr_in[4:1] = shift amount (0-15)

    wire [4:0] shift_amt = {1'b0, csr_in[4:1]};

    reg [REG_WIDTH-1:0] result;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            result <= 0;
        else if (csr_in[0])
            result <= data_reg_a >> shift_amt;
        else
            result <= data_reg_b << shift_amt;
    end

    assign data_reg_c  = result;
    assign csr_out     = {{(CSR_OUT_WIDTH-5){1'b0}}, csr_in[4:0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
