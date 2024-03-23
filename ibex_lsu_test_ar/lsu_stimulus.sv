`ifndef period
`timescale 1ns / 100ps
`define period 1e-9
`define trise 0.2
`define seconds_to_time_units_mult 1e9
`endif
module lsu_stimulus (
    output  logic         clk_i,
    output  logic         rst_ni,
    input   logic         data_req_o,
    output  logic         data_gnt_i,
    output  logic         data_rvalid_i,
    output  logic         data_bus_err_i,
    output  logic         data_pmp_err_i,
    output  logic [31:0]  data_rdata_i,
    output  logic         lsu_we_i,             // write enable                     -> from ID/EX
    output  logic [1:0]   lsu_type_i,           // data type: word, half word, byte -> from ID/EX
    output  logic [31:0]  lsu_wdata_i,          // data to write to memory          -> from ID/EX
    output  logic         lsu_sign_ext_i,       // sign extension                   -> from ID/EX
    output  logic         lsu_req_i,            // data request                     -> from ID/EX
    output  logic [31:0]  adder_result_ex_i    // address computed in ALU          -> from ID/EX
);
bit prev_gnt, prev_valid;

always #2 clk_i = ~clk_i;

function void driveInputs();
    lsu_we_i = $urandom_range(0, 1);
    adder_result_ex_i = $urandom();
    lsu_sign_ext_i = $urandom_range(0, 1);
    if(lsu_we_i)   lsu_wdata_i = $urandom();
    lsu_req_i = 1;
    lsu_type_i = $urandom(0, 3);
endfunction

function void driveCtrlSignals();
    if(prev_gnt == 1 & prev_valid == 0 & data_req_o == 0) begin
        data_rvalid_i = 1;
        adder_result_ex_i = $urandom();
        data_rdata_i = $urandom();
    end
    if(data_req_o == 1)    data_gnt_i = 1;
    prev_gnt = data_gnt_i;
    prev_valid = data_rvalid_i;
endfunction

initial begin
    logic [31:0] opcode;
    rst_ni = 0;
    clk_i = 0;
    instr_rdata_i = 0;
    #20 rst_ni = 1;
    forever begin
        driveCtrlSignals();
        internal_count++;
        @(posedge clk_i);
        driveInputs();
    end
end
endmodule