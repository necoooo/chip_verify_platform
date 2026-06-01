// 时钟管理单元 (CMU) — Clock Management Unit
//
// 功能：双时钟源无毛刺切换
//   - rch_clk: 内部RC振荡器 16MHz
//   - pll_clk: PLL输出 50MHz（上电默认）
// 切换策略：先关后开（Gate off current → Switch → Gate on new）
// AHB寄存器：0x5000_0000 CMU_CLK_SEL, 0x5000_0004 CMU_STATUS

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

  // 切换状态编码
  localparam [1:0] SwIdle     = 2'd0;
  localparam [1:0] SwGateOff  = 2'd1;
  localparam [1:0] SwSwitch   = 2'd2;
  localparam [1:0] SwGateOn   = 2'd3;

  reg [1:0] switch_state_d, switch_state_q;
  reg       clk_sel_d, clk_sel_q;   // 0=pll, 1=rch
  reg       clk_sel_req_d, clk_sel_req_q;
  reg       gate_pll_d, gate_pll_q;
  reg       gate_rch_d, gate_rch_q;
  reg [3:0] switch_cnt_d, switch_cnt_q;

  wire        ahb_active;
  wire        pll_gated, rch_gated;

  assign ahb_active = hsel_i && (htrans_i == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  assign pll_gated = pll_clk_i & gate_pll_q;
  assign rch_gated = rch_clk_i & gate_rch_q;
  assign hclk_o = clk_sel_q ? rch_gated : pll_gated;

  // 切换状态机
  always @(*) begin
    switch_state_d = switch_state_q;
    clk_sel_d      = clk_sel_q;
    clk_sel_req_d  = clk_sel_req_q;
    gate_pll_d     = gate_pll_q;
    gate_rch_d     = gate_rch_q;
    switch_cnt_d   = switch_cnt_q;

    case (switch_state_q)
      SwIdle: begin
        if (clk_sel_req_q) begin
          switch_state_d = SwGateOff;
          switch_cnt_d   = 4'd0;
        end
      end

      SwGateOff: begin
        if (clk_sel_q) gate_rch_d = 1'b0;
        else           gate_pll_d = 1'b0;
        switch_cnt_d = switch_cnt_q + 4'd1;
        if (switch_cnt_q == 4'd3) begin
          switch_state_d = SwSwitch;
        end
      end

      SwSwitch: begin
        clk_sel_d      = clk_sel_req_q;
        switch_state_d = SwGateOn;
        switch_cnt_d   = 4'd0;
      end

      SwGateOn: begin
        if (clk_sel_req_q) gate_rch_d = 1'b1;
        else               gate_pll_d = 1'b1;
        switch_cnt_d = switch_cnt_q + 4'd1;
        if (switch_cnt_q == 4'd3) begin
          switch_state_d = SwIdle;
          clk_sel_req_d  = 1'b0;
        end
      end

      default: switch_state_d = SwIdle;
    endcase

    // AHB写操作
    if (ahb_active && hwrite_i && haddr_i[3:0] == 4'h0) begin
      clk_sel_req_d = hwdata_i[0];
    end
  end

  always @(posedge hclk_o or negedge clk_sel_q) begin
    if (!clk_sel_q) begin  // pll_clk domain reset
      switch_state_q <= SwIdle;
      clk_sel_q      <= 1'b0;
      clk_sel_req_q  <= 1'b0;
      gate_pll_q     <= 1'b1;
      gate_rch_q     <= 1'b0;
      switch_cnt_q   <= 4'd0;
    end else begin        // rch_clk domain reset
      switch_state_q <= SwIdle;
      clk_sel_q      <= 1'b1;
      clk_sel_req_q  <= 1'b0;
      gate_pll_q     <= 1'b0;
      gate_rch_q     <= 1'b1;
      switch_cnt_q   <= 4'd0;
    end
  end

  always @(posedge hclk_o) begin
    switch_state_q <= switch_state_d;
    clk_sel_q      <= clk_sel_d;
    clk_sel_req_q  <= clk_sel_req_d;
    gate_pll_q     <= gate_pll_d;
    gate_rch_q     <= gate_rch_d;
    switch_cnt_q   <= switch_cnt_d;
  end

  assign hrdata_o = (haddr_i[3:0] == 4'h0) ? {31'h0, clk_sel_q} :
                    (haddr_i[3:0] == 4'h4) ? {31'h0, clk_sel_q} :
                    32'h0;

endmodule
