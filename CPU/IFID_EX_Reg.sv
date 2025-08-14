`include "para.sv"

module IFID_EX_Reg(
    input clock,
    input reset,
    input EXU_inst_clr,

    // Control signals
    input valid_last,
    input ready_last,
    input ready_next,
    output logic valid_next,

    // Data inputs from IDU
    input [2:0] funct3,
    input [3:0] csr_wen,
    input R_wen,
    input mem_wen,
    input mem_ren,
    input [4:0] rd,
    input [31:0] pc,
    input [3:0] alu_opcode,
    input inv_flag,
    input jump_flag,
    input branch_flag,
    input fetch_i_flag,
    input [31:0] branch_pc,
    input [31:0] rs2_value,
    input [31:0] add1,
    input [31:0] add2,
    input [31:0] rd_value,

    // Data outputs to EXU
    output logic [2:0] funct3_reg,
    output logic [3:0] csr_wen_reg,
    output logic R_wen_reg,
    output logic mem_wen_reg,
    output logic mem_ren_reg,
    output logic [4:0] rd_reg,
    output logic [31:0] pc_reg,
    output logic [3:0] alu_opcode_reg,
    output logic inv_flag_reg,
    output logic jump_flag_reg,
    output logic branch_flag_reg,
    output logic fetch_i_reg,
    output logic [31:0] branch_pc_reg,
    output logic [31:0] rs2_value_reg,
    output logic [31:0] add1_reg,
    output logic [31:0] add2_reg,
    output logic [31:0] rd_value_reg
);

    // ͳһʹ�� ready_next �ź�
    always @(posedge clock) begin
        if(reset)
            valid_next <= 1'b0;
        else if(valid_last & ready_next & EXU_inst_clr)
            valid_next <= 1'b0;
        else if(valid_last & ready_next)
            valid_next <= 1'b1;
        else
            valid_next <= 1'b0;
    end

    always @(posedge clock) begin
        if(reset)begin
            funct3_reg      <= 0;
            rd_reg          <= 0;
            alu_opcode_reg  <= 0;
            inv_flag_reg    <= 0;
            rs2_value_reg   <= 0;
            add1_reg        <= 0;
            add2_reg        <= 0;
            rd_value_reg    <= 0;
            branch_pc_reg   <= 0;
            pc_reg          <= 0;
        end
        else if(valid_last & ready_next)
        begin
            funct3_reg      <= funct3;
            rd_reg          <= rd;
            alu_opcode_reg  <= alu_opcode;
            inv_flag_reg    <= inv_flag;
            rs2_value_reg   <= rs2_value;
            add1_reg        <= add1;
            add2_reg        <= add2;
            rd_value_reg    <= rd_value;
            branch_pc_reg   <= branch_pc;
            pc_reg          <= pc;
        end
    end

    always @(posedge clock) begin
        if(reset)begin
            mem_ren_reg     <= 0;
            csr_wen_reg     <= 0;
            R_wen_reg       <= 0;
            mem_wen_reg     <= 0;
            jump_flag_reg   <= 0;
            branch_flag_reg <= 0;
            fetch_i_reg     <= 0;
        end
        else if(valid_last & ready_next & EXU_inst_clr)begin
            mem_ren_reg     <= 0;
            csr_wen_reg     <= 0;
            R_wen_reg       <= 0;
            mem_wen_reg     <= 0;
            jump_flag_reg   <= 0;
            branch_flag_reg <= 0;
            fetch_i_reg     <= 0;
        end
        else if(valid_last & ready_next) begin
            mem_ren_reg     <= mem_ren;
            csr_wen_reg     <= csr_wen;
            R_wen_reg       <= R_wen;
            mem_wen_reg     <= mem_wen;
            jump_flag_reg   <= jump_flag;
            branch_flag_reg <= branch_flag;
            fetch_i_reg     <= fetch_i_flag;
        end
    end

endmodule
