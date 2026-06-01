// DSP运算核心 — 8位加减法算术单元
//
// 操作：
//   op_sel_i=0 → result = opa + opb (9位含进位)
//   op_sel_i=1 → result = opa - opb (9位含借位)

module dsp_core (
  input  wire       clk_i,
  input  wire       rst_ni,

  input  wire [7:0] opa_i,            // 操作数A
  input  wire [7:0] opb_i,            // 操作数B
  input  wire       op_sel_i,         // 0=ADD, 1=SUB
  input  wire       start_i,          // 启动运算

  output wire [8:0] result_o,         // 运算结果（9位含进位/借位）
  output wire       busy_o,           // 运算进行中
  output wire       done_o            // 运算完成脉冲
);

  logic [8:0] add_result, sub_result;
  logic       busy_d, busy_q;
  logic       done_d, done_q;
  logic [8:0] result_d, result_q;
  logic       start_q;

  assign add_result = {1'b0, opa_i} + {1'b0, opb_i};
  assign sub_result = {1'b0, opa_i} - {1'b0, opb_i};

  assign result_o = result_q;
  assign busy_o   = busy_q;
  assign done_o   = done_q;

  // 打拍start信号
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      start_q <= 1'b0;
    end else begin
      start_q <= start_i;
    end
  end

  always_comb begin
    busy_d  = busy_q;
    done_d  = 1'b0;
    result_d = result_q;

    if (start_i && !start_q && !busy_q) begin
      busy_d = 1'b1;
    end else if (busy_q) begin
      result_d = op_sel_i ? sub_result : add_result;
      busy_d   = 1'b0;
      done_d   = 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      busy_q   <= 1'b0;
      done_q   <= 1'b0;
      result_q <= 9'd0;
    end else begin
      busy_q   <= busy_d;
      done_q   <= done_d;
      result_q <= result_d;
    end
  end

endmodule
