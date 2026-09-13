`default_nettype none

module rv12_data_ram #(
    parameter int WORDS = 64
) (
    input  logic        clk,
    input  logic        we,
    input  logic [3:0]  be,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
    localparam int AW = $clog2(WORDS);
    logic [31:0] mem [0:WORDS-1];
    logic [AW-1:0] word_addr;

    assign word_addr = addr[AW+1:2];
    assign rdata = mem[word_addr];

    always_ff @(posedge clk) begin
        if (we) begin
            if (be[0]) mem[word_addr][ 7: 0] <= wdata[ 7: 0];
            if (be[1]) mem[word_addr][15: 8] <= wdata[15: 8];
            if (be[2]) mem[word_addr][23:16] <= wdata[23:16];
            if (be[3]) mem[word_addr][31:24] <= wdata[31:24];
        end
    end
endmodule

`default_nettype wire
