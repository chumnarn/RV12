`default_nettype none

module chip_top (
`ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
`endif
    inout wire       clk_PAD,
    inout wire       rst_n_PAD,
    inout wire [7:0] input_PAD,
    inout wire [7:0] output_PAD
);
    wire       clk_core;
    wire       rst_n_core;
    wire [7:0] ext_in;
    wire [7:0] status_out;

    sg13g2_IOPadIOVdd u_iovdd (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
    );

    sg13g2_IOPadIOVss u_iovss (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
    );

    sg13g2_IOPadVdd u_vdd (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
    );

    sg13g2_IOPadVss u_vss (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
    );

    sg13g2_IOPadIn u_clk_pad (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
        .p2c(clk_core),
        .pad(clk_PAD)
    );

    sg13g2_IOPadIn u_rst_pad (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
        .p2c(rst_n_core),
        .pad(rst_n_PAD)
    );

    generate
        for (genvar i = 0; i < 8; i++) begin : g_in
            sg13g2_IOPadIn u_pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
                .p2c(ext_in[i]),
                .pad(input_PAD[i])
            );
        end
        for (genvar i = 0; i < 8; i++) begin : g_out
            sg13g2_IOPadOut30mA u_pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
                .c2p(status_out[i]),
                .pad(output_PAD[i])
            );
        end
    endgenerate

    (* keep_hierarchy = "yes" *)
    rv12_chip_core u_core (
        .clk        (clk_core),
        .rst_n      (rst_n_core),
        .ext_in     (ext_in),
        .status_out (status_out)
    );

endmodule

`default_nettype wire
