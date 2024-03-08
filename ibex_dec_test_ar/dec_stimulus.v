//run_sv2v
`include "dec_stimulus.sv"

module dec_stimulus_v#(
    parameter NUM_TRANS = 10
    )(
        output                clk_i,
        output                rst_ni,
        output[31:0]          instr_rdata_i         // instruction read from memory/cache
    );

    dec_stimulus #(
      .NUM_TRANS(NUM_TRANS)  
    )
    s0(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .instr_rdata_i(instr_rdata_i)
    );

endmodule