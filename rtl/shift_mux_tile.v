`timescale 1ns / 1ps

// TEST CASE 5: Width mismatch
// Interface is complete and correct — all 9 SemiCoLab ports present
// Internal signal connection has a width mismatch:
// csr_in is 16-bit but only 8 bits are assigned to an intermediate
// 16-bit register without proper adaptation — iverilog should catch this

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

    // 8-bit wire assigned to a 16-bit bus without zero-extension
    wire [7:0]  narrow_ctrl;
    wire [15:0] wide_ctrl;

    assign narrow_ctrl = csr_in[7:0];
    assign wide_ctrl   = narrow_ctrl;  // implicit truncation/extension — width mismatch

    reg [REG_WIDTH-1:0] result;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            result <= 0;
        else if (wide_ctrl[0])
            result <= data_reg_a >> wide_ctrl[4:1];
        else
            result <= data_reg_b << wide_ctrl[4:1];
    end

    assign data_reg_c  = result;
    assign csr_out     = wide_ctrl;
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
