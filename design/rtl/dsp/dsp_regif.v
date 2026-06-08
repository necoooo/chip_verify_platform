// DSP寄存器接口 — AHB从机总线接口与寄存器组
//
// 寄存器映射：
//   0x00: DSP_OPA    — 操作数A
//   0x04: DSP_OPB    — 操作数B
//   0x08: DSP_CTRL   — 控制寄存器
//   0x0C: DSP_RESULT — 运算结果
//   0x10: DSP_STATUS — 状态寄存器
// V1.1: 修复done_latch误清除(添加ahb_active+hwrite条件)

module dsp_regif (
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
  output wire [7:0] opa_o,
  output wire [7:0] opb_o,
  output wire       op_sel_o,
  output wire       start_o,

  // 运算结果
  input  wire [8:0] result_i,
  input  wire       busy_i,
  input  wire       done_i
);

  // 寄存器
  reg [7:0] opa_d, opa_q;
  reg [7:0] opb_d, opb_q;
  reg       op_sel_d, op_sel_q;
  reg       start_d, start_q;
  reg       done_latch_q;  // done锁存（读后清零）

  wire ahb_active;
  assign ahb_active = hsel_i && (htrans_i == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  assign opa_o    = opa_q;
  assign opb_o    = opb_q;
  assign op_sel_o = op_sel_q;
  assign start_o  = start_q;

  // done锁存
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      done_latch_q <= 1'b0;
    end else begin
      if (done_i) begin
        done_latch_q <= 1'b1;
      // V1.1: 仅AHB读STATUS时清除, 避免空闲/写周期误清除
      end else if (ahb_active && !hwrite_i && haddr_i[3:0] == 4'h10) begin
        done_latch_q <= 1'b0;
      end
    end
  end

  always @(*) begin
    opa_d    = opa_q;
    opb_d    = opb_q;
    op_sel_d = op_sel_q;
    start_d  = 1'b0;

    if (hwrite_i) begin
      case (haddr_i[3:0])
        4'h0: opa_d = hwdata_i[7:0];
        4'h4: opb_d = hwdata_i[7:0];
        4'h8: begin
          start_d  = hwdata_i[0];
          op_sel_d = hwdata_i[1];
        end
        default: ;
      endcase
    end
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      opa_q    <= 8'd0;
      opb_q    <= 8'd0;
      op_sel_q <= 1'b0;
      start_q  <= 1'b0;
    end else begin
      opa_q    <= opa_d;
      opb_q    <= opb_d;
      op_sel_q <= op_sel_d;
      start_q  <= start_d;
    end
  end

  assign hrdata_o = (haddr_i[3:0] == 4'h0)  ? {24'h0, opa_q} :
                    (haddr_i[3:0] == 4'h4)  ? {24'h0, opb_q} :
                    (haddr_i[3:0] == 4'h8)  ? {30'h0, op_sel_q, start_q} :
                    (haddr_i[3:0] == 4'hC)  ? {23'h0, result_i} :
                    (haddr_i[3:0] == 4'h10) ? {30'h0, done_latch_q, busy_i} :
                    32'h0;

endmodule
