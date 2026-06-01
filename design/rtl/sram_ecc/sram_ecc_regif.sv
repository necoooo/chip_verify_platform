// SRAM_ECC寄存器接口 — AHB从机总线接口
//
// 地址空间：
//   0x000 - 0x3FC: SRAM数据空间（字地址 HADDR[9:2]，256字）
//   0x400: ECC_ERR_CNT
//   0x404: ECC_ERR_ADDR
//   0x408: ECC_CTRL（bit0: 错误注入使能）

module sram_ecc_regif (
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

  // SRAM控制
  output wire       wr_en_o,
  output wire [7:0] wr_addr_o,
  output wire [38:0] wr_data_o,
  output wire [7:0] rd_addr_o,

  // 读数据输入
  input  wire [31:0] rd_data_i,
  input  wire        rd_single_err_i,
  input  wire        rd_double_err_i,

  // ECC状态
  output wire       ecc_err_o,
  output wire       ecc_sec_o,
  output wire       ecc_ded_o,
  output wire [7:0] ecc_err_cnt_o,
  output wire [9:0] ecc_err_addr_o,
  output wire       ecc_inject_en_o
);

  logic       rd_req;
  logic       wr_req;
  logic [7:0] rd_addr_d, rd_addr_q;
  logic       ecc_inject_d, ecc_inject_q;
  logic [7:0] ecc_err_cnt_d, ecc_err_cnt_q;
  logic [9:0] ecc_err_addr_d, ecc_err_addr_q;

  wire ahb_active;
  assign ahb_active = hsel_i && (htrans_i == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  // 地址解析
  wire is_data_space;
  assign is_data_space = (haddr_i[11:10] == 2'b00);

  assign wr_addr_o = haddr_i[9:2];
  assign rd_addr_o = rd_addr_q;

  // 写请求
  assign wr_en_o = ahb_active && hwrite_i && is_data_space;
  assign wr_data_o = {sram_ecc_encode(hwdata_i), hwdata_i};

  // 读请求
  always_comb begin
    rd_addr_d = rd_addr_q;
    if (ahb_active && !hwrite_i && is_data_space) begin
      rd_addr_d = haddr_i[9:2];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_addr_q <= 8'd0;
    end else begin
      rd_addr_q <= rd_addr_d;
    end
  end

  // ECC状态更新
  always_comb begin
    ecc_err_cnt_d  = ecc_err_cnt_q;
    ecc_err_addr_d = ecc_err_addr_q;
    if (rd_single_err_i || rd_double_err_i) begin
      ecc_err_cnt_d  = ecc_err_cnt_q + 8'd1;
      ecc_err_addr_d = haddr_i[9:2];
    end
  end

  // 控制寄存器
  always_comb begin
    ecc_inject_d = ecc_inject_q;
    if (ahb_active && hwrite_i && !is_data_space && haddr_i[11:0] == 12'h408) begin
      ecc_inject_d = hwdata_i[0];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ecc_err_cnt_q  <= 8'd0;
      ecc_err_addr_q <= 10'd0;
      ecc_inject_q   <= 1'b0;
    end else begin
      ecc_err_cnt_q  <= ecc_err_cnt_d;
      ecc_err_addr_q <= ecc_err_addr_d;
      ecc_inject_q   <= ecc_inject_d;
    end
  end

  // ECC编码函数
  function automatic [6:0] sram_ecc_encode;
    input [31:0] data;
    logic [5:0] p;
    begin
      p[0] = data[0]  ^ data[1]  ^ data[3]  ^ data[4]  ^ data[6]  ^ data[8]  ^
             data[10] ^ data[11] ^ data[13] ^ data[15] ^ data[17] ^ data[19] ^
             data[21] ^ data[23] ^ data[25] ^ data[26] ^ data[28] ^ data[30];
      p[1] = data[0]  ^ data[2]  ^ data[3]  ^ data[5]  ^ data[6]  ^ data[9]  ^
             data[10] ^ data[12] ^ data[13] ^ data[16] ^ data[17] ^ data[20] ^
             data[21] ^ data[24] ^ data[25] ^ data[27] ^ data[28] ^ data[31];
      p[2] = data[1]  ^ data[2]  ^ data[3]  ^ data[7]  ^ data[8]  ^ data[9]  ^
             data[10] ^ data[14] ^ data[15] ^ data[16] ^ data[17] ^ data[22] ^
             data[23] ^ data[24] ^ data[25] ^ data[29] ^ data[30] ^ data[31];
      p[3] = data[4]  ^ data[5]  ^ data[6]  ^ data[7]  ^ data[8]  ^ data[9]  ^
             data[10] ^ data[18] ^ data[19] ^ data[20] ^ data[21] ^ data[22] ^
             data[23] ^ data[24] ^ data[25];
      p[4] = data[11] ^ data[12] ^ data[13] ^ data[14] ^ data[15] ^ data[16] ^
             data[17] ^ data[18] ^ data[19] ^ data[20] ^ data[21] ^ data[22] ^
             data[23] ^ data[24] ^ data[25];
      p[5] = data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30] ^ data[31];
      sram_ecc_encode = {(^data ^ ^p), p};
    end
  endfunction

  // 读数据多路复用
  assign hrdata_o = is_data_space         ? rd_data_i :
                    (haddr_i[11:0] == 12'h400) ? {24'h0, ecc_err_cnt_q} :
                    (haddr_i[11:0] == 12'h404) ? {22'h0, ecc_err_addr_q} :
                    (haddr_i[11:0] == 12'h408) ? {31'h0, ecc_inject_q} :
                    32'h0;

  // ECC状态输出
  assign ecc_err_o       = rd_single_err_i | rd_double_err_i;
  assign ecc_sec_o       = rd_single_err_i;
  assign ecc_ded_o       = rd_double_err_i;
  assign ecc_err_cnt_o   = ecc_err_cnt_q;
  assign ecc_err_addr_o  = ecc_err_addr_q;
  assign ecc_inject_en_o = ecc_inject_q;

endmodule
