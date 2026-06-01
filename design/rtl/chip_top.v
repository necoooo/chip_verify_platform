// 芯片验证教学平台 — 顶层集成 (chip_top)
//
// 功能：实例化所有子模块，完成时钟/复位/总线接口连接
// 模块：CMU, RMU, AHB_BFM, AHB_Matrix, UART, DSP, SYS_TC, SRAM_ECC

module chip_top (
  // 时钟源
  input  wire       rch_clk_i,        // 内部RC振荡器 16MHz
  input  wire       pll_clk_i,        // PLL输出 50MHz

  // 复位源
  input  wire       pin_rst_ni,       // 外部引脚复位（低有效）
  input  wire       por_rst_ni,       // 模拟域上电复位（低有效）

  // UART物理引脚
  output wire       uart_tx_o,
  input  wire       uart_rx_i,

  // 中断输出
  output wire       tc_int_o,
  output wire       uart_tx_int_o,
  output wire       uart_rx_int_o,
  output wire       dsp_done_int_o,

  // ECC状态
  output wire       ecc_err_o,
  output wire       ecc_sec_o,
  output wire       ecc_ded_o
);

  // ========================================================================
  // 时钟与复位网络
  // ========================================================================
  wire hclk;
  wire sys_rst_n;
  wire uart_rst_n, dsp_rst_n, timer_rst_n, sram_rst_n, bfm_rst_n;

  // RMU自身复位：仅por_rst可复位RMU
  wire rmu_rst_n;
  assign rmu_rst_n = por_rst_ni;

  // CMU使用系统复位
  wire cmu_rst_n;
  assign cmu_rst_n = sys_rst_n;

  // ========================================================================
  // AHB总线 — Master侧（BFM → Matrix）
  // ========================================================================
  wire [31:0] m_haddr, m_hwdata, m_hrdata;
  wire        m_hwrite, m_hready;
  wire [2:0]  m_hsize;
  wire [2:0]  m_hburst;
  wire [3:0]  m_hprot;
  wire [1:0]  m_htrans;
  wire [1:0]  m_hresp;

  // ========================================================================
  // AHB总线 — Slave共享信号（Matrix → 各Slave）
  // ========================================================================
  wire [5:0]  s_hsel;
  wire [31:0] s_haddr, s_hwdata;
  wire        s_hwrite;
  wire [2:0]  s_hsize;
  wire [2:0]  s_hburst;
  wire [3:0]  s_hprot;
  wire [1:0]  s_htrans;

  // Slave响应
  wire [31:0] s0_hrdata, s1_hrdata, s2_hrdata, s3_hrdata, s4_hrdata, s5_hrdata;
  wire        s0_hready, s1_hready, s2_hready, s3_hready, s4_hready, s5_hready;
  wire [1:0]  s0_hresp, s1_hresp, s2_hresp, s3_hresp, s4_hresp, s5_hresp;

  // ========================================================================
  // 1. CMU — 时钟管理单元（地址 0x5000_0000, Slave 5）
  // ========================================================================
  cmu u_cmu (
    .rch_clk_i (rch_clk_i),
    .pll_clk_i (pll_clk_i),
    .hclk_o    (hclk),
    .hsel_i    (s_hsel[5]),
    .haddr_i   (s_haddr),
    .hwrite_i  (s_hwrite),
    .htrans_i  (s_htrans),
    .hwdata_i  (s_hwdata),
    .hrdata_o  (s5_hrdata),
    .hready_o  (s5_hready),
    .hresp_o   (s5_hresp)
  );

  // ========================================================================
  // 2. RMU — 复位管理单元（地址 0x4000_0000, Slave 4）
  // ========================================================================
  rmu #(
    .PinFilterCycles(25000)
  ) u_rmu (
    .clk_i   (hclk),
    .rst_ni  (rmu_rst_n),
    .hsel_i  (s_hsel[4]),
    .haddr_i (s_haddr),
    .hwrite_i(s_hwrite),
    .htrans_i(s_htrans),
    .hwdata_i(s_hwdata),
    .hrdata_o(s4_hrdata),
    .hready_o(s4_hready),
    .hresp_o (s4_hresp),
    .pin_rst_ni (pin_rst_ni),
    .por_rst_ni (por_rst_ni),
    .sys_rst_no  (sys_rst_n),
    .uart_rst_no (uart_rst_n),
    .dsp_rst_no  (dsp_rst_n),
    .timer_rst_no(timer_rst_n),
    .sram_rst_no (sram_rst_n),
    .bfm_rst_no  (bfm_rst_n)
  );

  // ========================================================================
  // 3. AHB BFM — 总线功能模型（仿真Master）
  // ========================================================================
  ahb_bfm u_ahb_bfm (
    .clk_i    (hclk),
    .rst_ni   (bfm_rst_n),
    .m_haddr_o (m_haddr),
    .m_hwrite_o(m_hwrite),
    .m_hsize_o (m_hsize),
    .m_hburst_o(m_hburst),
    .m_hprot_o (m_hprot),
    .m_htrans_o(m_htrans),
    .m_hwdata_o(m_hwdata),
    .m_hrdata_i(m_hrdata),
    .m_hready_i(m_hready)
  );

  // ========================================================================
  // 4. AHB Matrix — 1主6从总线矩阵
  // ========================================================================
  ahb_matrix u_ahb_matrix (
    .m_haddr_i (m_haddr),
    .m_hwrite_i(m_hwrite),
    .m_hsize_i (m_hsize),
    .m_hburst_i(m_hburst),
    .m_hprot_i (m_hprot),
    .m_htrans_i(m_htrans),
    .m_hwdata_i(m_hwdata),
    .m_hrdata_o(m_hrdata),
    .m_hready_o(m_hready),
    .m_hresp_o (m_hresp),
    .s_hsel_o  (s_hsel),
    .s_haddr_o (s_haddr),
    .s_hwrite_o(s_hwrite),
    .s_hsize_o (s_hsize),
    .s_hburst_o(s_hburst),
    .s_hprot_o (s_hprot),
    .s_htrans_o(s_htrans),
    .s_hwdata_o(s_hwdata),
    .s0_hrdata_i(s0_hrdata),
    .s0_hready_i(s0_hready),
    .s0_hresp_i (s0_hresp),
    .s1_hrdata_i(s1_hrdata),
    .s1_hready_i(s1_hready),
    .s1_hresp_i (s1_hresp),
    .s2_hrdata_i(s2_hrdata),
    .s2_hready_i(s2_hready),
    .s2_hresp_i (s2_hresp),
    .s3_hrdata_i(s3_hrdata),
    .s3_hready_i(s3_hready),
    .s3_hresp_i (s3_hresp),
    .s4_hrdata_i(s4_hrdata),
    .s4_hready_i(s4_hready),
    .s4_hresp_i (s4_hresp),
    .s5_hrdata_i(s5_hrdata),
    .s5_hready_i(s5_hready),
    .s5_hresp_i (s5_hresp)
  );

  // ========================================================================
  // 5. UART — 通信模块（地址 0x1000_0000, Slave 1）
  // ========================================================================
  uart_top u_uart (
    .clk_i   (hclk),
    .rst_ni  (uart_rst_n),
    .hsel_i  (s_hsel[1]),
    .haddr_i (s_haddr),
    .hwrite_i(s_hwrite),
    .htrans_i(s_htrans),
    .hwdata_i(s_hwdata),
    .hrdata_o(s1_hrdata),
    .hready_o(s1_hready),
    .hresp_o (s1_hresp),
    .uart_tx_o(uart_tx_o),
    .uart_rx_i(uart_rx_i),
    .tx_int_o (uart_tx_int_o),
    .rx_int_o (uart_rx_int_o)
  );

  // ========================================================================
  // 6. DSP — 算法模块（地址 0x2000_0000, Slave 2）
  // ========================================================================
  dsp_top u_dsp (
    .clk_i   (hclk),
    .rst_ni  (dsp_rst_n),
    .hsel_i  (s_hsel[2]),
    .haddr_i (s_haddr),
    .hwrite_i(s_hwrite),
    .htrans_i(s_htrans),
    .hwdata_i(s_hwdata),
    .hrdata_o(s2_hrdata),
    .hready_o(s2_hready),
    .hresp_o (s2_hresp),
    .done_int_o(dsp_done_int_o)
  );

  // ========================================================================
  // 7. SYS_TC — 系统定时器（地址 0x3000_0000, Slave 3）
  // ========================================================================
  sys_tc_top u_sys_tc (
    .clk_i   (hclk),
    .rst_ni  (timer_rst_n),
    .hsel_i  (s_hsel[3]),
    .haddr_i (s_haddr),
    .hwrite_i(s_hwrite),
    .htrans_i(s_htrans),
    .hwdata_i(s_hwdata),
    .hrdata_o(s3_hrdata),
    .hready_o(s3_hready),
    .hresp_o (s3_hresp),
    .tc_int_o(tc_int_o)
  );

  // ========================================================================
  // 8. SRAM_ECC — 带ECC的SRAM（地址 0x0000_0000, Slave 0）
  // ========================================================================
  sram_ecc_top u_sram_ecc (
    .clk_i   (hclk),
    .rst_ni  (sram_rst_n),
    .hsel_i  (s_hsel[0]),
    .haddr_i (s_haddr),
    .hwrite_i(s_hwrite),
    .htrans_i(s_htrans),
    .hwdata_i(s_hwdata),
    .hrdata_o(s0_hrdata),
    .hready_o(s0_hready),
    .hresp_o (s0_hresp),
    .ecc_err_o(ecc_err_o),
    .ecc_sec_o(ecc_sec_o),
    .ecc_ded_o(ecc_ded_o)
  );

endmodule
