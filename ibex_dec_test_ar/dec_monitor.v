//run_sv2v
`include "dec_monitor.sv"
`include "dr32e_pkg.sv"
module dec_monitor_v #(
    parameter NUM_TRANS = 10
    )(
        input                 clk_i,
        input                 rst_ni,
      
        // to/from controller
        input                 illegal_insn_o,        // illegal instr encountered
        input                 ebrk_insn_o,           // trap instr encountered
        input                 mret_insn_o,           // return from exception instr
                                                            // encountered
        input                 dret_insn_o,           // return from debug instr encountered
        input                 ecall_insn_o,          // syscall instr encountered
        input                 wfi_insn_o,            // wait for interrupt instr encountered
        input                 jump_set_o,            // jump taken set signal
        input                 branch_taken_i,        // registered branch decision
        input                 icache_inval_o,
      
        // from IF-ID pipeline register
        input                  instr_first_cycle_i,   // instruction read is in its first cycle
        input  [31:0]          instr_rdata_i,         // instruction read from memory/cache
        input  [31:0]          instr_rdata_alu_i,     // instruction read from memory/cache
                                                            // replicated to ease fan-out)
      
        input                  illegal_c_insn_i,      // compressed instruction decode failed
      
        // immediates
        input dr32e_pkg::imm_a_sel_e  imm_a_mux_sel_o,       // immediate selection for operand a
        input dr32e_pkg::imm_b_sel_e  imm_b_mux_sel_o,       // immediate selection for operand b
        input dr32e_pkg::op_a_sel_e   bt_a_mux_sel_o,        // branch target selection operand a
        input dr32e_pkg::imm_b_sel_e  bt_b_mux_sel_o,        // branch target selection operand b
        input [31:0]           imm_i_type_o,
        input [31:0]           imm_s_type_o,
        input [31:0]           imm_b_type_o,
        input [31:0]           imm_u_type_o,
        input [31:0]           imm_j_type_o,
        input [31:0]           zimm_rs1_type_o,
      
        // register file
        input dr32e_pkg::rf_wd_sel_e rf_wdata_sel_o,   // RF write data selection
        input                 rf_we_o,          // write enable for regfile
        input [4:0]           rf_raddr_a_o,
        input [4:0]           rf_raddr_b_o,
        input [4:0]           rf_waddr_o,
        input                 rf_ren_a_o,          // Instruction reads from RF addr A
        input                 rf_ren_b_o,          // Instruction reads from RF addr B
      
        // ALU
        input dr32e_pkg::alu_op_e    alu_operator_o,        // ALU operation selection
        input dr32e_pkg::op_a_sel_e  alu_op_a_mux_sel_o,    // operand a selection: reg value, PC,
                                                            // immediate or zero
        input dr32e_pkg::op_b_sel_e  alu_op_b_mux_sel_o,    // operand b selection: reg value or
                                                            // immediate
        input                 alu_multicycle_o,      // ternary bitmanip instruction
      
        // MULT & DIV
        input                 mult_en_o,             // perform integer multiplication
        input                 div_en_o,              // perform integer division or remainder
        input                 mult_sel_o,            // as above but static, for data muxes
        input                 div_sel_o,             // as above but static, for data muxes
      
        input dr32e_pkg::md_op_e     multdiv_operator_o,
        input [1:0]           multdiv_signed_mode_o,
      
        // CSRs
        input                 csr_access_o,          // access to CSR
        input dr32e_pkg::csr_op_e    csr_op_o,              // operation to perform on CSR
      
        // LSU
        input                 data_req_o,            // start transaction to data memory
        input                 data_we_o,             // write enable
        input [1:0]           data_type_o,           // size of transaction: byte, half
                                                            // word or word
        input                 data_sign_extension_o, // sign extension for data read from
                                                            // memory
      
        // jump/branches
        input                 jump_in_dec_o,         // jump is being calculated in ALU
        input                 branch_in_dec_o
    );

    dec_monitor #(
        .NUM_TRANS(NUM_TRANS)
    ) m0 (
        .clk_i (clk_i),
        .rst_ni (rst_ni),
        .illegal_insn_o(illegal_insn_o),
        .ebrk_insn_o(ebrk_insn_o),           // trap instr encountered
        .mret_insn_o(mret_insn_o),           // return from exception instr
                                                            // encountered
        .dret_insn_o(dret_insn_o),           // return from debug instr encountered
        .ecall_insn_o(ecall_insn_o),          // syscall instr encountered
        .wfi_insn_o(wfi_insn_o),           // wait for interrupt instr encountered
        .jump_set_o(jump_set_o),            // jump taken set signal
        .branch_taken_i(branch_taken_i),        // registered branch decision
        .icache_inval_o(icache_inval_o),
    
        // from IF-ID pipeline register
        .instr_first_cycle_i(instr_first_cycle_i),   // instruction read is in its first cycle
        .instr_rdata_i(instr_rdata_i),         // instruction read from memory/cache
        .instr_rdata_alu_i(instr_rdata_alu_i),     // instruction read from memory/cache
                                                            // replicated to ease fan-out)
    
        .illegal_c_insn_i(illegal_c_insn_i),      // compressed instruction decode failed
    
        // immediates
        .imm_a_mux_sel_o(imm_a_mux_sel_o),       // immediate selection for operand a
        .imm_b_mux_sel_o(imm_b_mux_sel_o),       // immediate selection for operand b
        .bt_a_mux_sel_o(bt_a_mux_sel_o),        // branch target selection operand a
        .bt_b_mux_sel_o(bt_b_mux_sel_o),       // branch target selection operand b
        .imm_i_type_o(imm_i_type_o),
        .imm_s_type_o(imm_s_type_o),
        .imm_b_type_o(imm_b_type_o),
        .imm_u_type_o(imm_u_type_o),
        .imm_j_type_o(imm_j_type_o),
        .zimm_rs1_type_o(zimm_rs1_type_o),
    
        // register file
        .rf_wdata_sel_o(rf_wdata_sel_o),   // RF write data selection
        .rf_we_o(rf_we_o),         // write enable for regfile
        .rf_raddr_a_o(rf_raddr_a_o),
        .rf_raddr_b_o(rf_raddr_b_o),
        .rf_waddr_o(rf_waddr_o),
        .rf_ren_a_o(rf_ren_a_o),          // Instruction reads from RF addr A
        .rf_ren_b_o(rf_ren_b_o),          // Instruction reads from RF addr B
    
        // ALU
        .alu_operator_o(alu_operator_o),        // ALU operation selection
        .alu_op_a_mux_sel_o(alu_op_a_mux_sel_o),    // operand a selection: reg value, PC,
                                                            // immediate or zero
        .alu_op_b_mux_sel_o(alu_op_b_mux_sel_o),    // operand b selection: reg value or
                                                            // immediate
        .alu_multicycle_o(alu_multicycle_o),      // ternary bitmanip instruction
    
        // MULT & DIV
        .mult_en_o(mult_en_o),             // perform integer multiplication
        .div_en_o(div_en_o),              // perform integer division or remainder
        .mult_sel_o(mult_sel_o),           // as above but static, for data muxes
        .div_sel_o(div_sel_o),             // as above but static, for data muxes
    
        .multdiv_operator_o(multdiv_operator_o),
        .multdiv_signed_mode_o(multdiv_signed_mode_o),
    
        // CSRs
        .csr_access_o(csr_access_o),          // access to CSR
        .csr_op_o(csr_op_o),              // operation to perform on CSR
    
        // LSU
        .data_req_o(data_req_o),           // start transaction to data memory
        .data_we_o(data_we_o),            // write enable
        .data_type_o(data_type_o),           // size of transaction: byte, half
                                                            // word or word
        .data_sign_extension_o(data_sign_extension_o), // sign extension for data read from
                                                            // memory
    
        // jump/branches
        .jump_in_dec_o(jump_in_dec_o),         // jump is being calculated in ALU
        .branch_in_dec_o(branch_in_dec_o)
   
    );
endmodule