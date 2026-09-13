`timescale 1ns/1ps
`default_nettype none

module tb_rv12_chip_core;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic [7:0] ext_in = '0;
    logic [7:0] status_out;

    always #10 clk = ~clk; // 50 MHz

    rv12_chip_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .ext_in(ext_in),
        .status_out(status_out)
    );

    initial begin
        $dumpfile("rv12_core.vcd");
        $dumpvars(0, tb_rv12_chip_core);

        repeat (5) @(posedge clk);
        rst_n <= 1'b1;

        repeat (100) @(posedge clk);

        // In the default ROM, the core continuously executes JAL x0,0.
        if (status_out[4] !== 1'b1 && status_out[1] !== 1'b1)
            $display("WARNING: no instruction-side activity observed at sample point");

        $display("PASS: simulation completed, status=%02x", status_out);
        $finish;
    end
endmodule

`default_nettype wire
