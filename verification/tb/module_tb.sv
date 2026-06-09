//--------------------------------------------------------------
// 模块级Testbench顶层 (module_tb)
// 功能: 通过`ifdef选择DUT, DUT直连ahb_if
// 版本: V1.0 2026.05.29
`timescale 1ns/1ps
//       V1.1 2026.06.03 (增加全部7模块DUT实例化)
//       V2.0 2026.06.03 (修复总线连接: DUT直连ahb_if, 移除错误中间wire)
//--------------------------------------------------------------

import uvm_pkg::*;

module module_tb;

  // ================================================================
  // 时钟和复位
  // ================================================================
  reg        rch_clk;       // 16MHz RC时钟 (CMU)
  reg        pll_clk;       // 50MHz PLL时钟 (CMU)
  reg        hclk;          // AHB总线时钟
  reg        hresetn;       // AHB总线复位 (低有效)

  // ----------------------------------------------------------------
  // 时钟生成
  // ----------------------------------------------------------------
  // RC时钟 16MHz
  initial begin
    rch_clk = 1'b0;
    forever #31.25 rch_clk = ~rch_clk;
  end

  // PLL时钟 50MHz
  initial begin
    pll_clk = 1'b0;
    forever #10 pll_clk = ~pll_clk;
  end

`ifdef DUT_CMU
  // CMU模式: hclk由CMU DUT产生, hresetn用绝对时间
  initial begin
    hresetn = 1'b0;
    #5000;
    hresetn = 1'b1;
  end
`else
  // 通用模式: testbench产生hclk (50MHz) + hresetn
  initial begin
    hclk = 1'b0;
    forever #10 hclk = ~hclk;
  end
  initial begin
    hresetn = 1'b0;
    repeat (20) @(posedge hclk);
    hresetn = 1'b1;
  end
`endif

  // ================================================================
  // AHB Interface + DUT
  // DUT直连ahb_if, 无中间wire
  // ================================================================
  ahb_if ahb_vif (.hclk(hclk), .hresetn(hresetn));

  // 模块级: 单DUT, hsel恒为1
  assign ahb_vif.hsel = 1'b1;

`ifdef DUT_CMU
  cmu u_dut (
    .rch_clk_i (rch_clk),
    .pll_clk_i (pll_clk),
    .hclk_o    (hclk),
    .hsel_i    (ahb_vif.hsel),
    .haddr_i   (ahb_vif.haddr),
    .hwrite_i  (ahb_vif.hwrite),
    .htrans_i  (ahb_vif.htrans),
    .hwdata_i  (ahb_vif.hwdata),
    .hrdata_o  (ahb_vif.hrdata),
    .hready_o  (ahb_vif.hready),
    .hresp_o   (ahb_vif.hresp)
  );

`elsif DUT_RMU
  // 外部复位直连高 (模块级内部管理)
  wire pin_rst_ni = 1'b1;
  wire por_rst_ni = 1'b1;
  wire sys_rst_no, uart_rst_no, dsp_rst_no;
  wire timer_rst_no, sram_rst_no, bfm_rst_no;

  rmu #(.PinFilterCycles(10)) u_dut (
    .clk_i       (hclk),
    .rst_ni      (hresetn),
    .hsel_i      (ahb_vif.hsel),
    .haddr_i     (ahb_vif.haddr),
    .hwrite_i    (ahb_vif.hwrite),
    .htrans_i    (ahb_vif.htrans),
    .hwdata_i    (ahb_vif.hwdata),
    .hrdata_o    (ahb_vif.hrdata),
    .hready_o    (ahb_vif.hready),
    .hresp_o     (ahb_vif.hresp),
    .pin_rst_ni  (pin_rst_ni),
    .por_rst_ni  (por_rst_ni),
    .sys_rst_no  (sys_rst_no),
    .uart_rst_no (uart_rst_no),
    .dsp_rst_no  (dsp_rst_no),
    .timer_rst_no(timer_rst_no),
    .sram_rst_no (sram_rst_no),
    .bfm_rst_no  (bfm_rst_no)
  );

`elsif DUT_SYS_TC
  wire tc_int;

  sys_tc_top u_dut (
    .clk_i    (hclk),
    .rst_ni   (hresetn),
    .hsel_i   (ahb_vif.hsel),
    .haddr_i  (ahb_vif.haddr),
    .hwrite_i (ahb_vif.hwrite),
    .htrans_i (ahb_vif.htrans),
    .hwdata_i (ahb_vif.hwdata),
    .hrdata_o (ahb_vif.hrdata),
    .hready_o (ahb_vif.hready),
    .hresp_o  (ahb_vif.hresp),
    .tc_int_o (tc_int)
  );

`elsif DUT_DSP
  wire done_int;

  dsp_top u_dut (
    .clk_i      (hclk),
    .rst_ni     (hresetn),
    .hsel_i     (ahb_vif.hsel),
    .haddr_i    (ahb_vif.haddr),
    .hwrite_i   (ahb_vif.hwrite),
    .htrans_i   (ahb_vif.htrans),
    .hwdata_i   (ahb_vif.hwdata),
    .hrdata_o   (ahb_vif.hrdata),
    .hready_o   (ahb_vif.hready),
    .hresp_o    (ahb_vif.hresp),
    .done_int_o (done_int)
  );

`elsif DUT_SRAM_ECC
  wire ecc_err, ecc_sec, ecc_ded;

  sram_ecc_top u_dut (
    .clk_i    (hclk),
    .rst_ni   (hresetn),
    .hsel_i   (ahb_vif.hsel),
    .haddr_i  (ahb_vif.haddr),
    .hwrite_i (ahb_vif.hwrite),
    .htrans_i (ahb_vif.htrans),
    .hwdata_i (ahb_vif.hwdata),
    .hrdata_o (ahb_vif.hrdata),
    .hready_o (ahb_vif.hready),
    .hresp_o  (ahb_vif.hresp),
    .ecc_err_o(ecc_err),
    .ecc_sec_o(ecc_sec),
    .ecc_ded_o(ecc_ded)
  );

`elsif DUT_UART
  wire uart_tx, uart_rx;
  wire tx_int, rx_int;

  uart_top u_dut (
    .clk_i    (hclk),
    .rst_ni   (hresetn),
    .hsel_i   (ahb_vif.hsel),
    .haddr_i  (ahb_vif.haddr),
    .hwrite_i (ahb_vif.hwrite),
    .htrans_i (ahb_vif.htrans),
    .hwdata_i (ahb_vif.hwdata),
    .hrdata_o (ahb_vif.hrdata),
    .hready_o (ahb_vif.hready),
    .hresp_o  (ahb_vif.hresp),
    .uart_tx_o(uart_tx),
    .uart_rx_i(uart_rx),
    .tx_int_o (tx_int),
    .rx_int_o (rx_int)
  );

  // UART: 回环 + Agent monitor读TX
  assign uart_rx = uart_tx;
  uart_if uart_vif (.hclk(hclk));
  assign uart_vif.uart_tx = uart_tx;

`elsif DUT_AHB_MATRIX
  wire [5:0]  s_hsel;
  wire [31:0] s_haddr, s_hwdata, s_hrdata;
  wire        s_hwrite, s_hready;
  wire [2:0]  s_hsize, s_hburst;
  wire [3:0]  s_hprot;
  wire [1:0]  s_htrans, s_hresp;

  ahb_matrix u_dut (
    .m_haddr_i  (ahb_vif.haddr),
    .m_hwrite_i (ahb_vif.hwrite),
    .m_hsize_i  (ahb_vif.hsize),
    .m_hburst_i (ahb_vif.hburst),
    .m_hprot_i  (ahb_vif.hprot),
    .m_htrans_i (ahb_vif.htrans),
    .m_hwdata_i (ahb_vif.hwdata),
    .m_hrdata_o (ahb_vif.hrdata),
    .m_hready_o (ahb_vif.hready),
    .m_hresp_o  (ahb_vif.hresp),
    .s_hsel_o   (s_hsel),
    .s_haddr_o  (s_haddr),
    .s_hwrite_o (s_hwrite),
    .s_hsize_o  (s_hsize),
    .s_hburst_o (s_hburst),
    .s_hprot_o  (s_hprot),
    .s_htrans_o (s_htrans),
    .s_hwdata_o (s_hwdata),
    .s0_hrdata_i(32'h0), .s0_hready_i(1'b1), .s0_hresp_i(2'b00),
    .s1_hrdata_i(32'h0), .s1_hready_i(1'b1), .s1_hresp_i(2'b00),
    .s2_hrdata_i(32'h0), .s2_hready_i(1'b1), .s2_hresp_i(2'b00),
    .s3_hrdata_i(32'h0), .s3_hready_i(1'b1), .s3_hresp_i(2'b00),
    .s4_hrdata_i(32'h0), .s4_hready_i(1'b1), .s4_hresp_i(2'b00),
    .s5_hrdata_i(32'h0), .s5_hready_i(1'b1), .s5_hresp_i(2'b00)
  );

`else
  initial begin
    $error("[module_tb] No DUT_* macro! Use +define+DUT_<MODULE>");
    $finish;
  end
`endif

  // ================================================================
  // UVM 测试启动
  // ================================================================
  initial begin
    uvm_config_db #(virtual ahb_if)::set(null, "*", "ahb_vif", ahb_vif);
`ifdef DUT_UART
    uvm_config_db #(virtual uart_if)::set(null, "*", "uart_vif", uart_vif);
`endif
    run_test();
  end

  // ================================================================
  // VCD 波形 dump
  // ================================================================
  initial begin
    $dumpfile("module_tb.vcd");
    $dumpvars(0, module_tb);
  end

endmodule : module_tb
