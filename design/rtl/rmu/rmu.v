// 复位管理单元 (RMU) — Reset Management Unit
//
// 功能：
//   - pin_rst_n: 500us数字消抖滤波
//   - por_rst_n: 模拟域上电复位
//   - 5模块独立软复位（AHB可配，写0复位/写1释放）
//   - 异步复位、同步释放

module rmu #(
  parameter int PinFilterCycles = 25000  // 500us @ 50MHz; 8000 @ 16MHz
) (
  input  wire       clk_i,
  input  wire       rst_ni,            // RMU自身AHB复位

  // AHB从机接口
  input  wire       hsel_i,
  input  wire [31:0] haddr_i,
  input  wire       hwrite_i,
  input  wire [1:0] htrans_i,
  input  wire [31:0] hwdata_i,
  output wire [31:0] hrdata_o,
  output wire       hready_o,
  output wire [1:0] hresp_o,

  // 外部复位输入
  input  wire       pin_rst_ni,        // 外部引脚复位（低有效）
  input  wire       por_rst_ni,        // 模拟域上电复位（低有效）

  // 复位输出
  output wire       sys_rst_no,        // 系统全局复位
  output wire       uart_rst_no,       // UART复位
  output wire       dsp_rst_no,        // DSP复位
  output wire       timer_rst_no,      // SYS_TC复位
  output wire       sram_rst_no,       // SRAM_ECC复位
  output wire       bfm_rst_no         // AHB BFM复位
);

  // ========================================================================
  // 500us数字滤波
  // ========================================================================
  reg [14:0] filter_cnt_d, filter_cnt_q;
  reg        pin_sync1_q, pin_sync2_q;
  reg        pin_prev_q;
  reg        pin_filtered_d, pin_filtered_q;
  reg        filter_active_d, filter_active_q;
  always @(posedge clk_i or negedge pin_rst_ni) begin
    if (!pin_rst_ni) begin
      pin_sync1_q <= 1'b0;
      pin_sync2_q <= 1'b0;
    end else begin
      pin_sync1_q <= 1'b1;
      pin_sync2_q <= pin_sync1_q;
    end
  end

  wire pin_falling;
  assign pin_falling = pin_prev_q && !pin_sync2_q;

  always @(*) begin
    filter_cnt_d    = filter_cnt_q;
    pin_filtered_d  = pin_filtered_q;
    filter_active_d = filter_active_q;

    if (pin_falling) begin
      filter_cnt_d    = 15'd0;
      filter_active_d = 1'b1;
    end else if (filter_active_q) begin
      if (filter_cnt_q < PinFilterCycles - 1) begin
        filter_cnt_d = filter_cnt_q + 15'd1;
      end else begin
        pin_filtered_d  = pin_sync2_q;
        filter_active_d = 1'b0;
      end
    end
  end

  always @(posedge clk_i or negedge por_rst_ni) begin
    if (!por_rst_ni) begin
      filter_cnt_q    <= 15'd0;
      pin_prev_q      <= 1'b1;
      pin_filtered_q  <= 1'b0;
      filter_active_q <= 1'b0;
    end else begin
      pin_prev_q      <= pin_sync2_q;
      filter_cnt_q    <= filter_cnt_d;
      pin_filtered_q  <= pin_filtered_d;
      filter_active_q <= filter_active_d;
    end
  end

  // ========================================================================
  // 软件复位寄存器 [4]=bfm [3]=sram [2]=timer [1]=dsp [0]=uart
  // ========================================================================
  reg [4:0] soft_rst_d, soft_rst_q;  // 1=释放 0=复位
  wire [4:0] module_rst_raw;

  wire global_rst_raw;
  assign global_rst_raw = pin_filtered_q & por_rst_ni;

  assign module_rst_raw[0] = global_rst_raw & soft_rst_q[0];  // uart
  assign module_rst_raw[1] = global_rst_raw & soft_rst_q[1];  // dsp
  assign module_rst_raw[2] = global_rst_raw & soft_rst_q[2];  // timer
  assign module_rst_raw[3] = global_rst_raw & soft_rst_q[3];  // sram
  assign module_rst_raw[4] = global_rst_raw & soft_rst_q[4];  // bfm

  // ========================================================================
  // 同步释放（异步复位、同步释放）
  // ========================================================================
  reg [1:0] sys_sync_d, sys_sync_q;
  reg [1:0] uart_sync_d, uart_sync_q;
  reg [1:0] dsp_sync_d, dsp_sync_q;
  reg [1:0] timer_sync_d, timer_sync_q;
  reg [1:0] sram_sync_d, sram_sync_q;
  reg [1:0] bfm_sync_d, bfm_sync_q;

  always @(*) begin
    sys_sync_d   = global_rst_raw ? {sys_sync_q[0], 1'b1}   : 2'b00;
    uart_sync_d  = module_rst_raw[0] ? {uart_sync_q[0], 1'b1} : 2'b00;
    dsp_sync_d   = module_rst_raw[1] ? {dsp_sync_q[0], 1'b1}  : 2'b00;
    timer_sync_d = module_rst_raw[2] ? {timer_sync_q[0], 1'b1}: 2'b00;
    sram_sync_d  = module_rst_raw[3] ? {sram_sync_q[0], 1'b1} : 2'b00;
    bfm_sync_d   = module_rst_raw[4] ? {bfm_sync_q[0], 1'b1}  : 2'b00;
  end

  always @(posedge clk_i or negedge global_rst_raw) begin
    if (!global_rst_raw) sys_sync_q <= 2'b00;
    else                 sys_sync_q <= sys_sync_d;
  end
  always @(posedge clk_i or negedge module_rst_raw[0]) begin
    if (!module_rst_raw[0]) uart_sync_q <= 2'b00;
    else                    uart_sync_q <= uart_sync_d;
  end
  always @(posedge clk_i or negedge module_rst_raw[1]) begin
    if (!module_rst_raw[1]) dsp_sync_q <= 2'b00;
    else                    dsp_sync_q <= dsp_sync_d;
  end
  always @(posedge clk_i or negedge module_rst_raw[2]) begin
    if (!module_rst_raw[2]) timer_sync_q <= 2'b00;
    else                    timer_sync_q <= timer_sync_d;
  end
  always @(posedge clk_i or negedge module_rst_raw[3]) begin
    if (!module_rst_raw[3]) sram_sync_q <= 2'b00;
    else                    sram_sync_q <= sram_sync_d;
  end
  always @(posedge clk_i or negedge module_rst_raw[4]) begin
    if (!module_rst_raw[4]) bfm_sync_q <= 2'b00;
    else                    bfm_sync_q <= bfm_sync_d;
  end

  assign sys_rst_no   = sys_sync_q[1];
  assign uart_rst_no  = uart_sync_q[1];
  assign dsp_rst_no   = dsp_sync_q[1];
  assign timer_rst_no = timer_sync_q[1];
  assign sram_rst_no  = sram_sync_q[1];
  assign bfm_rst_no   = bfm_sync_q[1];

  // ========================================================================
  // AHB从机接口
  // ========================================================================
  wire ahb_active;
  assign ahb_active = hsel_i && (htrans_i == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  always @(*) begin
    soft_rst_d = soft_rst_q;
    if (ahb_active && hwrite_i && haddr_i[3:0] == 4'h0) begin
      soft_rst_d = hwdata_i[4:0];
    end
  end

  always @(posedge clk_i or negedge module_rst_raw[4]) begin
    if (!module_rst_raw[4]) begin
      soft_rst_q <= 5'b11111;
    end else begin
      soft_rst_q <= soft_rst_d;
    end
  end

  assign hrdata_o = (haddr_i[3:0] == 4'h0) ? {27'h0, soft_rst_q} :
                    (haddr_i[3:0] == 4'h4) ? {29'h0, filter_active_q, por_rst_ni,
                                              pin_filtered_q} :
                    32'h0;

  // ========================================================================
  // V1.1: 上电初始化 (修复pin/por直连高时无异步复位导致X态扩散)
  // ========================================================================
  initial begin
    pin_sync1_q     = 1'b1;
    pin_sync2_q     = 1'b1;
    pin_prev_q      = 1'b1;
    pin_filtered_q  = 1'b1;
    filter_cnt_q    = 15'd0;
    filter_active_q = 1'b0;
    soft_rst_q      = 5'b11111;
    sys_sync_q      = 2'b11;
    uart_sync_q     = 2'b11;
    dsp_sync_q      = 2'b11;
    timer_sync_q    = 2'b11;
    sram_sync_q     = 2'b11;
    bfm_sync_q      = 2'b11;
  end

endmodule
