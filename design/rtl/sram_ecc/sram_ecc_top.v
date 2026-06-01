// SRAM_ECC顶层模块 — 集成AHB接口、ECC编解码器与SRAM存储阵列
//
// 功能：256×32bit存储，SEC-DED (39,32)扩展汉明码保护，AHB读写

module sram_ecc_top (
  input  wire       clk_i,
  input  wire       rst_ni,

  // AHB从机接口
  input  wire       hsel_i,
  input  wire [31:0] haddr_i,
  input  wire       hwrite_i,
  input  wire [1:0] htrans_i,
  input  wire [31:0] hwdata_i,
  output wire [31:0] hrdata_o,
  output wire       hready_o,
  output wire [1:0] hresp_o,

  // ECC状态
  output wire       ecc_err_o,
  output wire       ecc_sec_o,
  output wire       ecc_ded_o
);

  // 内部信号
  wire        wr_en;
  wire [7:0]  wr_addr;
  wire [38:0] wr_data;
  wire [7:0]  rd_addr;
  wire [38:0] rd_raw;
  wire [31:0] rd_corrected;
  wire        rd_single_err;
  wire        rd_double_err;

  // 寄存器接口
  sram_ecc_regif u_regif (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .hsel_i   (hsel_i),
    .haddr_i  (haddr_i),
    .hwrite_i (hwrite_i),
    .htrans_i (htrans_i),
    .hwdata_i (hwdata_i),
    .hrdata_o (hrdata_o),
    .hready_o (hready_o),
    .hresp_o  (hresp_o),
    .wr_en_o    (wr_en),
    .wr_addr_o  (wr_addr),
    .wr_data_o  (wr_data),
    .rd_addr_o  (rd_addr),
    .rd_data_i  (rd_corrected),
    .rd_single_err_i(rd_single_err),
    .rd_double_err_i(rd_double_err),
    .ecc_err_o  (ecc_err_o),
    .ecc_sec_o  (ecc_sec_o),
    .ecc_ded_o  (ecc_ded_o),
    .ecc_err_cnt_o (),
    .ecc_err_addr_o(),
    .ecc_inject_en_o()
  );

  // SRAM存储阵列
  sram_ecc_mem u_mem (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .wr_en_i  (wr_en),
    .wr_addr_i(wr_addr),
    .wr_data_i(wr_data),
    .rd_addr_i(rd_addr),
    .rd_data_o(rd_raw)
  );

  // ECC解码器
  sram_ecc_decode u_decode (
    .codeword_i (rd_raw),
    .data_o       (rd_corrected),
    .single_err_o (rd_single_err),
    .double_err_o (rd_double_err)
  );

endmodule
