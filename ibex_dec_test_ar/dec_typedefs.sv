
package dec_typedefs;

typedef enum logic [6:0]{
    JUMP_OP = 'h6F,
    BRANCH_OP = 'h63,
    LOAD_OP = 'h3,
    ITYPE_OP = 'h13,
    STORE_OP = 'h23,
    UTYPE_OP = 'h37
} op_e;

typedef enum logic [31:0]{
    ILLEGAL =  32'h0FFFFFFF,
    JUMP =  32'hD90006F,
    BRANCH =  32'h6000063,
    WFI =  32'h10500073,
    ECALL =  32'h73,
    EBREAK =  32'h100073,
    DEBUG =  32'h7B200073,
    MRET =  32'h30200073,
    STORE =  32'h18023,
    UTYPE =  32'h307037,
    ITYPE =  32'hE000C113,
    LOAD  =  32'hFFFFFFE3
} instr_type_e;

endpackage