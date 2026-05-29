// ============================================================================
// AHB 总线矩阵 (AHB Matrix) — 1主6从 AHB-Lite 总线互联
// ============================================================================
// 功能：地址译码路由、HSEL生成、HRDATA/HREADY/HRESP多路复用
// ============================================================================

module ahb_matrix (
    // ========================================================================
    // Master 侧 — 连接到 AHB BFM
    // ========================================================================
    input  wire [31:0] m_haddr,
    input  wire        m_hwrite,
    input  wire [2:0]  m_hsize,
    input  wire [2:0]  m_hburst,
    input  wire [3:0]  m_hprot,
    input  wire [1:0]  m_htrans,
    input  wire [31:0] m_hwdata,
    output wire [31:0] m_hrdata,
    output wire        m_hready,
    output wire [1:0]  m_hresp,

    // ========================================================================
    // Slave 侧 — 共享信号（连接到所有Slave）
    // ========================================================================
    output wire [5:0]  s_hsel,
    output wire [31:0] s_haddr,
    output wire        s_hwrite,
    output wire [2:0]  s_hsize,
    output wire [2:0]  s_hburst,
    output wire [3:0]  s_hprot,
    output wire [1:0]  s_htrans,
    output wire [31:0] s_hwdata,

    // Slave 0 — SRAM_ECC
    input  wire [31:0] s0_hrdata,
    input  wire        s0_hready,
    input  wire [1:0]  s0_hresp,

    // Slave 1 — UART
    input  wire [31:0] s1_hrdata,
    input  wire        s1_hready,
    input  wire [1:0]  s1_hresp,

    // Slave 2 — DSP
    input  wire [31:0] s2_hrdata,
    input  wire        s2_hready,
    input  wire [1:0]  s2_hresp,

    // Slave 3 — SYS_TC
    input  wire [31:0] s3_hrdata,
    input  wire        s3_hready,
    input  wire [1:0]  s3_hresp,

    // Slave 4 — RMU
    input  wire [31:0] s4_hrdata,
    input  wire        s4_hready,
    input  wire [1:0]  s4_hresp,

    // Slave 5 — CMU
    input  wire [31:0] s5_hrdata,
    input  wire        s5_hready,
    input  wire [1:0]  s5_hresp
);

    // ========================================================================
    // 共享信号直通
    // ========================================================================
    assign s_haddr  = m_haddr;
    assign s_hwrite = m_hwrite;
    assign s_hsize  = m_hsize;
    assign s_hburst = m_hburst;
    assign s_hprot  = m_hprot;
    assign s_htrans = m_htrans;
    assign s_hwdata = m_hwdata;

    // ========================================================================
    // 地址译码 — HADDR[31:28]
    // ========================================================================
    wire [5:0] addr_decode;
    assign addr_decode[0] = (m_haddr[31:28] == 4'h0);  // SRAM_ECC
    assign addr_decode[1] = (m_haddr[31:28] == 4'h1);  // UART
    assign addr_decode[2] = (m_haddr[31:28] == 4'h2);  // DSP
    assign addr_decode[3] = (m_haddr[31:28] == 4'h3);  // SYS_TC
    assign addr_decode[4] = (m_haddr[31:28] == 4'h4);  // RMU
    assign addr_decode[5] = (m_haddr[31:28] == 4'h5);  // CMU

    // HSEL 在 IDLE 周期不产生
    wire no_idle;
    assign no_idle = m_htrans[1];  // HTRANS[1]=1 → NONSEQ or SEQ

    assign s_hsel[0] = addr_decode[0] & no_idle;
    assign s_hsel[1] = addr_decode[1] & no_idle;
    assign s_hsel[2] = addr_decode[2] & no_idle;
    assign s_hsel[3] = addr_decode[3] & no_idle;
    assign s_hsel[4] = addr_decode[4] & no_idle;
    assign s_hsel[5] = addr_decode[5] & no_idle;

    // ========================================================================
    // 响应多路复用 — 根据地址译码选通对应Slave的响应
    // ========================================================================
    reg [31:0] m_hrdata_r;
    reg        m_hready_r;
    reg [1:0]  m_hresp_r;

    always @(*) begin
        case (1'b1)  // 优先级编码（one-hot match）
            addr_decode[0]: begin
                m_hrdata_r = s0_hrdata;
                m_hready_r = s0_hready;
                m_hresp_r  = s0_hresp;
            end
            addr_decode[1]: begin
                m_hrdata_r = s1_hrdata;
                m_hready_r = s1_hready;
                m_hresp_r  = s1_hresp;
            end
            addr_decode[2]: begin
                m_hrdata_r = s2_hrdata;
                m_hready_r = s2_hready;
                m_hresp_r  = s2_hresp;
            end
            addr_decode[3]: begin
                m_hrdata_r = s3_hrdata;
                m_hready_r = s3_hready;
                m_hresp_r  = s3_hresp;
            end
            addr_decode[4]: begin
                m_hrdata_r = s4_hrdata;
                m_hready_r = s4_hready;
                m_hresp_r  = s4_hresp;
            end
            addr_decode[5]: begin
                m_hrdata_r = s5_hrdata;
                m_hready_r = s5_hready;
                m_hresp_r  = s5_hresp;
            end
            default: begin
                m_hrdata_r = 32'hDEAD_BEEF;
                m_hready_r = 1'b1;
                m_hresp_r  = 2'b01;     // ERROR
            end
        endcase
    end

    assign m_hrdata = m_hrdata_r;
    assign m_hready = m_hready_r;
    assign m_hresp  = m_hresp_r;

endmodule
