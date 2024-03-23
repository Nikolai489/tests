module lsu_monitor(
    input logic                   clk_i,
    input logic                   rst_ni,
    input logic [31:0]            data_rdata_i,
    input logic [31:0]            adder_result_ex_i,    
    input logic [31:0]            lsu_wdata_i,       
    input logic                   data_req_o,
    input logic [31:0]            data_addr_o,
    input logic                   data_we_o,
    input logic [3:0]             data_be_o,
    input logic [31:0]            data_wdata_o,
    input logic [31:0]            lsu_rdata_o,         
    input logic                   lsu_rdata_valid_o,
    input logic                   addr_incr_req_o,
    input logic [31:0]            addr_last_o,         

    input logic                   lsu_req_done_o,       

    input logic                   lsu_resp_valid_o,     

    input logic                   load_err_o,
    input logic                   load_resp_intg_err_o,
    input logic                   store_err_o,
    input logic                   store_resp_intg_err_o,

    input logic                   busy_o,

    input logic                   perf_load_o,
    input logic                   perf_store_o
);


function void print();

    if(data_rdata_i != 0) begin
        if(data_rdata_i == lsu_rdata_o)
            $display("T=%0t [Scoreboard] PASS! Read Data MATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, data_rdata_i, lsu_rdata_o);
        else
            $display("T=%0t [Scoreboard] Error! Read Data MISMATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, data_rdata_i, lsu_rdata_o); 
    end

    if(adder_result_ex_i != 0)begin
        if(adder_result_ex_i[31:2] == data_addr_o)
            $display("T=%0t [Scoreboard] PASS! Address Word Aligned\t Addr -> 0x%0h\n", $time, data_addr_o);
        else
            $display("T=%0t [Scoreboard] ERROR! Address Word Misaligned\t Addr -> 0x%0h\n", $time, adder_result_ex_i[31:2]);
    end

    if(lsu_wdata_i != 0) begin
        case(adder_result_ex_i[1:0])
            2'b00: begin
                if(lsu_wdata_i == data_wdata_o)
                    $display("T=%0t [Scoreboard] PASS! Write Data MATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, lsu_wdata_i, data_wdata_o);
                else
                    $display("T=%0t [Scoreboard] ERROR! Write Data MISMATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, lsu_wdata_i, data_wdata_o);
            end
            2'b01: begin
                if({lsu_wdata_i[23:0], lsu_wdata_i[31:24]} == data_wdata_o)
                    $display("T=%0t [Scoreboard] PASS! Write Data MATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, {lsu_wdata_i[23:0], lsu_wdata_i[31:24]}, data_wdata_o);
                else
                    $display("T=%0t [Scoreboard] ERROR! Write Data MISMATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, {lsu_wdata_i[23:0], lsu_wdata_i[31:24]}, data_wdata_o);
            end
            2'b10: begin
                if({lsu_wdata_i[15:0], lsu_wdata_i[31:16]} == data_wdata_o)
                    $display("T=%0t [Scoreboard] PASS! Write Data MATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, {lsu_wdata_i[15:0], lsu_wdata_i[31:16]}, data_wdata_o);
                else
                    $display("T=%0t [Scoreboard] ERROR! Write Data MISMATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, {lsu_wdata_i[15:0], lsu_wdata_i[31:16]}, data_wdata_o); 
            end
            2'b11: begin
                if({lsu_wdata_i[7:0], lsu_wdata_i[31:8]} == data_wdata_o)
                    $display("T=%0t [Scoreboard] PASS! Write Data MATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, {lsu_wdata_i[7:0], lsu_wdata_i[31:8]}, data_wdata_o);
                else
                    $display("T=%0t [Scoreboard] ERROR! Write Data MISMATCH\t Data_in -> 0x%0h \t Data_out -> 0x%0h\n", $time, {lsu_wdata_i[7:0], lsu_wdata_i[31:8]}, data_wdata_o);
            end
        endcase

        if(adder_result_ex_i != 0)begin
            if(adder_result_ex_i[31:2] == data_addr_o)
                $display("T=%0t [Scoreboard] PASS! Address Word Aligned\t Addr -> 0x%0h\n", $time, data_addr_o);
            else
                $display("T=%0t [Scoreboard] ERROR! Address Word Misaligned\t Addr -> 0x%0h\n", $time, adder_result_ex_i[31:2]);
        end
    end
endfunction

initial begin
    forever begin
        @(posedge clk_i);
        print();
    end
end

endmodule