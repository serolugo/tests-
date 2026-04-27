`timescale 1ns / 1ps

// TEST CASE 2: Correct interface, bad logic
// Interface is complete and correct — all 9 SemiCoLab ports present
// Logic has an incomplete case statement → Yosys will infer a latch → synthesis FAIL

module mux_tile #(
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

    // Incomplete case → latch inferred → synthesis FAIL
    reg [REG_WIDTH-1:0] result;

    always @(*) begin
        case (csr_in[1:0])
            2'b00: result = data_reg_a;
            2'b01: result = data_reg_b;
            2'b10: result = data_reg_a + data_reg_b;
            // 2'b11 missing → latch
        endcase
    end

    assign data_reg_c  = result;
    assign csr_out     = {{(CSR_OUT_WIDTH-2){1'b0}}, csr_in[1:0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
