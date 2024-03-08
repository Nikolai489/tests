`ifndef period
`timescale 1ns / 100ps
`define period 1e-9
`define trise 0.2
`define seconds_to_time_units_mult 1e9
`endif

`include "dec_typedefs.sv"
module dec_stimulus #(
    parameter int NUM_TRANS = 10
    )(
    output  logic                 clk_i,
    output  logic                 rst_ni,
    output  logic [31:0]          instr_rdata_i         // instruction read from memory/cache
    );

    int internal_count;

    always #2 clk_i = ~clk_i;

    function logic [31:0] getRandomOpcode;
        logic [31:0] arr1[6];
        logic [31:0] arr2[6];
        int index;

        arr1[0] = ILLEGAL; //0x0FFFFFFF
        arr1[1] = WFI; //0x10500073
        arr1[2] = ECALL; //0x73
        arr1[3] = EBREAK; //0x100073
        arr1[4] = DEBUG; //0x7B200073
        arr1[5] = MRET; //0x30200073
        arr2[0] = JUMP;  //0xD90006F
        arr2[1] = BRANCH; //0x6000063
        arr2[2] = STORE; //0x18023
        arr2[3] = UTYPE; //0x307037
        arr2[4] = ITYPE; //0xE000C113
        arr2[5] = LOAD;  //0xFFFFFFE3

        index = $urandom() % 6;

        if(internal_count % 3 == 0)
            getRandomOpcode = arr1[index];
        else
            getRandomOpcode = arr2[index];
    endfunction

    function logic [31:0] getScrambledInstr;
        input [31:0] instr;
        logic [31:0] randomBits1, randomBits2, randomBits3, result;
        op_e opc;
        randomBits1 = $urandom();
        randomBits1 = randomBits1 & 32'hFFFF;
        result = (instr & 32'h00007FFF) | (randomBits1 << 15);
        randomBits2 = $urandom();
        randomBits2 = randomBits2 & 32'h1F;
        result = (result & 32'hFFFF83FF) | (randomBits2 << 7);
        randomBits3 = $urandom();
        randomBits3 = randomBits3 & 32'h7;
        randomBits3 = randomBits3 << 12;

        opc = op_e '(instr & 'h7F);
        if(internal_count % 3 == 0)
            result = instr;
        else begin
            case(opc)
                JUMP_OP, UTYPE_OP: result = (result & 32'hFFFFE0FF) | (randomBits3);
                BRANCH_OP: begin
                    if(randomBits3 == 'h2000 || randomBits3 == 'h3000)
                        randomBits3 = 'h1000;
                    result = (result & 32'hFFFFE0FF) | randomBits3;
                end
                ITYPE_OP: begin
                    if(randomBits3 == 'h1000 || randomBits3 == 'h5000)
                        randomBits3 = 'h3000;
                    result = (result & 32'hFFFFE0FF) | randomBits3;
                end
                LOAD_OP: begin
                    if(randomBits3 == 'h3000 || randomBits3 == 'h6000 || randomBits3 == 'h7000)
                        randomBits3 = 'h4000;
                    result = (result & 32'hFFFFE0FF) | randomBits3;
                end
                STORE_OP: begin
                    if(randomBits3 > 'h2000)
                        randomBits3 = 'h2000;
                    result = (result & 32'hFFFFE0FF) | randomBits3;  
                end
            endcase
        end
        getScrambledInstr = result;
    endfunction

    initial begin
        logic [31:0] opcode;
        rst_ni = 0;
        instr_rdata_i = 0;
        #20 rst_ni = 1;
        repeat(NUM_TRANS) begin
            @(posedge clk_i);
            internal_count++;
            opcode = getRandomOpcode();
            instr_rdata_i = getScrambledInstr(opcode);
            @(posedge clk_i);
        end
    end
endmodule