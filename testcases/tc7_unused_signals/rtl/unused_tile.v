`timescale 1ns / 1ps

// TEST CASE 7: Unused signals and undriven outputs
//
// Declares internal signals that are never used and has a registered
// output that is never assigned after reset.
// Neither iverilog nor Yosys fail on this — documents a lint gap.
//
// Expected: PASS (gap — no lint stage implemented)

module unused_tile #(
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

    // Declared but never used — lint gap
    wire [REG_WIDTH-1:0] unused_wire;
    reg  [REG_WIDTH-1:0] unused_reg;
    wire [7:0]           dead_signal = 8'hAB;

    // data_reg_b is never read — lint gap
    reg [REG_WIDTH-1:0] result;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            result <= 0;
        else if (csr_in[0])
            result <= data_reg_a;
        // data_reg_b intentionally ignored
    end

    assign data_reg_c  = result;
    assign csr_out     = {{(CSR_OUT_WIDTH-1){1'b0}}, csr_in[0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
