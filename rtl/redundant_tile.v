`timescale 1ns / 1ps

// TEST CASE 10: Borderline valid — redundant and suboptimal logic
//
// Design is functionally correct but contains:
// - Redundant intermediate assignments Yosys will optimize away
// - A mux with explicit default that avoids latch inference
// - Double-negation (~~signal) that nets to the original value
// - Unnecessary pipeline stage that adds latency without benefit
//
// Yosys synthesizes this without errors or warnings.
// Expected: PASS (borderline valid — suboptimal but not incorrect)

module redundant_tile #(
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

    // Redundant intermediate wires — Yosys optimizes these away
    wire [REG_WIDTH-1:0] stage1 = data_reg_a + data_reg_b;
    wire [REG_WIDTH-1:0] stage2 = stage1 + 32'd0;       // +0 is redundant
    wire [REG_WIDTH-1:0] stage3 = stage2 | 32'd0;       // OR 0 is redundant
    wire [REG_WIDTH-1:0] stage4 = stage3 & 32'hFFFFFFFF; // AND all-ones is redundant

    // Double negation — nets to original value
    wire enable = ~~csr_in[0];

    // Mux with explicit default — avoids latch, but all branches are the same
    reg [REG_WIDTH-1:0] result;
    always @(*) begin
        case (csr_in[1:0])
            2'b00:   result = enable ? stage4 : 32'd0;
            2'b01:   result = enable ? stage4 : 32'd0;  // duplicate branch
            2'b10:   result = enable ? stage4 : 32'd0;  // duplicate branch
            default: result = 32'd0;                     // safe default
        endcase
    end

    // Unnecessary registered pipeline stage
    reg [REG_WIDTH-1:0] result_reg;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            result_reg <= 0;
        else
            result_reg <= result;   // single cycle delay with no functional benefit
    end

    assign data_reg_c  = result_reg;
    assign csr_out     = {{(CSR_OUT_WIDTH-2){1'b0}}, csr_in[1:0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
