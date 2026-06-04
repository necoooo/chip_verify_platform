//--------------------------------------------------------------
// AHB-Lite 总线接口 (ahb_if)
//
// 功能: 定义AHB-Lite总线信号，供UVM driver/monitor通过virtual interface访问
// 用途: 在testbench中实例化，连接AHB Master(BFM)和Slave(DUT)
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

interface ahb_if (
  input logic hclk,
  input logic hresetn
);
  // Master → Slave 信号
  logic [31:0] haddr;
  logic        hwrite;
  logic [2:0]  hsize;
  logic [2:0]  hburst;
  logic [3:0]  hprot;
  logic [1:0]  htrans;
  logic [31:0] hwdata;

  // Slave → Master 信号
  logic [31:0] hrdata;
  logic        hready;
  logic [1:0]  hresp;

  // Slave选择信号（由Matrix产生）
  logic        hsel;

  //--------------------------------------------------------------
  // 时钟模块 (clocking blocks)
  //--------------------------------------------------------------

  // Master驱动侧时钟块
  clocking master_cb @(posedge hclk);
    output haddr;
    output hwrite;
    output hsize;
    output hburst;
    output hprot;
    output htrans;
    output hwdata;
    input   hrdata;
    input   hready;
    input   hresp;
  endclocking

  // Slave监测侧时钟块
  clocking monitor_cb @(posedge hclk);
    input haddr;
    input hwrite;
    input hsize;
    input hburst;
    input hprot;
    input htrans;
    input hwdata;
    input hrdata;
    input hready;
    input hresp;
    input hsel;
  endclocking

  //--------------------------------------------------------------
  // 复位检查
  //--------------------------------------------------------------
  // 检查复位期间AHB信号是否处于安全状态
  property reset_check;
    @(posedge hclk) !hresetn |-> !htrans[1];
  endproperty

  // assert property (reset_check) else
    // $error("[AHB_IF] HTRANS should be IDLE during reset");

endinterface : ahb_if
