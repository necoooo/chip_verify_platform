// 时钟管理单元 (CMU) — Clock Management Unit
//
// 功能：双时钟源无毛刺切换
//   - rch_clk: 内部RC振荡器 16MHz
//   - pll_clk: PLL输出 50MHz（上电默认）
// 切换策略：先关后开（Gate off current → Switch → Gate on new）
// AHB寄存器：0x5000_0000 CMU_CLK_SEL, 0x5000_0004 CMU_STATUS
// 状态机：三段式结构（状态寄存器 + 下一状态逻辑 + 输出寄存器）
// V1.2: FSM时钟改用pll_clk_i(始终运行), 修复时钟切换时hclk停振导致FSM卡死
// V1.3: CDC同步器 — 2-FF同步AHB信号(hclk_o域→pll_clk_i域),
//       修复切到rch(16MHz)后AHB写CLK_SEL无法被FSM(50MHz)正确采样的亚稳态问题
//       hwdata采用toggle握手跨域, haddr/hwrite/htrans/hsel各2-FF同步

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

  // V1.3: CDC 2-FF同步器 — AHB信号(hclk_o域) → pll_clk_i域
  // AHB信号随hclk_o变化(hclk_o可为16MHz或50MHz), FSM在pll_clk_i(50MHz)域
  // 直接采样会导致亚稳态; 2-FF同步器将MTBF降至可忽略水平
  reg        hsel_s1, hsel_s2;
  reg        hwrite_s1, hwrite_s2;
  reg [1:0]  htrans_s1, htrans_s2;
  reg [3:0]  haddr_lo_s1, haddr_lo_s2;
  // V1.3: hwdata通过toggle握手跨域 — 写检测后capture, toggle→同步→边沿检测→安全读取
  reg        hwdata_cap;           // capture hwdata_i[0] on write detect
  reg        hwdata_toggle;        // toggle on each write (跨域握手)
  reg [1:0]  hwdata_toggle_sync;   // 2-FF同步器(pll_clk_i域)
  reg        hwdata_toggle_sync_d; // 前值, 用于边沿检测

  wire       ahb_active_sync;
  wire       hwdata_wr_det;        // pll_clk_i域的写检测脉冲

  assign ahb_active_sync = hsel_s2 && (htrans_s2 == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  assign pll_gated = pll_clk_i & gate_pll;
  assign rch_gated = rch_clk_i & gate_rch;
  assign hclk_o = clk_sel ? rch_gated : pll_gated;

  // CDC同步器链: 2-FF同步 + hwdata toggle握手
  always @(posedge pll_clk_i) begin
    // AHB控制信号 2-FF同步器
    hsel_s1      <= hsel_i;
    hsel_s2      <= hsel_s1;
    hwrite_s1    <= hwrite_i;
    hwrite_s2    <= hwrite_s1;
    htrans_s1    <= htrans_i;
    htrans_s2    <= htrans_s1;
    haddr_lo_s1  <= haddr_i[3:0];
    haddr_lo_s2  <= haddr_lo_s1;
    // hwdata toggle握手: 同步器+边沿检测
    hwdata_toggle_sync   <= {hwdata_toggle_sync[0], hwdata_toggle};
    hwdata_toggle_sync_d <= hwdata_toggle_sync[1];
  end

  // V1.3: 写检测在pll_clk_i域完成(使用已同步的信号, 避免亚稳态)
  // hwdata_i[0]在ahb_active_sync为高时已稳定>2周期, 可安全采样
  always @(posedge pll_clk_i) begin
    if (ahb_active_sync && hwrite_s2 && haddr_lo_s2 == 4'h0) begin
      hwdata_cap    <= hwdata_i[0];          // 安全采样(已稳定)
      hwdata_toggle <= ~hwdata_toggle;        // toggle握手
    end
  end

  // pll_clk_i域的写检测脉冲
  assign hwdata_wr_det = hwdata_toggle_sync[1] ^ hwdata_toggle_sync_d;

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
    // V1.3: CDC同步器初始值
    hsel_s1     = 1'b0;
    hsel_s2     = 1'b0;
    hwrite_s1   = 1'b0;
    hwrite_s2   = 1'b0;
    htrans_s1   = 2'b00;
    htrans_s2   = 2'b00;
    haddr_lo_s1 = 4'h0;
    haddr_lo_s2 = 4'h0;
    hwdata_cap  = 1'b0;
    hwdata_toggle       = 1'b0;
    hwdata_toggle_sync  = 2'b00;
    hwdata_toggle_sync_d = 1'b0;
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
  // V1.3: AHB写检测改用hwdata_wr_det(CDC toggle握手), 避免直接采样hclk_o域信号
  // ========================================================================
  always @(posedge pll_clk_i) begin
    case (curr_state)
      S_IDLE: begin
        switch_cnt <= 4'd0;
        // V1.3: CDC安全的写检测 — hwdata_wr_det是pll_clk_i域的同步脉冲
        if (hwdata_wr_det) begin
          clk_sel_req <= hwdata_cap;
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
