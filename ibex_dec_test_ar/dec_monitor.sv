`timescale 1ns/100ps

`include "dec_typedefs.sv"
`include "dr32e_pkg.sv"
module dec_monitor#(
        parameter int NUM_TRANS = 10
    )(
    input  logic                 clk_i,
    input  logic                 rst_ni,
  
    // to/from controller
    input logic                 illegal_insn_o,        // illegal instr encountered
    input logic                 ebrk_insn_o,           // trap instr encountered
    input logic                 mret_insn_o,           // return from exception instr
                                                        // encountered
    input logic                 dret_insn_o,           // return from debug instr encountered
    input logic                 ecall_insn_o,          // syscall instr encountered
    input logic                 wfi_insn_o,            // wait for interrupt instr encountered
    input logic                 jump_set_o,            // jump taken set signal
    input  logic                 branch_taken_i,        // registered branch decision
    input logic                 icache_inval_o,
  
    // from IF-ID pipeline register
    input  logic                 instr_first_cycle_i,   // instruction read is in its first cycle
    input  logic [31:0]          instr_rdata_i,         // instruction read from memory/cache
    input  logic [31:0]          instr_rdata_alu_i,     // instruction read from memory/cache
                                                        // replicated to ease fan-out)
  
    input  logic                 illegal_c_insn_i,      // compressed instruction decode failed
  
    // immediates
    input dr32e_pkg::imm_a_sel_e  imm_a_mux_sel_o,       // immediate selection for operand a
    input dr32e_pkg::imm_b_sel_e  imm_b_mux_sel_o,       // immediate selection for operand b
    input dr32e_pkg::op_a_sel_e   bt_a_mux_sel_o,        // branch target selection operand a
    input dr32e_pkg::imm_b_sel_e  bt_b_mux_sel_o,        // branch target selection operand b
    input logic [31:0]           imm_i_type_o,
    input logic [31:0]           imm_s_type_o,
    input logic [31:0]           imm_b_type_o,
    input logic [31:0]           imm_u_type_o,
    input logic [31:0]           imm_j_type_o,
    input logic [31:0]           zimm_rs1_type_o,
  
    // register file
    input dr32e_pkg::rf_wd_sel_e rf_wdata_sel_o,   // RF write data selection
    input logic                 rf_we_o,          // write enable for regfile
    input logic [4:0]           rf_raddr_a_o,
    input logic [4:0]           rf_raddr_b_o,
    input logic [4:0]           rf_waddr_o,
    input logic                 rf_ren_a_o,          // Instruction reads from RF addr A
    input logic                 rf_ren_b_o,          // Instruction reads from RF addr B
  
    // ALU
    input dr32e_pkg::alu_op_e    alu_operator_o,        // ALU operation selection
    input dr32e_pkg::op_a_sel_e  alu_op_a_mux_sel_o,    // operand a selection: reg value, PC,
                                                        // immediate or zero
    input dr32e_pkg::op_b_sel_e  alu_op_b_mux_sel_o,    // operand b selection: reg value or
                                                        // immediate
    input logic                 alu_multicycle_o,      // ternary bitmanip instruction
  
    // MULT & DIV
    input logic                 mult_en_o,             // perform integer multiplication
    input logic                 div_en_o,              // perform integer division or remainder
    input logic                 mult_sel_o,            // as above but static, for data muxes
    input logic                 div_sel_o,             // as above but static, for data muxes
  
    input dr32e_pkg::md_op_e     multdiv_operator_o,
    input logic [1:0]           multdiv_signed_mode_o,
  
    // CSRs
    input logic                 csr_access_o,          // access to CSR
    input dr32e_pkg::csr_op_e    csr_op_o,              // operation to perform on CSR
  
    // LSU
    input logic                 data_req_o,            // start transaction to data memory
    input logic                 data_we_o,             // write enable
    input logic [1:0]           data_type_o,           // size of transaction: byte, half
                                                        // word or word
    input logic                 data_sign_extension_o, // sign extension for data read from
                                                        // memory
  
    // jump/branches
    input logic                 jump_in_dec_o,         // jump is being calculated in ALU
    input logic                 branch_in_dec_o
    );

    bit[1:0] dtype;
    op_e opcode; 
    instr_type_e instr_type;

    function void print();
        dr32e_pkg::alu_op_e alu_op;
        dr32e_pkg::op_b_sel_e bmux;
        dr32e_pkg::imm_b_sel_e imm_bmux;
        
        opcode = op_e'(instr_rdata_i[7:0]);
        //$display("opcode : %0h", opcode);
        if(instr_rdata_i[13:12] == 2'b00)
            dtype = 2'b10;
        else if(instr_rdata_i[13:12] == 2'b10)
            dtype = 2'b00;
        else if(instr_rdata_i[13:12] == 2'b01)
            dtype = 2'b01;
        else    
            illegal_insn_o = 1'b1;

        bmux = instr_rdata_i[14] ? dr32e_pkg::OP_B_REG_B : dr32e_pkg::OP_B_IMM;
        imm_bmux = instr_rdata_i[14] ? dr32e_pkg::IMM_B_I : dr32e_pkg::IMM_B_S;

        case(instr_rdata_i[14:12])
            3'b000: 
              alu_op = dr32e_pkg::ALU_ADD;
            3'b001:
              alu_op = dr32e_pkg::ALU_SLL;
            3'b010:
              alu_op = dr32e_pkg::ALU_SLT;
            3'b011:
              alu_op = dr32e_pkg::ALU_SLTU;
            3'b100:
              alu_op = dr32e_pkg::ALU_XOR;
            3'b101:
            begin
              if(instr_rdata_i[31:27] == 'h0)
                alu_op = dr32e_pkg::ALU_SRL;
              else 
                alu_op = dr32e_pkg::ALU_SRA;
            end
            3'b110:
              alu_op = dr32e_pkg::ALU_OR;
            3'b111:
              alu_op = dr32e_pkg::ALU_AND;
        endcase

        case(opcode)
            JUMP_OP: begin
                if(jump_in_dec_o)begin
                    $display("T=%0t [Scoreboard] PASS! Jump instruction succesfully detected\t Input Instruction -> 0x%0h", $time, instr_rdata_i);
                    if(rf_raddr_a_o == (instr_rdata_i[19:15]) && rf_raddr_b_o == (instr_rdata_i[24:20]) && rf_we_o == 1 && rf_waddr_o == (instr_rdata_i[11:7]))
                        $display("\t RF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_waddr : %0h \t rf_we_o : %0b",rf_raddr_a_o, rf_raddr_b_o, rf_waddr_o, rf_we_o);
                    else
                        $display("\t RF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_waddr : %0h \t rf_we_o : %0b",rf_raddr_a_o, rf_raddr_b_o, rf_waddr_o, rf_we_o); 
                    if(imm_j_type_o == { {12{instr_rdata_i[31]}}, instr_rdata_i[19:12], instr_rdata_i[20], instr_rdata_i[30:21], 1'b0 })
                        $display("\t Jump immediate values MATCH \t IMM_J -> %0h", imm_j_type_o);
                    else
                    $display("\t Jump immediate values MISMATCH \t IMM_J -> %0h", imm_j_type_o); 
                    if(imm_b_mux_sel_o == dr32e_pkg::IMM_B_INCR_PC &&
                        alu_op_a_mux_sel_o == dr32e_pkg::OP_A_CURRPC &&
                        alu_op_b_mux_sel_o == dr32e_pkg::OP_B_IMM &&
                        alu_operator_o == dr32e_pkg::ALU_ADD)
                        $display("\t ALU signals MATCH \t imm_b_sel : %0h  op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                    else
                        $display("\t ALU signals MISMATCH \t imm_b_sel : %0h  op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                end
                else begin
                    $display("T=%0t [Scoreboard] ERROR! Failed to detect a jump instruction\t Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                end      
            end
            BRANCH_OP: begin
                if(branch_in_dec_o)begin
                    $display("T=%0t [Scoreboard] PASS! Branch instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                    if(rf_raddr_a_o == (instr_rdata_i[19:15]) && rf_raddr_b_o == (instr_rdata_i[24:20]))
                        $display("\t RF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h",rf_raddr_a_o, rf_raddr_b_o);
                    else
                    $display("\t RF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h",rf_raddr_a_o, rf_raddr_b_o);
                    if(imm_b_type_o == { {19{instr_rdata_i[31]}}, instr_rdata_i[31], instr_rdata_i[7], instr_rdata_i[30:25], instr_rdata_i[11:8], 1'b0 })
                        $display("\t Branch immediate values MATCH \t IMM_B -> %0h", imm_b_type_o);
                    else
                    $display("\t Branch immediate values MISMATCH \t IMM_B -> %0h", imm_b_type_o); 
                    if(imm_b_mux_sel_o == dr32e_pkg::IMM_B_INCR_PC &&
                        alu_op_a_mux_sel_o == dr32e_pkg::OP_A_CURRPC &&
                        alu_op_b_mux_sel_o == dr32e_pkg::OP_B_IMM &&
                        alu_operator_o == dr32e_pkg::ALU_ADD)
                        $display("\t ALU signals MATCH \t imm_b_sel : %0h  op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                    else
                        $display("\t ALU signals MISMATCH \t imm_b_sel : %0h  op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                end
                else begin
                    $display("T=%0t [Scoreboard] ERROR! Failed to detect a branch instruction\t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                end
            end
            STORE_OP: begin
                if(data_we_o)begin
                    $display("T=%0t [Scoreboard] PASS! Store instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                    if(rf_raddr_a_o == (instr_rdata_i[19:15]) && rf_raddr_b_o == (instr_rdata_i[24:20]))
                        $display("\t RF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h",rf_raddr_a_o, rf_raddr_b_o);
                    else
                    $display("\t RF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h",rf_raddr_a_o, rf_raddr_b_o);
                    if(imm_s_type_o == { {20{instr_rdata_i[31]}}, instr_rdata_i[31:25], instr_rdata_i[11:7]})
                        $display("\t Branch immediate values MATCH \t IMM_S -> %0h", imm_s_type_o);
                    else
                    $display("\t Branch immediate values MISMATCH \t IMM_S -> %0h", imm_s_type_o); 
                    if(imm_a_mux_sel_o == dr32e_pkg::IMM_A_ZERO &&
                        imm_b_mux_sel_o == imm_bmux &&
                        alu_op_a_mux_sel_o == dr32e_pkg::OP_A_REG_A &&
                        alu_op_b_mux_sel_o == bmux &&
                        alu_operator_o == dr32e_pkg::ALU_ADD)
                        $display("\t ALU signals MATCH \t imm_a_sel : %0h  imm_b_sel : %0h op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_a_mux_sel_o, imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                    else
                        $display("\t ALU signals MISMATCH \t imm_b_sel : %0h  op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                end
                else begin
                    $display("T=%0t [Scoreboard] ERROR! Failed to detect a store instruction\t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                end
            end
            UTYPE_OP: begin
                if(imm_u_type_o == {instr_rdata_i[31:12],12'b0})begin
                    $display("T=%0t [Scoreboard] PASS! U-Type immediate values match\t\ IMM_U -> 0x%0h", $time, imm_u_type_o);
                    if(rf_raddr_a_o == (instr_rdata_i[19:15]) && rf_raddr_b_o == (instr_rdata_i[24:20]) && rf_we_o == 'h1 && rf_waddr_o == (instr_rdata_i[11:7]))
                        $display("\t RF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_waddr : %0h \t rf_we_o : %0b",rf_raddr_a_o, rf_raddr_b_o, rf_waddr_o, rf_we_o);
                    else
                        $display("\t RF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_waddr : %0h \t rf_we_o : %0b",rf_raddr_a_o, rf_raddr_b_o, rf_waddr_o, rf_we_o);
                    if(imm_a_mux_sel_o == dr32e_pkg::IMM_A_ZERO &&
                        imm_b_mux_sel_o == dr32e_pkg::IMM_B_U &&
                        alu_op_a_mux_sel_o == dr32e_pkg::OP_A_IMM &&
                        alu_op_b_mux_sel_o == dr32e_pkg::OP_B_IMM &&
                        alu_operator_o == dr32e_pkg::ALU_ADD)
                        $display("\t ALU signals MATCH \t imm_a_sel : %0h  imm_b_sel : %0h op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_a_mux_sel_o, imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                    else
                        $display("\t ALU signals MISMATCH \t imm_b_sel : %0h  op_a_sel : %0h  op_b_sel : %0h  op :%0h\n", imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o, alu_operator_o);
                end
                else begin
                    $display("T=%0t [Scoreboard] ERROR! U-Type immediate values mismatch\t\ IMM_U -> 0x%0h \t 0x%0h \n", $time, imm_u_type_o, {instr_rdata_i[31:12],12'b0});
                end
            end
            ITYPE_OP: begin
                if(imm_i_type_o == { {20{instr_rdata_i[31]}}, instr_rdata_i[31:20] } ) begin
                    $display("T=%0t [Scoreboard] PASS! I-Type immediate values match\t\ IMM_I -> 0x%0h", $time, imm_i_type_o);
                    if(rf_raddr_a_o == (instr_rdata_i[19:15]) && rf_raddr_b_o == (instr_rdata_i[24:20]) && rf_we_o == 'h1 && rf_waddr_o == (instr_rdata_i[11:7]))
                        $display("\t RF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_waddr : %0h \t rf_we_o : %0b",rf_raddr_a_o, rf_raddr_b_o, rf_waddr_o, rf_we_o);
                    else
                        $display("\t RF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_waddr : %0h \t rf_we_o : %0b",rf_raddr_a_o, rf_raddr_b_o, rf_waddr_o, rf_we_o);
                    if(imm_a_mux_sel_o == dr32e_pkg::IMM_A_ZERO &&
                        imm_b_mux_sel_o == dr32e_pkg::IMM_B_I &&
                        alu_op_a_mux_sel_o == dr32e_pkg::OP_A_REG_A &&
                        alu_op_b_mux_sel_o == dr32e_pkg::OP_B_IMM)
                        $display("\t ALU signals MATCH \t imm_a_sel : %0h  imm_b_sel : %0h op_a_sel : %0h  op_b_sel : %0h \n", imm_a_mux_sel_o, imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o);
                    else
                        $display("\t ALU signals MISMATCH \t imm_b_sel : %0h  op_a_sel : %0h  op_b_sel : %0h \n", imm_b_mux_sel_o, alu_op_a_mux_sel_o, alu_op_b_mux_sel_o);
                end
                else begin
                    $display("T=%0t [Scoreboard] ERROR! I-Type immediate values mismatch\t\ IMM_U -> 0x%0h \t 0x%0h \n", $time, imm_i_type_o, { {20{instr_rdata_i[31]}}, instr_rdata_i[31:20] });
                end
            end
            LOAD_OP: begin
                if(imm_i_type_o == { {20{instr_rdata_i[31]}}, instr_rdata_i[31:20] } ) begin
                    $display("T=%0t [Scoreboard] PASS! I-Type immediate values match\t\ IMM_I -> 0x%0h\n", $time, imm_i_type_o);
                end
                else begin
                    $display("T=%0t [Scoreboard] ERROR! I-Type immediate values mismatch\t\ IMM_U -> 0x%0h \t 0x%0h \n", $time, imm_i_type_o, { {20{instr_rdata_i[31]}}, instr_rdata_i[31:20] });
                end  
            end
        endcase

        //if(trans % 3 == 0) begin
            instr_type = instr_type_e'(instr_rdata_i);
            case(instr_type)
                ILLEGAL:
                    begin
                        if(illegal_insn_o)
                        begin
                            $display("T=%0t [Scoreboard] PASS! Illegal instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                            if(rf_raddr_a_o == 'h1F && rf_raddr_b_o == 'h1F && rf_we_o == 0)
                                $display("\t RF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we_o : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);
                            else
                            $display("\t RF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we_o : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o); 
                        end
                        else
                            $display("T=%0t [Scoreboard] ERROR! Failed to detect illegal instruction \t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                    end
                WFI:
                    begin
                        if(wfi_insn_o)begin
                            $display("T=%0t [Scoreboard] PASS! WFI instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                            if(rf_raddr_a_o == 'h0 && rf_raddr_b_o == 'h5 && rf_we_o == 0)
                                $display( "\tRF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);
                            else
                            $display( "\tRF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);  
                        end
                        else
                            $display("T=%0t [Scoreboard] ERROR! Failed to detect WFI instruction \t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                    end
                ECALL:
                    begin
                        if(ecall_insn_o)begin
                            $display("T=%0t [Scoreboard] PASS! ECALL instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                            if(rf_raddr_a_o == 'h0 && rf_raddr_b_o == 'h0 && rf_we_o == 0)
                                $display( "\tRF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);
                            else
                            $display( "\tRF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);  
                        end
                        else
                            $display("T=%0t [Scoreboard] ERROR! Failed to detect ECALL instruction \t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                    end
                EBREAK:
                    begin
                        if(ebrk_insn_o)begin
                            $display("T=%0t [Scoreboard] PASS! EBREAK instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                            if(rf_raddr_a_o == 'h0 && rf_raddr_b_o == 'h1 && rf_we_o == 0)
                                $display( "\tRF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);
                            else
                            $display( "\tRF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);  
                        end
                        else
                            $display("T=%0t [Scoreboard] ERROR! Failed to detect EBREAK instruction \t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                    end
                DEBUG:
                    begin
                        if(dret_insn_o)begin
                            $display("T=%0t [Scoreboard] PASS! Debug instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                            if(rf_raddr_a_o == 'h0 && rf_raddr_b_o == 'h12 && rf_we_o == 0)
                                $display( "\tRF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);
                            else
                            $display( "\tRF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);  
                        end
                        else
                            $display("T=%0t [Scoreboard] ERROR! Failed to detect Debug instruction \t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                    end
                MRET:
                    begin
                        if(mret_insn_o)begin
                            $display("T=%0t [Scoreboard] PASS! MRET instruction successfully detected\t\ Input Instruction -> 0x%0h", $time, instr_rdata_i);
                            if(rf_raddr_a_o == 'h0 && rf_raddr_b_o == 'h2 && rf_we_o == 0)
                                $display( "\tRF Signals MATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);
                            else
                            $display( "\tRF Signals MISMATCH \t rf_addr_a : %0h \t rf_addr_b : %0h \t rf_we : %0b\n",rf_raddr_a_o, rf_raddr_b_o, rf_we_o);  
                        end
                        else
                            $display("T=%0t [Scoreboard] ERROR! Failed to detect MRET instruction \t\ Input Instruction -> 0x%0h\n", $time, instr_rdata_i);
                    end
            endcase
        //end
    endfunction

    initial begin
        while(!rst_ni);
        repeat(NUM_TRANS) begin
            @(posedge clk_i);
            print();
            @(posedge clk_i);
        end
    end
endmodule