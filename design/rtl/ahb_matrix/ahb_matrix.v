// AHB总线矩阵 — 1主6从 AHB-Lite 互联
//
// 功能：地址译码路由（HADDR[31:28]）、HSEL生成、响应多路复用

module ahb_matrix (
  // Master侧
  input  wire [31:0] m_haddr_i,
  input  wire        m_hwrite_i,
  input  wire [2:0]  m_hsize_i,
  input  wire [2:0]  m_hburst_i,
  input  wire [3:0]  m_hprot_i,
  input  wire [1:0]  m_htrans_i,
  input  wire [31:0] m_hwdata_i,
  output wire [31:0] m_hrdata_o,
  output wire        m_hready_o,
  output wire [1:0]  m_hresp_o,

  // Slave共享信号
  output wire [5:0]  s_hsel_o,
  output wire [31:0] s_haddr_o,
  output wire        s_hwrite_o,
  output wire [2:0]  s_hsize_o,
  output wire [2:0]  s_hburst_o,
  output wire [3:0]  s_hprot_o,
  output wire [1:0]  s_htrans_o,
  output wire [31:0] s_hwdata_o,

  // Slave 0 — SRAM_ECC
  input  wire [31:0] s0_hrdata_i,
  input  wire        s0_hready_i,
  input  wire [1:0]  s0_hresp_i,

  // Slave 1 — UART
  input  wire [31:0] s1_hrdata_i,
  input  wire        s1_hready_i,
  input  wire [1:0]  s1_hresp_i,

  // Slave 2 — DSP
  input  wire [31:0] s2_hrdata_i,
  input  wire        s2_hready_i,
  input  wire [1:0]  s2_hresp_i,

  // Slave 3 — SYS_TC
  input  wire [31:0] s3_hrdata_i,
  input  wire        s3_hready_i,
  input  wire [1:0]  s3_hresp_i,

  // Slave 4 — RMU
  input  wire [31:0] s4_hrdata_i,
  input  wire        s4_hready_i,
  input  wire [1:0]  s4_hresp_i,

  // Slave 5 — CMU
  input  wire [31:0] s5_hrdata_i,
  input  wire        s5_hready_i,
  input  wire [1:0]  s5_hresp_i
);

  // 共享信号直通
  assign s_haddr_o  = m_haddr_i;
  assign s_hwrite_o = m_hwrite_i;
  assign s_hsize_o  = m_hsize_i;
  assign s_hburst_o = m_hburst_i;
  assign s_hprot_o  = m_hprot_i;
  assign s_htrans_o = m_htrans_i;
  assign s_hwdata_o = m_hwdata_i;

  // 地址译码
  reg [5:0] addr_decode;
  wire        no_idle;

  assign no_idle = m_htrans_i[1];

  assign addr_decode[0] = (m_haddr_i[31:28] == 4'h0) & no_idle;  // SRAM_ECC
  assign addr_decode[1] = (m_haddr_i[31:28] == 4'h1) & no_idle;  // UART
  assign addr_decode[2] = (m_haddr_i[31:28] == 4'h2) & no_idle;  // DSP
  assign addr_decode[3] = (m_haddr_i[31:28] == 4'h3) & no_idle;  // SYS_TC
  assign addr_decode[4] = (m_haddr_i[31:28] == 4'h4) & no_idle;  // RMU
  assign addr_decode[5] = (m_haddr_i[31:28] == 4'h5) & no_idle;  // CMU

  assign s_hsel_o = addr_decode;

  // 响应多路复用（优先级编码）
  reg [31:0] m_hrdata;
  reg       m_hready;
  reg [1:0] m_hresp;

  always @(*) begin
    case (1'b1)
      addr_decode[0]: begin
        m_hrdata = s0_hrdata_i; m_hready = s0_hready_i; m_hresp = s0_hresp_i;
      end
      addr_decode[1]: begin
        m_hrdata = s1_hrdata_i; m_hready = s1_hready_i; m_hresp = s1_hresp_i;
      end
      addr_decode[2]: begin
        m_hrdata = s2_hrdata_i; m_hready = s2_hready_i; m_hresp = s2_hresp_i;
      end
      addr_decode[3]: begin
        m_hrdata = s3_hrdata_i; m_hready = s3_hready_i; m_hresp = s3_hresp_i;
      end
      addr_decode[4]: begin
        m_hrdata = s4_hrdata_i; m_hready = s4_hready_i; m_hresp = s4_hresp_i;
      end
      addr_decode[5]: begin
        m_hrdata = s5_hrdata_i; m_hready = s5_hready_i; m_hresp = s5_hresp_i;
      end
      default: begin
        m_hrdata = 32'hDEAD_BEEF; m_hready = 1'b1; m_hresp = 2'b01;
      end
    endcase
  end

  assign m_hrdata_o = m_hrdata;
  assign m_hready_o = m_hready;
  assign m_hresp_o  = m_hresp;

endmodule
