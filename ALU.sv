`include "para.sv"
`timescale 1ns / 1ps

// �Ƴ�����Ҫ��clock����
module ALU #(
    parameter BW = 32    
)
(
    input [BW-1: 0] d1,
    input [BW-1: 0] d2,
    input [3: 0] choice,
    output logic [BW-1: 0] result
);

    // Ԥ�����Լ��ٹؼ�·��
    logic [BW-1: 0] d2_inv;
    logic [BW-1: 0] add_result;
    logic [BW-1: 0] sub_result;
    logic [BW-1: 0] and_result;
    logic [BW-1: 0] or_result;
    logic [BW-1: 0] xor_result;
    logic [BW-1: 0] sll_result;
    logic [BW-1: 0] srl_result;
    logic [BW-1: 0] sra_result;
    
    // �ȽϽ��
    logic signed_lt;
    logic unsigned_lt;
    logic equal;
    
    assign d2_inv = ~d2;
    
    // ���м����������
    assign and_result = d1 & d2;
    assign or_result  = d1 | d2;
    assign xor_result = d1 ^ d2;
    assign sll_result = d1 << d2[4:0];
    assign srl_result = d1 >> d2[4:0];
    assign sra_result = $signed(d1) >>> d2[4:0];
    
    // �Ż��Ƚ��߼�
    assign signed_lt = $signed(d1) < $signed(d2);
    assign unsigned_lt = d1 < d2;
    assign equal = (d1 != d2);

    // ʹ��addģ����мӼ���
    add #(
        .BW(BW)
    ) add_inst0 (
        .choose_add_sub(choice == `alu_sub),
        .add_1(d1),
        .add_2(d2),
        .add_2_inv(d2_inv),
        .result(add_result)
    );
    
    assign sub_result = add_result;  // �Ӽ�����ͨ��addģ��

    // �Ż���caseѡ���߼�
    always@(*) begin
        case(choice)
            `alu_signed_comparator:   result = {31'b0, signed_lt};
            `alu_unsigned_comparator: result = {31'b0, unsigned_lt};
            `alu_add:                 result = add_result;
            `alu_sub:                 result = sub_result;
            `alu_and:                 result = and_result;
            `alu_or:                  result = or_result;
            `alu_xor:                 result = xor_result;
            `alu_equal:               result = {31'b0, equal};
            `alu_sll:                 result = sll_result;
            `alu_srl:                 result = srl_result;
            `alu_sra:                 result = sra_result;
            default:                  result = 32'b0;
        endcase
    end
endmodule