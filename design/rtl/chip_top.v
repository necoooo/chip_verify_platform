// ============================================================================
// 芯片验证教学平台 — 顶层集成模块 (chip_top)
// ============================================================================
// 功能：实例化所有子模块，完成时钟/复位/总线接口的完整连接
// 模块清单：CMU, RMU, AHB_BFM, AHB_Matrix, UART, DSP, SYS_TC, SRAM_ECC
// ============================================================================

module chip_top (
    // ========================================================================
    // 时钟源输入
    // ========================================================================
    input  wire       rch_clk,          // 内部RC振荡器 16MHz
    input  wire       pll_clk,          // PLL输出 50MHz

    // ========================================================================
    // 复位源输入
    // ========================================================================
    input  wire       pin_rst_n,        // 外部引脚复位（低有效）
    input  wire       por_rst_n,        // 模拟域上电复位（低有效）

    // ========================================================================
    // UART 外部引脚
    // ========================================================================
    output wire       uart_tx,          // UART 发送
    input  wire       uart_rx,          // UART 接收

    // ========================================================================
    // 中断输出（至外部中断控制器/测试点）
    // ========================================================================
    output wire       tc_int,           // 定时器中断
    output wire       uart_tx_int,      // UART 发送完成中断
    output wire       uart_rx_int,      // UART 接收中断
    output wire       dsp_done_int,     // DSP 运算完成中断

    // ========================================================================
    // ECC 状态输出（测试点）
    // ========================================================================
    output wire       ecc_err,          // ECC 错误
    output wire       ecc_sec,          // 单bit纠正
    output wire       ecc_ded           // 双bit检测
);

    // ========================================================================
    // 时钟网络
    // ========================================================================
    wire        hclk;                   // 主时钟（CMU输出，所有模块共用）
    wire        hclk_div;               // 分频时钟（预留，当前未使用）

    // ========================================================================
    // 复位网络
    // ========================================================================
    wire        sys_rst_n;              // 系统全局复位
    wire        uart_rst_n;             // UART 模块复位
    wire        dsp_rst_n;              // DSP 模块复位
    wire        timer_rst_n;            // SYS_TC 模块复位
    wire        sram_rst_n;             // SRAM_ECC 模块复位
    wire        bfm_rst_n;              // AHB BFM 模块复位

    // RMU 自身复位：仅 por_rst_n 可复位 RMU（确保 RMU 在所有状态下可工作）
    wire        rmu_hresetn;
    assign      rmu_hresetn = por_rst_n;

    // CMU 使用系统复位
    wire        cmu_hresetn;
    assign      cmu_hresetn = sys_rst_n;

    // ========================================================================
    // AHB 总线信号 — Master 侧（BFM → Matrix）
    // ========================================================================
    wire [31:0] m_haddr;
    wire        m_hwrite;
    wire [2:0]  m_hsize;
    wire [2:0]  m_hburst;
    wire [3:0]  m_hprot;
    wire [1:0]  m_htrans;
    wire [31:0] m_hwdata;
    wire [31:0] m_hrdata;
    wire        m_hready;
    wire [1:0]  m_hresp;

    // ========================================================================
    // AHB 总线信号 — Slave 侧（Matrix → 各Slave共享信号）
    // ========================================================================
    wire [5:0]  s_hsel;                 // [5]=CMU [4]=RMU [3]=SYS_TC [2]=DSP [1]=UART [0]=SRAM_ECC
    wire [31:0] s_haddr;
    wire        s_hwrite;
    wire [2:0]  s_hsize;
    wire [2:0]  s_hburst;
    wire [3:0]  s_hprot;
    wire [1:0]  s_htrans;
    wire [31:0] s_hwdata;

    // Slave 0 — SRAM_ECC
    wire [31:0] s0_hrdata;
    wire        s0_hready;
    wire [1:0]  s0_hresp;

    // Slave 1 — UART
    wire [31:0] s1_hrdata;
    wire        s1_hready;
    wire [1:0]  s1_hresp;

    // Slave 2 — DSP
    wire [31:0] s2_hrdata;
    wire        s2_hready;
    wire [1:0]  s2_hresp;

    // Slave 3 — SYS_TC
    wire [31:0] s3_hrdata;
    wire        s3_hready;
    wire [1:0]  s3_hresp;

    // Slave 4 — RMU
    wire [31:0] s4_hrdata;
    wire        s4_hready;
    wire [1:0]  s4_hresp;

    // Slave 5 — CMU
    wire [31:0] s5_hrdata;
    wire        s5_hready;
    wire [1:0]  s5_hresp;

    // ========================================================================
    // 1. 时钟管理单元 (CMU)
    // ========================================================================
    // 地址：0x5000_0000 (Slave 5)
    // 输出 hclk 供所有模块使用
    cmu u_cmu (
        .rch_clk    (rch_clk),
        .pll_clk    (pll_clk),
        .hclk       (hclk),
        .hclk_div   (hclk_div),
        .hresetn    (cmu_hresetn),
        .hsel       (s_hsel[5]),
        .haddr      (s_haddr),
        .hwrite     (s_hwrite),
        .htrans     (s_htrans),
        .hwdata     (s_hwdata),
        .hrdata     (s5_hrdata),
        .hready     (s5_hready),
        .hresp      (s5_hresp)
    );

    // ========================================================================
    // 2. 复位管理单元 (RMU)
    // ========================================================================
    // 地址：0x4000_0000 (Slave 4)
    // 生成所有模块的独立复位信号
    rmu #(
        .PIN_FILTER_CYCLES(25000)       // 500us @ 50MHz
    ) u_rmu (
        .hclk       (hclk),
        .hresetn    (rmu_hresetn),
        .hsel       (s_hsel[4]),
        .haddr      (s_haddr),
        .hwrite     (s_hwrite),
        .htrans     (s_htrans),
        .hwdata     (s_hwdata),
        .hrdata     (s4_hrdata),
        .hready     (s4_hready),
        .hresp      (s4_hresp),
        .pin_rst_n  (pin_rst_n),
        .por_rst_n  (por_rst_n),
        .sys_rst_n  (sys_rst_n),
        .uart_rst_n (uart_rst_n),
        .dsp_rst_n  (dsp_rst_n),
        .timer_rst_n(timer_rst_n),
        .sram_rst_n (sram_rst_n),
        .bfm_rst_n  (bfm_rst_n)
    );

    // ========================================================================
    // 3. AHB 总线功能模型 (BFM)
    // ========================================================================
    // Master 端：仿真 CPU，发起 AHB 读写
    ahb_bfm u_ahb_bfm (
        .hclk       (hclk),
        .hresetn    (bfm_rst_n),
        .m_haddr    (m_haddr),
        .m_hwrite   (m_hwrite),
        .m_hsize    (m_hsize),
        .m_hburst   (m_hburst),
        .m_hprot    (m_hprot),
        .m_htrans   (m_htrans),
        .m_hwdata   (m_hwdata),
        .m_hrdata   (m_hrdata),
        .m_hready   (m_hready)
    );

    // ========================================================================
    // 4. AHB 总线矩阵
    // ========================================================================
    // 1主6从，地址译码路由
    ahb_matrix u_ahb_matrix (
        // Master 侧
        .m_haddr    (m_haddr),
        .m_hwrite   (m_hwrite),
        .m_hsize    (m_hsize),
        .m_hburst   (m_hburst),
        .m_hprot    (m_hprot),
        .m_htrans   (m_htrans),
        .m_hwdata   (m_hwdata),
        .m_hrdata   (m_hrdata),
        .m_hready   (m_hready),
        .m_hresp    (m_hresp),
        // Slave 共享信号
        .s_hsel     (s_hsel),
        .s_haddr    (s_haddr),
        .s_hwrite   (s_hwrite),
        .s_hsize    (s_hsize),
        .s_hburst   (s_hburst),
        .s_hprot    (s_hprot),
        .s_htrans   (s_htrans),
        .s_hwdata   (s_hwdata),
        // Slave 0 — SRAM_ECC
        .s0_hrdata  (s0_hrdata),
        .s0_hready  (s0_hready),
        .s0_hresp   (s0_hresp),
        // Slave 1 — UART
        .s1_hrdata  (s1_hrdata),
        .s1_hready  (s1_hready),
        .s1_hresp   (s1_hresp),
        // Slave 2 — DSP
        .s2_hrdata  (s2_hrdata),
        .s2_hready  (s2_hready),
        .s2_hresp   (s2_hresp),
        // Slave 3 — SYS_TC
        .s3_hrdata  (s3_hrdata),
        .s3_hready  (s3_hready),
        .s3_hresp   (s3_hresp),
        // Slave 4 — RMU
        .s4_hrdata  (s4_hrdata),
        .s4_hready  (s4_hready),
        .s4_hresp   (s4_hresp),
        // Slave 5 — CMU
        .s5_hrdata  (s5_hrdata),
        .s5_hready  (s5_hready),
        .s5_hresp   (s5_hresp)
    );

    // ========================================================================
    // 5. UART 通信模块
    // ========================================================================
    // 地址：0x1000_0000 (Slave 1)
    uart u_uart (
        .hclk       (hclk),
        .hresetn    (uart_rst_n),
        .hsel       (s_hsel[1]),
        .haddr      (s_haddr),
        .hwrite     (s_hwrite),
        .htrans     (s_htrans),
        .hwdata     (s_hwdata),
        .hrdata     (s1_hrdata),
        .hready     (s1_hready),
        .hresp      (s1_hresp),
        .uart_tx    (uart_tx),
        .uart_rx    (uart_rx),
        .tx_int     (uart_tx_int),
        .rx_int     (uart_rx_int)
    );

    // ========================================================================
    // 6. DSP 算法模块
    // ========================================================================
    // 地址：0x2000_0000 (Slave 2)
    dsp u_dsp (
        .hclk       (hclk),
        .hresetn    (dsp_rst_n),
        .hsel       (s_hsel[2]),
        .haddr      (s_haddr),
        .hwrite     (s_hwrite),
        .htrans     (s_htrans),
        .hwdata     (s_hwdata),
        .hrdata     (s2_hrdata),
        .hready     (s2_hready),
        .hresp      (s2_hresp),
        .done_int   (dsp_done_int)
    );

    // ========================================================================
    // 7. 系统定时器 (SYS_TC)
    // ========================================================================
    // 地址：0x3000_0000 (Slave 3)
    sys_tc u_sys_tc (
        .hclk       (hclk),
        .hresetn    (timer_rst_n),
        .hsel       (s_hsel[3]),
        .haddr      (s_haddr),
        .hwrite     (s_hwrite),
        .htrans     (s_htrans),
        .hwdata     (s_hwdata),
        .hrdata     (s3_hrdata),
        .hready     (s3_hready),
        .hresp      (s3_hresp),
        .tc_int     (tc_int)
    );

    // ========================================================================
    // 8. SRAM_ECC 存储模块
    // ========================================================================
    // 地址：0x0000_0000 (Slave 0)
    sram_ecc u_sram_ecc (
        .hclk       (hclk),
        .hresetn    (sram_rst_n),
        .hsel       (s_hsel[0]),
        .haddr      (s_haddr),
        .hwrite     (s_hwrite),
        .htrans     (s_htrans),
        .hwdata     (s_hwdata),
        .hrdata     (s0_hrdata),
        .hready     (s0_hready),
        .hresp      (s0_hresp),
        .ecc_err    (ecc_err),
        .ecc_sec    (ecc_sec),
        .ecc_ded    (ecc_ded)
    );

endmodule
