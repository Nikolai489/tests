`include "lsu_stimulus.sv"
module lsu_stimulus_v(
    output         clk_i,
    output         rst_ni,
    input          data_req_o,
    output         data_gnt_i,
    output         data_rvalid_i,
    output         data_bus_err_i,
    output         data_pmp_err_i,
    output [31:0]  data_rdata_i,
    output         lsu_we_i,             // write enable                     -> from ID/EX
    output [1:0]   lsu_type_i,           // data type: word, half word, byte -> from ID/EX
    output [31:0]  lsu_wdata_i,          // data to write to memory          -> from ID/EX
    output         lsu_sign_ext_i,       // sign extension                   -> from ID/EX
    output         lsu_req_i,            // data request                     -> from ID/EX
    output [31:0]  adder_result_ex_i    // address computed in ALU          -> from ID/EX
);

lsu_stimulus s0 (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .data_req_o(data_req_o),
    .data_gnt_i(data_gnt_i),
    .data_rvalid_i(data_rvalid_i),
    .data_bus_err_i(data_bus_err_i),
    .data_pmp_err_i(data_pmp_err_i),
    .data_rdata_i(data_rdata_i),
    .lsu_we_i(lsu_we_i),             // write enable                     -> from ID/EX
    .lsu_type_i(lsu_type_i),           // data type: word, half word, byte -> from ID/EX
    .lsu_wdata_i(lsu_wdata_i),          // data to write to memory          -> from ID/EX
    .lsu_sign_ext_i(lsu_sign_ext_i),       // sign extension                   -> from ID/EX
    .lsu_req_i(lsu_req_i),            // data request                     -> from ID/EX
    .adder_result_ex_i(adder_result_ex_i)    // address computed in ALU          -> from ID/EX
);
endmodule