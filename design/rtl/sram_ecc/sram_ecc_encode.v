// SRAM_ECC编码器 — (39,32)扩展汉明码编码
//
// 32位数据 → 7位ECC校验位（6位SEC + 1位全局偶校验）
// 采用标准Hamming码：校验位覆盖对应位置bit为1的所有数据位

module sram_ecc_encode (
  input  wire [31:0] data_i,          // 32位输入数据
  output wire [6:0]  ecc_o            // 7位ECC输出 [6]=p0(全局), [5:0]=p[6:1](SEC)
);

  // 数据位在码字中的位置（1-indexed，非2的幂位置）
  // d[0]→pos3, d[1]→pos5, d[2]→pos6, ..., d[31]→pos38
  reg [5:0] p;

  // 校验位p[1] (位置1, bit0=1): 覆盖位置bit0=1的数据位
  assign p[0] = data_i[0]  ^ data_i[1]  ^ data_i[3]  ^ data_i[4]  ^
                data_i[6]  ^ data_i[8]  ^ data_i[10] ^ data_i[11] ^
                data_i[13] ^ data_i[15] ^ data_i[17] ^ data_i[19] ^
                data_i[21] ^ data_i[23] ^ data_i[25] ^ data_i[26] ^
                data_i[28] ^ data_i[30];

  // 校验位p[2] (位置2, bit1=1): 覆盖位置bit1=1的数据位
  assign p[1] = data_i[0]  ^ data_i[2]  ^ data_i[3]  ^ data_i[5]  ^
                data_i[6]  ^ data_i[9]  ^ data_i[10] ^ data_i[12] ^
                data_i[13] ^ data_i[16] ^ data_i[17] ^ data_i[20] ^
                data_i[21] ^ data_i[24] ^ data_i[25] ^ data_i[27] ^
                data_i[28] ^ data_i[31];

  // 校验位p[3] (位置4, bit2=1)
  assign p[2] = data_i[1]  ^ data_i[2]  ^ data_i[3]  ^ data_i[7]  ^
                data_i[8]  ^ data_i[9]  ^ data_i[10] ^ data_i[14] ^
                data_i[15] ^ data_i[16] ^ data_i[17] ^ data_i[22] ^
                data_i[23] ^ data_i[24] ^ data_i[25] ^ data_i[29] ^
                data_i[30] ^ data_i[31];

  // 校验位p[4] (位置8, bit3=1)
  assign p[3] = data_i[4]  ^ data_i[5]  ^ data_i[6]  ^ data_i[7]  ^
                data_i[8]  ^ data_i[9]  ^ data_i[10] ^ data_i[18] ^
                data_i[19] ^ data_i[20] ^ data_i[21] ^ data_i[22] ^
                data_i[23] ^ data_i[24] ^ data_i[25];

  // 校验位p[5] (位置16, bit4=1)
  assign p[4] = data_i[11] ^ data_i[12] ^ data_i[13] ^ data_i[14] ^
                data_i[15] ^ data_i[16] ^ data_i[17] ^ data_i[18] ^
                data_i[19] ^ data_i[20] ^ data_i[21] ^ data_i[22] ^
                data_i[23] ^ data_i[24] ^ data_i[25];

  // 校验位p[6] (位置32, bit5=1)
  assign p[5] = data_i[26] ^ data_i[27] ^ data_i[28] ^ data_i[29] ^
                data_i[30] ^ data_i[31];

  // 全局偶校验 p0 = XOR of all 32 data bits and 6 SEC check bits
  wire p0;
  assign p0 = (^data_i) ^ (^p);

  assign ecc_o = {p0, p};

endmodule
