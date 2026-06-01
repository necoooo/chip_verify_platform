// DSP运算核心 — 8位加减法算术单元
//
// 操作：
//   op_sel_i=0 → result = opa + opb (9位含进位)
//   op_sel_i=1 → result = opa - opb (9位含借位)
// 状态机：三段式结构（状态寄存器 + 下一状态逻辑 + 输出寄存器）

module dsp_core (
  input  wire       clk_i,
  input  wire       rst_ni,

  input  wire [7:0] opa_i,            // 操作数A
  input  wire [7:0] opb_i,            // 操作数B
  input  wire       op_sel_i,         // 0=ADD, 1=SUB
  input  wire       start_i,          // 启动运算

  output wire [8:0] result_o,         // 运算结果（9位含进位/借位）
  output reg        busy_o,           // 运算进行中
  output reg        done_o            // 运算完成脉冲
);

  // 状态定义
  localparam [0:0] S_IDLE = 1'd0;
  localparam [0:0] S_BUSY = 1'd1;

  // 状态寄存器
  reg [0:0] curr_state;
  reg [0:0] next_state;

  // 数据通路寄存器
  reg [8:0] result_q;
  reg       start_q;                  // 打拍start信号（边沿检测）

  wire [8:0] add_result;
  wire [8:0] sub_result;

  assign add_result = {1'b0, opa_i} + {1'b0, opb_i};
  assign sub_result = {1'b0, opa_i} - {1'b0, opb_i};
  assign result_o   = result_q;

  // start边沿检测
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      start_q <= 1'b0;
    end else begin
      start_q <= start_i;
    end
  end

  // ========================================================================
  // Block 1: 状态转移时序逻辑
  // ========================================================================
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      curr_state <= S_IDLE;
    end else begin
      curr_state <= next_state;
    end
  end

  // ========================================================================
  // Block 2: 下一状态组合逻辑
  // ========================================================================
  always @(*) begin
    next_state = curr_state;

    case (curr_state)
      S_IDLE: begin
        if (start_i && !start_q) begin
          next_state = S_BUSY;
        end
      end

      S_BUSY: begin
        next_state = S_IDLE;
      end

      default: next_state = S_IDLE;
    endcase
  end

  // ========================================================================
  // Block 3: 输出时序逻辑（寄存器输出，避免毛刺）
  // ========================================================================
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      busy_o    <= 1'b0;
      done_o    <= 1'b0;
      result_q  <= 9'd0;
    end else begin
      // 默认值
      done_o <= 1'b0;

      case (curr_state)
        S_IDLE: begin
          busy_o <= 1'b0;
        end

        S_BUSY: begin
          busy_o   <= 1'b0;           // 单周期运算，下一拍即完成
          result_q <= op_sel_i ? sub_result : add_result;
          done_o   <= 1'b1;
        end

        default: begin
          busy_o <= 1'b0;
          done_o <= 1'b0;
        end
      endcase
    end
  end

endmodule
