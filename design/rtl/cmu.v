// ============================================================================
// 时钟管理单元 (CMU) — Clock Management Unit
// ============================================================================
// 功能：双时钟源选择（rch_clk 16MHz / pll_clk 50MHz），无毛刺切换，AHB 可配
// ============================================================================

module cmu (
    // 时钟源输入
    input  wire       rch_clk,        // 内部RC振荡器 16MHz
    input  wire       pll_clk,        // PLL输出 50MHz

    // 主时钟输出
    output wire       hclk,           // 主时钟输出（默认pll_clk 50MHz）
    output wire       hclk_div,       // 分频时钟输出（预留）

    // AHB 从机接口
    input  wire       hresetn,        // AHB总线复位（低有效）
    input  wire       hsel,           // Slave选择
    input  wire [31:0] haddr,         // 地址
    input  wire       hwrite,         // 读写：1=写，0=读
    input  wire [1:0] htrans,         // 传输类型
    input  wire [31:0] hwdata,        // 写数据
    output reg  [31:0] hrdata,        // 读数据
    output reg        hready,         // 传输完成
    output wire [1:0] hresp           // 传输响应
);

    // ========================================================================
    // 参数定义
    // ========================================================================
    parameter HCLK_FREQ_MHZ = 50;       // 默认主时钟频率
    parameter DIV_RATIO     = 1;        // 分频比（预留）

    // ========================================================================
    // 寄存器定义
    // ========================================================================
    reg        clk_sel;                 // 时钟源选择：0=pll_clk, 1=rch_clk
    reg        clk_sel_req;             // 时钟切换请求
    reg [3:0]  switch_cnt;              // 切换计数器

    // ========================================================================
    // 无毛刺时钟切换 (Glitch-Free Clock Mux)
    // ========================================================================
    // 采用"先关后开"策略：
    // 1. 关闭当前时钟门控
    // 2. 切换选择
    // 3. 等待两个源时钟周期后释放门控

    reg        gate_pll;                // pll_clk 门控
    reg        gate_rch;                // rch_clk 门控
    reg        gate_pll_sync;
    reg        gate_rch_sync;

    wire       pll_gated;
    wire       rch_gated;

    assign pll_gated = pll_clk & gate_pll;
    assign rch_gated = rch_clk & gate_rch;

    // hclk 输出选择
    assign hclk = clk_sel ? rch_gated : pll_gated;
    assign hclk_div = 1'b0;            // 预留：分频时钟未启用

    // 切换状态机
    localparam SW_IDLE     = 2'b00;
    localparam SW_GATE_OFF = 2'b01;
    localparam SW_SWITCH   = 2'b10;
    localparam SW_GATE_ON  = 2'b11;

    reg [1:0] switch_state;

    always @(negedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            clk_sel      <= 1'b0;
            clk_sel_req  <= 1'b0;
            switch_state <= SW_IDLE;
            switch_cnt   <= 4'd0;
            gate_pll     <= 1'b1;
            gate_rch     <= 1'b0;
        end else begin
            // 默认状态
            if (switch_state == SW_IDLE) begin
                if (clk_sel_req) begin
                    switch_state <= SW_GATE_OFF;
                    switch_cnt   <= 4'd0;
                end
            end

            // 关闭当前门控
            else if (switch_state == SW_GATE_OFF) begin
                if (clk_sel) begin
                    gate_rch <= 1'b0;
                end else begin
                    gate_pll <= 1'b0;
                end
                switch_cnt <= switch_cnt + 4'd1;
                if (switch_cnt == 4'd3) begin   // 等待3个周期确保门控关闭
                    switch_state <= SW_SWITCH;
                end
            end

            // 切换选择
            else if (switch_state == SW_SWITCH) begin
                clk_sel <= clk_sel_req;
                switch_state <= SW_GATE_ON;
                switch_cnt   <= 4'd0;
            end

            // 开启新门控
            else if (switch_state == SW_GATE_ON) begin
                if (clk_sel_req) begin
                    gate_rch <= 1'b1;
                end else begin
                    gate_pll <= 1'b1;
                end
                switch_cnt <= switch_cnt + 4'd1;
                if (switch_cnt == 4'd3) begin
                    switch_state <= SW_IDLE;
                    clk_sel_req  <= 1'b0;
                end
            end
        end
    end

    // ========================================================================
    // AHB 从机接口
    // ========================================================================
    wire ahb_active;
    assign ahb_active = hsel && (htrans == 2'b10);
    assign hresp = 2'b00;              // 始终 OKAY

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            hrdata   <= 32'h0;
            hready   <= 1'b1;
        end else begin
            if (ahb_active && hready) begin
                if (hwrite) begin
                    // 写操作
                    case (haddr[3:0])
                        4'h0: begin
                            clk_sel_req <= hwdata[0];   // CMU_CLK_SEL
                        end
                        default: ;
                    endcase
                    hready <= 1'b1;
                end else begin
                    // 读操作
                    case (haddr[3:0])
                        4'h0: hrdata <= {31'h0, clk_sel};       // CMU_CLK_SEL
                        4'h4: hrdata <= {31'h0, clk_sel};       // CMU_STATUS
                        default: hrdata <= 32'h0;
                    endcase
                    hready <= 1'b1;
                end
            end else begin
                hready <= 1'b1;
            end
        end
    end

endmodule
