`default_nettype none

module rv12_chip_core (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] ext_in,
    output logic [7:0] status_out
);
    import riscv_pma_pkg::*;
    import riscv_state_pkg::*;

    localparam int MXLEN = 32;
    localparam int ALEN  = 32;
    localparam int PMA_CNT = 1;

    // ------------------------------------------------------------------------
    // PMA: permit normal executable/read/write memory in 0x0000_0000..0x0fff_ffff
    // ------------------------------------------------------------------------
    pmacfg_t          pma_cfg [PMA_CNT];
    logic [MXLEN-1:0] pma_adr [PMA_CNT];

    always_comb begin
        pma_cfg[0] = '0;
        pma_cfg[0].mem_type = MEM_TYPE_MAIN;
        pma_cfg[0].r = 1'b1;
        pma_cfg[0].w = 1'b1;
        pma_cfg[0].x = 1'b1;
        pma_cfg[0].c = 1'b0;
        pma_cfg[0].cc = 1'b0;
        pma_cfg[0].ri = 1'b1;
        pma_cfg[0].wi = 1'b1;
        pma_cfg[0].m = 1'b0;
        pma_cfg[0].amo_type = AMO_TYPE_NONE;
        pma_cfg[0].a = TOR;
        pma_adr[0] = 32'h1000_0000;
    end

    // ------------------------------------------------------------------------
    // Instruction AHB-Lite
    // ------------------------------------------------------------------------
    logic        ins_HSEL;
    logic [31:0] ins_HADDR;
    logic [31:0] ins_HWDATA;
    logic [31:0] ins_HRDATA;
    logic        ins_HWRITE;
    logic [2:0]  ins_HSIZE;
    logic [2:0]  ins_HBURST;
    logic [3:0]  ins_HPROT;
    logic [1:0]  ins_HTRANS;
    logic        ins_HMASTLOCK;
    logic        ins_HREADY;
    logic        ins_HRESP;

    rv12_boot_rom u_boot_rom (
        .addr  (ins_HADDR),
        .rdata (ins_HRDATA)
    );

    assign ins_HREADY = 1'b1;
    assign ins_HRESP  = 1'b0;

    // ------------------------------------------------------------------------
    // Data AHB-Lite
    // ------------------------------------------------------------------------
    logic        dat_HSEL;
    logic [31:0] dat_HADDR;
    logic [31:0] dat_HWDATA;
    logic [31:0] dat_HRDATA;
    logic        dat_HWRITE;
    logic [2:0]  dat_HSIZE;
    logic [2:0]  dat_HBURST;
    logic [3:0]  dat_HPROT;
    logic [1:0]  dat_HTRANS;
    logic        dat_HMASTLOCK;
    logic        dat_HREADY;
    logic        dat_HRESP;

    logic        dat_valid;
    logic [3:0]  dat_be;

    assign dat_valid = dat_HSEL & dat_HTRANS[1];

    always_comb begin
        unique case (dat_HSIZE)
            3'b000: dat_be = 4'b0001 << dat_HADDR[1:0];
            3'b001: dat_be = dat_HADDR[1] ? 4'b1100 : 4'b0011;
            default: dat_be = 4'b1111;
        endcase
    end

    rv12_data_ram #(.WORDS(64)) u_data_ram (
        .clk   (clk),
        .we    (dat_valid & dat_HWRITE),
        .be    (dat_be),
        .addr  (dat_HADDR),
        .wdata (dat_HWDATA),
        .rdata (dat_HRDATA)
    );

    assign dat_HREADY = 1'b1;
    assign dat_HRESP  = 1'b0;

    // ------------------------------------------------------------------------
    // Debug interface: tied inactive in the first silicon implementation.
    // ------------------------------------------------------------------------
    logic [31:0] dbg_dato;
    logic        dbg_ack;
    logic        dbg_bp;

    riscv_top_ahb3lite #(
        .MXLEN        (32),
        .ALEN         (32),
        .PC_INIT      (32'h0000_0000),
        .HAS_USER     (1'b0),
        .HAS_SUPER    (1'b0),
        .HAS_HYPER    (1'b0),
        .HAS_BPU      (1'b0),
        .HAS_FPU      (1'b0),
        .HAS_MMU      (1'b0),
        .HAS_RVM      (1'b1),
        .HAS_RVA      (1'b0),
        .HAS_RVC      (1'b0),
        .IS_RV32E     (1'b0),
        .BREAKPOINTS  (2),
        .PMA_CNT      (PMA_CNT),
        .PMP_CNT      (0),
        .ICACHE_SIZE  (0),
        .DCACHE_SIZE  (0),
        .TECHNOLOGY   ("GENERIC")
    ) u_rv12 (
        .HRESETn      (rst_n),
        .HCLK         (clk),

        .pma_cfg_i    (pma_cfg),
        .pma_adr_i    (pma_adr),

        .ins_HSEL     (ins_HSEL),
        .ins_HADDR    (ins_HADDR),
        .ins_HWDATA   (ins_HWDATA),
        .ins_HRDATA   (ins_HRDATA),
        .ins_HWRITE   (ins_HWRITE),
        .ins_HSIZE    (ins_HSIZE),
        .ins_HBURST   (ins_HBURST),
        .ins_HPROT    (ins_HPROT),
        .ins_HTRANS   (ins_HTRANS),
        .ins_HMASTLOCK(ins_HMASTLOCK),
        .ins_HREADY   (ins_HREADY),
        .ins_HRESP    (ins_HRESP),

        .dat_HSEL     (dat_HSEL),
        .dat_HADDR    (dat_HADDR),
        .dat_HWDATA   (dat_HWDATA),
        .dat_HRDATA   (dat_HRDATA),
        .dat_HWRITE   (dat_HWRITE),
        .dat_HSIZE    (dat_HSIZE),
        .dat_HBURST   (dat_HBURST),
        .dat_HPROT    (dat_HPROT),
        .dat_HTRANS   (dat_HTRANS),
        .dat_HMASTLOCK(dat_HMASTLOCK),
        .dat_HREADY   (dat_HREADY),
        .dat_HRESP    (dat_HRESP),

        .ext_nmi      (ext_in[0]),
        .ext_tint     (ext_in[1]),
        .ext_sint     (ext_in[2]),
        .ext_int      (ext_in[6:3]),

        .dbg_stall    (1'b0),
        .dbg_strb     (1'b0),
        .dbg_we       (1'b0),
        .dbg_addr     ('0),
        .dbg_dati     ('0),
        .dbg_dato     (dbg_dato),
        .dbg_ack      (dbg_ack),
        .dbg_bp       (dbg_bp)
    );

    // Simple activity/bring-up observability pads.
    always_comb begin
        status_out[0] = dbg_bp;
        status_out[1] = ins_HSEL;
        status_out[2] = dat_HSEL;
        status_out[3] = dat_HWRITE;
        status_out[4] = ins_HTRANS[1];
        status_out[5] = dat_HTRANS[1];
        status_out[6] = dbg_ack;
        status_out[7] = ext_in[7];
    end

endmodule

`default_nettype wire
