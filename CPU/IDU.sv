`include "para.sv"

module IDU(
    input clock,
    input reset,

    input [31:0] inst,
    input [31:0] snpc,
    input [31:0] pc,

    input [31:0] rd_value,
    input [31:0] csrd,
    input [4:0] rd,
    input R_wen,
    input [3:0] csr_wen,

    input [31:0] EXU_rs1_in,
    input [31:0] EXU_rs2_in,

    output [4:0] rd_next,
    output [2:0] funct3,
    output mret_flag,
    output ecall_flag,
    output fence_i_flag,

    output [31:0] branch_pc,
    output [31:0] rs1_value,
    output [31:0] rs2_value,

    output [31:0] add1_value,
    output [31:0] add2_value,
    output [3:0] csr_wen_next,
    output R_wen_next,
    output [31:0] rd_value_next,

    output mem_wen,
    output mem_ren,
    output inv_flag,
    output branch_flag,
    output jump_flag,

    output [3:0] alu_opcode,

    output [4:0] rs1,
    output [4:0] rs2,
    output [31:0] a0_value,
    output [31:0] mepc_out,
    output [31:0] mtvec_out,
    output [31:0] pc_out,

    input valid_last,
    output ready_last,

    input ready_next,
    output valid_next
);

    logic [31:0] csr_addr;
    logic [6:0] oprand;
    logic [6:0] opcode;

    logic [31:0] imm_I;
    logic [31:0] imm_U;
    logic [31:0] imm_R;
    logic [31:0] imm_S;
    logic [31:0] imm_B;
    logic [31:0] imm_J;
    logic [31:0] csrs;
    logic [31:0] imm;

    assign ready_last = ready_next;
    assign valid_next = valid_last;

    assign oprand = inst[31:25];
    assign opcode = inst[6:0];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign funct3 = inst[14:12];
    assign rd_next = inst[11:7];

    assign ecall_flag = (inst == 32'b00000000000000000000000001110011);//ecall
    assign mret_flag = (inst == 32'b00110000001000000000000001110011);// mret
    assign fence_i_flag = (inst == 32'b00000000000000000001000000001111);

    assign csr_wen_next[0] = (opcode == `M_opcode && imm == 32'h341);
    assign csr_wen_next[1] = (opcode == `M_opcode && imm == 32'h342);
    assign csr_wen_next[2] = (opcode == `M_opcode && imm == 32'h300);
    assign csr_wen_next[3] = (opcode == `M_opcode && imm == 32'h305);

    assign R_wen_next = (opcode == `S_opcode || opcode == `B_opcode || opcode == 0)? 1'b0:1'b1;
    assign mem_wen = (opcode == `S_opcode);
    assign mem_ren = (opcode == `lw);

    assign jump_flag = (opcode == `jarl || opcode == `jal)? 1'b1:1'b0;

    assign inv_flag = (opcode == `B_opcode && (funct3 == 3'b101 || funct3 == 3'b111 || funct3 == 3'b000 ))? 1'b1:1'b0;
    assign branch_flag = (opcode == `B_opcode)? 1'b1:1'b0;

    assign csr_addr = imm;

    assign rd_value_next = jump_flag? snpc:
        (|csr_wen_next)? csrs:
        0;
    assign branch_pc = pc + imm;
    assign pc_out = pc;

    assign add1_value = (opcode == `lui)? 0 :
        (opcode == `jal || opcode == `auipc )? pc :
        EXU_rs1_in;

    assign add2_value = (opcode == `R_opcode || opcode == `B_opcode)? EXU_rs2_in :
        (opcode == `M_opcode && funct3 == 3'b010)? rd_value_next :
        (opcode == `M_opcode && funct3 == 3'b001)? 0 : imm;

    assign alu_opcode = (opcode == `S_opcode || opcode == `lw
        || opcode == `lui || opcode == `auipc
        || opcode == `jal || opcode == `jarl
        || (opcode ==`addi && funct3 == 3'b000) || (opcode == `R_opcode &&
        funct3 == 3'b000 && oprand[5] == 1'b0) || (opcode == `B_opcode &&
        funct3[2:1] == 2'b01))?
        `alu_add : (opcode == `addi && funct3 == 3'b010) ||
        (opcode == `R_opcode && funct3 == 3'b010) ||
        (opcode == `B_opcode && (funct3 == 3'b101 || funct3 == 3'b100))?
        `alu_signed_comparator:
        (opcode == `B_opcode && (funct3 == 3'b110 || funct3 == 3'b111)) ||
        (opcode == `addi && (funct3 == 3'b011)) ||
        (opcode == `R_opcode && (funct3 == 3'b011))?
        `alu_unsigned_comparator:
        (opcode == `addi && funct3 == 3'b100 ) ||
        (opcode == `R_opcode && funct3 == 3'b100 )?
        `alu_xor : (opcode == `addi && funct3 == 3'b110 ) ||
        (opcode == `R_opcode && funct3 == 3'b110 ) ||
        (opcode == `M_opcode && funct3 == 3'b010 )?
        `alu_or : (opcode == `addi && funct3 == 3'b111 ) ||
        (opcode == `R_opcode && funct3 == 3'b111 )?
        `alu_and : (opcode == `addi && funct3 == 3'b001 ) ||
        (opcode == `R_opcode && funct3 == 3'b001 )?
        `alu_sll : (opcode == `addi && funct3 == 3'b101 && oprand[5] == 1'b0) ||
        (opcode == `R_opcode && funct3 == 3'b101 && oprand[5] == 1'b0)?
        `alu_srl : (opcode == `addi && funct3 == 3'b101 && oprand[5] == 1'b1) ||
        (opcode == `R_opcode && funct3 == 3'b101 && oprand[5] == 1'b1)?
        `alu_sra : (opcode == `R_opcode && funct3 == 3'b000 && oprand[5] == 1'b1)?
        `alu_sub : (opcode == `B_opcode && funct3[2:1] == 2'b00)?
        `alu_equal:`alu_add;

    assign imm_I = {{20{inst[31]}},inst[31:20]};
    assign imm_U = {inst[31:12],12'd0};
    assign imm_R = {25'd0,inst[31:25]};
    assign imm_S = {{20{inst[31]}},inst[31:25],inst[11:7]};
    assign imm_B = {imm_S[31:11],imm_S[0],imm_S[10:1]}<<1;
    assign imm_J = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21]}<<1;
/* verilator lint_off IMPLICIT */

    assign imm = (opcode == `lw || opcode == `addi || opcode == `jarl || opcode == `M_opcode)? imm_I:
        (opcode == `lui || opcode == `auipc)? imm_U:
        (opcode == `jal)? imm_J:
        (opcode == `B_opcode)? imm_B:
        (opcode == `S_opcode)? imm_S:
        (opcode == `S_opcode)? imm_R :
        0;

Reg_Stack Reg_Stack_inst0(
    .reset(reset),
    .clock(clock),
    .pc(pc),
    .ecall_flag(ecall_flag),

    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .rd_value(rd_value),

    .csr_addr(csr_addr),
    .R_wen(R_wen),
    .csr_wen(csr_wen),
    .csrd(csrd),

    .rs1_value(rs1_value),
    .rs2_value(rs2_value),
    .a0_value(a0_value),
    .csrs(csrs),
    .mepc_out(mepc_out),
    .mtvec_out(mtvec_out)
);

endmodule

