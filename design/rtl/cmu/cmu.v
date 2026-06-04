// 时钟管理单元 (CMU) — Clock Management Unit
//
// 功能：双时钟源无毛刺切换
//   - rch_clk: 内部RC振荡器 16MHz
//   - pll_clk: PLL输出 50MHz（上电默认）
// 切换策略：先关后开（Gate off current → Switch → Gate on new）
// AHB寄存器：0x5000_0000 CMU_CLK_SEL, 0x5000_0004 CMU_STATUS
// 状态机：三段式结构（状态寄存器 + 下一状态逻辑 + 输出寄存器）
// V1.2: FSM时钟改用pll_clk_i(始终运行), 修复时钟切换时hclk停振导致FSM卡死

module cmu (
  input  wire       rch_clk_i,        // 内部RC振荡器 16MHz
  input  wire       pll_clk_i,        // PLL输出 50MHz
  output wire       hclk_o,           // 主时钟输出

  // AHB从机接口
  input  wire       hsel_i,
  input  wire [31:0] haddr_i,
  input  wire       hwrite_i,
  input  wire [1:0] htrans_i,
  input  wire [31:0] hwdata_i,
  output wire [31:0] hrdata_o,
  output wire       hready_o,
  output wire [1:0] hresp_o
);

  // 状态定义
  localparam [1:0] S_IDLE     = 2'd0;
  localparam [1:0] S_GATE_OFF = 2'd1;
  localparam [1:0] S_SWITCH   = 2'd2;
  localparam [1:0] S_GATE_ON  = 2'd3;

  // 状态寄存器
  reg [1:0] curr_state;
  reg [1:0] next_state;

  // 时钟选择与控制
  reg       clk_sel;             // 0=pll, 1=rch
  reg       clk_sel_req;         // 时钟切换请求
  reg       gate_pll;            // pll门控
  reg       gate_rch;            // rch门控
  reg [3:0] switch_cnt;          // 切换计数器

  wire      ahb_active;
  wire      pll_gated, rch_gated;

  assign ahb_active = hsel_i && (htrans_i == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  assign pll_gated = pll_clk_i & gate_pll;
  assign rch_gated = rch_clk_i & gate_rch;
  assign hclk_o = clk_sel ? rch_gated : pll_gated;

  // ========================================================================
  // 上电初始化（默认选择pll_clk, 50MHz）
  // ========================================================================
  initial begin
    curr_state  = S_IDLE;
    clk_sel     = 1'b0;
    clk_sel_req = 1'b0;
    gate_pll    = 1'b1;
    gate_rch    = 1'b0;
    switch_cnt  = 4'd0;
  end

  // ========================================================================
  // Block 1: 状态转移时序逻辑 (pll_clk_i域, 始终运行)
  // ========================================================================
  always @(posedge pll_clk_i) begin
    curr_state <= next_state;
  end

  // ========================================================================
  // Block 2: 下一状态组合逻辑
  // ========================================================================
  always @(*) begin
    next_state = curr_state;

    case (curr_state)
      S_IDLE: begin
        if (clk_sel_req) begin
          next_state = S_GATE_OFF;
        end
      end

      S_GATE_OFF: begin
        if (switch_cnt == 4'd3) begin
          next_state = S_SWITCH;
        end
      end

      S_SWITCH: begin
        next_state = S_GATE_ON;
      end

      S_GATE_ON: begin
        if (switch_cnt == 4'd3) begin
          next_state = S_IDLE;
        end
      end

      default: next_state = S_IDLE;
    endcase
  end

  // ========================================================================
  // Block 3: 输出和数据通路逻辑 (pll_clk_i域, 始终运行)
  // ========================================================================
  always @(posedge pll_clk_i) begin
    case (curr_state)
      S_IDLE: begin
        switch_cnt <= 4'd0;
        // AHB写触发切换请求
        if (ahb_active && hwrite_i && haddr_i[3:0] == 4'h0) begin
          clk_sel_req <= hwdata_i[0];
        end
      end

      S_GATE_OFF: begin
        if (clk_sel) gate_rch <= 1'b0;
        else         gate_pll <= 1'b0;
        switch_cnt <= switch_cnt + 4'd1;
      end

      S_SWITCH: begin
        clk_sel    <= clk_sel_req;
        switch_cnt <= 4'd0;
      end

      S_GATE_ON: begin
        if (clk_sel_req) gate_rch <= 1'b1;
        else             gate_pll <= 1'b1;
        switch_cnt <= switch_cnt + 4'd1;
        if (switch_cnt == 4'd3) begin
          clk_sel_req <= 1'b0;
        end
      end

      default: ;
    endcase
  end

  // AHB读数据
  assign hrdata_o = (haddr_i[3:0] == 4'h0) ? {31'h0, clk_sel} :
                    (haddr_i[3:0] == 4'h4) ? {31'h0, clk_sel} :
                    32'h0;

endmodule
