// 时钟管理单元 (CMU) — Clock Management Unit
//
// 功能：双时钟源无毛刺切换
//   - rch_clk: 内部RC振荡器 16MHz
//   - pll_clk: PLL输出 50MHz（上电默认）
// 切换策略：先关后开（Gate off current → Switch → Gate on new）
// AHB寄存器：0x5000_0000 CMU_CLK_SEL, 0x5000_0004 CMU_STATUS
// 状态机：三段式结构（状态寄存器 + 下一状态逻辑 + 输出寄存器）
// V1.2: FSM时钟改用pll_clk_i(始终运行), 修复时钟切换时hclk停振导致FSM卡死
// V1.6: 门控negedge对齐 — 门控在时钟低电平时打开, 消除窄脉冲/毛刺,
//       pll同域negedge寄存器, rch经2-FF CDC同步至rch_clk_i域+negedge对齐

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
  reg       clk_sel_req;         // 目标时钟: 0=pll, 1=rch
  reg       clk_sw_pending;      // V1.5: 切换请求挂起(分离触发与数据)
  reg       gate_pll;            // pll门控
  reg       gate_rch;            // rch门控
  reg [3:0] switch_cnt;          // 切换计数器

  // V1.4: CDC 2-FF同步器 — AHB信号(hclk_o域) → pll_clk_i域
  // AHB信号随hclk_o变化(hclk_o可为16MHz或50MHz), FSM在pll_clk_i(50MHz)域
  // 直接采样会导致亚稳态; 2-FF同步器将MTBF降至可忽略水平
  // 关键: hwdata_i[0]与hwrite_i/haddr_i等控制信号同深度(2级)同步, 保证时序对齐
  //       控制信号的2级延迟值对应hwdata的2级延迟值, 不会采到过期数据
  reg        hsel_s1, hsel_s2;
  reg        hwrite_s1, hwrite_s2;
  reg [1:0]  htrans_s1, htrans_s2;
  reg [3:0]  haddr_lo_s1, haddr_lo_s2;
  reg        hwdata_s0, hwdata_s1;   // hwdata_i[0] 2-FF同步(与控制信号同深度)

  wire       ahb_active_sync;

  assign ahb_active_sync = hsel_s2 && (htrans_s2 == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  // V1.6: negedge对齐门控 — gate在时钟低电平时变化, 下一上升沿为完整半周期
  // pll: 同域, 单级negedge寄存器即消除窄脉冲
  // rch: 跨域(gate_rch来自pll_clk_i域), 2-FF同步至rch_clk_i域+negedge对齐
  reg gate_pll_n;                   // pll门控 negedge对齐
  reg gate_rch_s1, gate_rch_s2;    // rch门控 CDC 2-FF + negedge对齐

  always @(negedge pll_clk_i) begin
    gate_pll_n <= gate_pll;
  end

  always @(negedge rch_clk_i) begin
    gate_rch_s1 <= gate_rch;
    gate_rch_s2 <= gate_rch_s1;
  end

  wire pll_gated, rch_gated;
  assign pll_gated = pll_clk_i & gate_pll_n;
  assign rch_gated = rch_clk_i & gate_rch_s2;
  assign hclk_o = clk_sel ? rch_gated : pll_gated;

  // CDC同步器链: 所有AHB输入信号统一2-FF同步(pll_clk_i域)
  always @(posedge pll_clk_i) begin
    hsel_s1      <= hsel_i;
    hsel_s2      <= hsel_s1;
    hwrite_s1    <= hwrite_i;
    hwrite_s2    <= hwrite_s1;
    htrans_s1    <= htrans_i;
    htrans_s2    <= htrans_s1;
    haddr_lo_s1  <= haddr_i[3:0];
    haddr_lo_s2  <= haddr_lo_s1;
    hwdata_s0    <= hwdata_i[0];
    hwdata_s1    <= hwdata_s0;
  end

  // ========================================================================
  // 上电初始化（默认选择pll_clk, 50MHz）
  // ========================================================================
  initial begin
    curr_state  = S_IDLE;
    clk_sel     = 1'b0;
    clk_sel_req    = 1'b0;
    clk_sw_pending = 1'b0;
    gate_pll    = 1'b1;
    gate_rch    = 1'b0;
    gate_pll_n  = 1'b1;             // V1.6: 上电默认pll门控开
    gate_rch_s1 = 1'b0;
    gate_rch_s2 = 1'b0;
    switch_cnt  = 4'd0;
    // V1.4: CDC同步器初始值
    hsel_s1     = 1'b0;
    hsel_s2     = 1'b0;
    hwrite_s1   = 1'b0;
    hwrite_s2   = 1'b0;
    htrans_s1   = 2'b00;
    htrans_s2   = 2'b00;
    haddr_lo_s1 = 4'h0;
    haddr_lo_s2 = 4'h0;
    hwdata_s0   = 1'b0;
    hwdata_s1   = 1'b0;
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
        // V1.5: 用clk_sw_pending触发(与clk_sel_req值无关)
        if (clk_sw_pending) begin
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
  // V1.4: AHB写检测使用2-FF同步后的信号, hwdata_s1与控制信号同深度对齐
  // ========================================================================
  always @(posedge pll_clk_i) begin
    case (curr_state)
      S_IDLE: begin
        switch_cnt <= 4'd0;
        // V1.5: CDC安全 — 同步信号检测, clk_sw_pending分离触发与数据
        if (ahb_active_sync && hwrite_s2 && haddr_lo_s2 == 4'h0) begin
          clk_sel_req    <= hwdata_s1;
          clk_sw_pending <= 1'b1;
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
          clk_sw_pending <= 1'b0;    // V1.5: 清除pending触发
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
