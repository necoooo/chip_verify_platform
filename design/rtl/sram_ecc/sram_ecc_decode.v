// SRAM_ECC解码器 — (39,32)扩展汉明码解码与纠错
//
// 功能：
//   - 重新计算ECC校验位并与存储值比较得到syndrome
//   - syndrome=0, p0_match → 无错误
//   - syndrome≠0, p0_mismatch → 单bit错（定位并翻转）
//   - syndrome≠0, p0_match → 双bit错（仅检测）

module sram_ecc_decode (
  input  wire [38:0] codeword_i,      // 39位码字 [38]=p0, [37:32]=p[6:1], [31:0]=data

  output wire [31:0] data_o,          // 纠错后数据
  output wire        single_err_o,    // 单bit错误已纠正
  output wire        double_err_o     // 双bit错误已检测
);

  wire       p0_stored;
  wire [5:0] p_stored;
  wire [31:0] data_stored;
  wire [6:0] ecc_calc;
  wire [5:0] syndrome;
  wire       p0_calc, p0_mismatch;
  reg [31:0] corrected;
  reg       is_single, is_double;

  assign p0_stored = codeword_i[38];
  assign p_stored  = codeword_i[37:32];
  assign data_stored = codeword_i[31:0];

  // 重新计算ECC
  sram_ecc_encode u_encode (
    .data_i(data_stored),
    .ecc_o (ecc_calc)
  );

  assign p0_calc    = ecc_calc[6];
  assign syndrome   = ecc_calc[5:0] ^ p_stored;
  assign p0_mismatch = p0_calc ^ p0_stored;

  // 错误判定
  always @(*) begin
    corrected = data_stored;
    is_single = 1'b0;
    is_double = 1'b0;

    if (syndrome == 6'd0) begin
      if (p0_mismatch) begin
        is_single = 1'b1;  // p0自身错误，数据正确
      end
    end else begin
      if (p0_mismatch) begin
        // 单bit错误：syndrome指示错误码字位置，翻转对应数据位
        is_single = 1'b1;
        case (syndrome)
          6'd3:  corrected[0]  = ~data_stored[0];
          6'd5:  corrected[1]  = ~data_stored[1];
          6'd6:  corrected[2]  = ~data_stored[2];
          6'd7:  corrected[3]  = ~data_stored[3];
          6'd9:  corrected[4]  = ~data_stored[4];
          6'd10: corrected[5]  = ~data_stored[5];
          6'd11: corrected[6]  = ~data_stored[6];
          6'd12: corrected[7]  = ~data_stored[7];
          6'd13: corrected[8]  = ~data_stored[8];
          6'd14: corrected[9]  = ~data_stored[9];
          6'd15: corrected[10] = ~data_stored[10];
          6'd17: corrected[11] = ~data_stored[11];
          6'd18: corrected[12] = ~data_stored[12];
          6'd19: corrected[13] = ~data_stored[13];
          6'd20: corrected[14] = ~data_stored[14];
          6'd21: corrected[15] = ~data_stored[15];
          6'd22: corrected[16] = ~data_stored[16];
          6'd23: corrected[17] = ~data_stored[17];
          6'd24: corrected[18] = ~data_stored[18];
          6'd25: corrected[19] = ~data_stored[19];
          6'd26: corrected[20] = ~data_stored[20];
          6'd27: corrected[21] = ~data_stored[21];
          6'd28: corrected[22] = ~data_stored[22];
          6'd29: corrected[23] = ~data_stored[23];
          6'd30: corrected[24] = ~data_stored[24];
          6'd31: corrected[25] = ~data_stored[25];
          6'd33: corrected[26] = ~data_stored[26];
          6'd34: corrected[27] = ~data_stored[27];
          6'd35: corrected[28] = ~data_stored[28];
          6'd36: corrected[29] = ~data_stored[29];
          6'd37: corrected[30] = ~data_stored[30];
          6'd38: corrected[31] = ~data_stored[31];
          default: ;  // 校验位错误，数据正确
        endcase
      end else begin
        is_double = 1'b1;  // 双bit错误，不可纠正
      end
    end
  end

  assign data_o       = corrected;
  assign single_err_o = is_single;
  assign double_err_o = is_double;

endmodule
