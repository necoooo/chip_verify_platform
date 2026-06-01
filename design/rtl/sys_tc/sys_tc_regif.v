// SYS_TC寄存器接口 — AHB从机总线接口与寄存器组
//
// 寄存器映射：
//   0x00: TC_CTRL   — 控制寄存器
//   0x04: TC_LOAD   — 重载值寄存器
//   0x08: TC_COUNT  — 当前计数值（只读）
//   0x0C: TC_STATUS — 状态寄存器（中断标志，写1清零）

module sys_tc_regif (
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

  // 控制输出
  output wire       en_o,
  output wire       ie_o,
  output wire [31:0] reload_o,

  // 计数器状态
  input  wire [31:0] count_i,
  output wire       int_flag_clr_o,
  input  wire       int_flag_i
);

  reg       en_d, en_q;
  reg       ie_d, ie_q;
  reg [31:0] reload_d, reload_q;
  reg       int_flag_clr;

  wire ahb_active;
  assign ahb_active = hsel_i && (htrans_i == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  assign en_o           = en_q;
  assign ie_o           = ie_q;
  assign reload_o       = reload_q;
  assign int_flag_clr_o = int_flag_clr;

  always @(*) begin
    en_d     = en_q;
    ie_d     = ie_q;
    reload_d = reload_q;

    if (hwrite_i) begin
      case (haddr_i[3:0])
        4'h0: begin
          en_d = hwdata_i[0];
          ie_d = hwdata_i[1];
        end
        4'h4: reload_d = hwdata_i;
        default: ;
      endcase
    end

    int_flag_clr = hwrite_i && (haddr_i[3:0] == 4'hC) && hwdata_i[0];
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      en_q     <= 1'b0;
      ie_q     <= 1'b0;
      reload_q <= 32'd49999;
    end else begin
      en_q     <= en_d;
      ie_q     <= ie_d;
      reload_q <= reload_d;
    end
  end

  assign hrdata_o = (haddr_i[3:0] == 4'h0) ? {30'h0, ie_q, en_q} :
                    (haddr_i[3:0] == 4'h4) ? reload_q :
                    (haddr_i[3:0] == 4'h8) ? count_i :
                    (haddr_i[3:0] == 4'hC) ? {31'h0, int_flag_i} :
                    32'h0;

endmodule
