`include "lsu_monitor.sv"
module lsu_monitor_v(
    input                   clk_i,
    input                   rst_ni,
    input [31:0]            data_rdata_i,
    input [31:0]            adder_result_ex_i,  
    input [31:0]            lsu_wdata_i,       
    input                   data_req_o,
    input [31:0]            data_addr_o,
    input                   data_we_o,
    input [3:0]             data_be_o,
    input [31:0]            data_wdata_o,
    input [31:0]            lsu_rdata_o,         
    input                   lsu_rdata_valid_o,
    input                   addr_incr_req_o,
    input [31:0]            addr_last_o,         

    input                   lsu_req_done_o,       

    input                   lsu_resp_valid_o,     

    input                   load_err_o,
    input                   load_resp_intg_err_o,
    input                   store_err_o,
    input                   store_resp_intg_err_o,

    input                   busy_o,

    input                   perf_load_o,
    input                   perf_store_o
);

lsu_monitor m0(
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .data_rdata_i(data_rdata_i),
    .adder_result_ex_i(adder_result_ex_i),    
    .lsu_wdata_i(lsu_wdata_i),       
    .data_req_o(data_req_o),
    .data_addr_o(data_addr_o),
    .data_we_o(data_we_o),
    .data_be_o(data_be_o),
    .data_wdata_o(data_wdata_o),
    .lsu_rdata_o(lsu_rdata_o),         
    .lsu_rdata_valid_o(lsu_rdata_valid_o),
    .addr_incr_req_o(addr_incr_req_o),
    .addr_last_o(addr_last_o),         

    .lsu_req_done_o(lsu_req_done_o),       

    .lsu_resp_valid_o(lsu_resp_valid_o),     

    .load_err_o(load_err_o),
    .load_resp_intg_err_o(load_resp_intg_err_o),
    .store_err_o(store_err_o),
    .store_resp_intg_err_o(store_resp_intg_err_o),

    .busy_o(busy_o),

    .perf_load_o(perf_load_o),
    .perf_store_o(perf_store_o)
);
endmodule