`timescale 1ns / 1ps

// TEST CASE 4: Large circuit — 8-tap FIR filter
// All 9 SemiCoLab ports correct
// Large combinational logic — good synthesis stress test

module fir_tile #(
    parameter REG_WIDTH     = 32,
    parameter CSR_IN_WIDTH  = 16,
    parameter CSR_OUT_WIDTH = 16,
    parameter TAPS          = 8,
    parameter COEFF_WIDTH   = 8
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

    // csr_in[0]     = filter enable
    // csr_in[1]     = flush (clear delay line)
    // csr_in[3:2]   = coefficient set select (4 preloaded sets)
    // data_reg_a    = input sample (signed 16-bit in [15:0])
    // data_reg_b    = unused
    // data_reg_c    = filtered output (signed 32-bit)

    // ── Coefficient ROM (4 sets x 8 taps) ────────────────────────────────
    // Set 0: Low-pass
    // Set 1: High-pass
    // Set 2: Band-pass
    // Set 3: All-pass (identity)
    function signed [COEFF_WIDTH-1:0] get_coeff;
        input [1:0] set;
        input [2:0] tap;
        begin
            case ({set, tap})
                5'h00: get_coeff =  8'sd2;
                5'h01: get_coeff =  8'sd5;
                5'h02: get_coeff =  8'sd10;
                5'h03: get_coeff =  8'sd20;
                5'h04: get_coeff =  8'sd10;
                5'h05: get_coeff =  8'sd5;
                5'h06: get_coeff =  8'sd2;
                5'h07: get_coeff =  8'sd1;

                5'h08: get_coeff = -8'sd2;
                5'h09: get_coeff = -8'sd5;
                5'h0A: get_coeff = -8'sd10;
                5'h0B:  get_coeff =  8'sd55;
                5'h0C: get_coeff = -8'sd10;
                5'h0D: get_coeff = -8'sd5;
                5'h0E: get_coeff = -8'sd2;
                5'h0F: get_coeff = -8'sd1;

                5'h10: get_coeff = -8'sd3;
                5'h11: get_coeff =  8'sd0;
                5'h12: get_coeff =  8'sd15;
                5'h13: get_coeff =  8'sd25;
                5'h14: get_coeff =  8'sd15;
                5'h15: get_coeff =  8'sd0;
                5'h16: get_coeff = -8'sd3;
                5'h17: get_coeff =  8'sd0;

                5'h18: get_coeff =  8'sd0;
                5'h19: get_coeff =  8'sd0;
                5'h1A: get_coeff =  8'sd0;
                5'h1B:  get_coeff =  8'sd64;
                5'h1C: get_coeff =  8'sd0;
                5'h1D: get_coeff =  8'sd0;
                5'h1E: get_coeff =  8'sd0;
                5'h1F: get_coeff =  8'sd0;

                default: get_coeff = 8'sd0;
            endcase
        end
    endfunction

    // ── Delay line ────────────────────────────────────────────────────────
    reg signed [15:0] delay [0:TAPS-1];
    integer i;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            for (i = 0; i < TAPS; i = i + 1)
                delay[i] <= 16'sd0;
        end else if (csr_in[1]) begin
            for (i = 0; i < TAPS; i = i + 1)
                delay[i] <= 16'sd0;
        end else if (csr_in[0]) begin
            delay[0] <= $signed(data_reg_a[15:0]);
            for (i = 1; i < TAPS; i = i + 1)
                delay[i] <= delay[i-1];
        end
    end

    // ── MAC (multiply-accumulate) ─────────────────────────────────────────
    reg signed [REG_WIDTH-1:0] acc;
    wire [1:0] coeff_set = csr_in[3:2];

    always @(*) begin
        acc = 32'sd0;
        for (i = 0; i < TAPS; i = i + 1)
            acc = acc + (delay[i] * $signed(get_coeff(coeff_set, i[2:0])));
    end

    // ── Saturation ────────────────────────────────────────────────────────
    wire signed [REG_WIDTH-1:0] sat_out;
    assign sat_out = (acc > 32'sh7FFFFFFF) ? 32'sh7FFFFFFF :
                     (acc < -32'sh80000000) ? -32'sh80000000 : acc;

    // ── Outputs ───────────────────────────────────────────────────────────
    assign data_reg_c  = sat_out;
    assign csr_out     = {{(CSR_OUT_WIDTH-4){1'b0}}, csr_in[3:0]};
    assign csr_in_re   = 1'b0;
    assign csr_out_we  = 1'b0;

endmodule
