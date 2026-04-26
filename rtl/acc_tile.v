`timescale 1ns / 1ps

module acc_tile #(
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

    // csr_in[0] = accumulate enable
    // csr_in[1] = clear accumulator

    reg [REG_WIDTH-1:0] acc;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            acc <= 0;
        else if (csr_in[1])
            acc <= 0;
        else if (csr_in[0])
            acc <= acc + data_reg_a;
    end

    assign data_reg_c  = acc;
    assign csr_out     = {{(CSR_OUT_WIDTH-2){1'b0}}, csr_in[1:0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
