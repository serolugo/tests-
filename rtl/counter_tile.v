`timescale 1ns / 1ps

// TEST CASE 1: Wrong interface, correct logic
// Missing csr_in_re and csr_out_we ports — connectivity check should FAIL
// Logic itself is correct (counter)

module counter_tile #(
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
    output wire [CSR_OUT_WIDTH-1:0]  csr_out
    // csr_in_re  ← MISSING
    // csr_out_we ← MISSING
);

    reg [REG_WIDTH-1:0] count;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            count <= 0;
        else if (csr_in[1])
            count <= 0;
        else if (csr_in[0])
            count <= count + data_reg_a;
    end

    assign data_reg_c = count;
    assign csr_out    = {{(CSR_OUT_WIDTH-2){1'b0}}, csr_in[1:0]};

endmodule
