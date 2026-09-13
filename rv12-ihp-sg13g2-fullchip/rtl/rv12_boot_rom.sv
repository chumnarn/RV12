`default_nettype none

module rv12_boot_rom #(
    parameter int AW = 10
) (
    input  logic [31:0] addr,
    output logic [31:0] rdata
);
    logic [AW-1:2] word_addr;

    always_comb begin
        word_addr = addr[AW-1:2];
        unique case (word_addr)
            // 0x00000000: jal x0, 0
            // Minimal deterministic smoke-test firmware.
            'h000: rdata = 32'h0000_006f;
            default: rdata = 32'h0000_0013; // nop = addi x0,x0,0
        endcase
    end
endmodule

`default_nettype wire
