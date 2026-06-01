// 系统定时器计数核心 — 32位向下计数器
//
// 功能：使能后每个时钟周期减1，到零自动重载并产生中断脉冲

module sys_tc_counter (
  input  wire       clk_i,
  input  wire       rst_ni,

  input  wire       en_i,             // 定时器使能
  input  wire       ie_i,             // 中断使能
  input  wire [31:0] reload_i,         // 重载值

  output wire [31:0] count_o,          // 当前计数值
  output wire       tc_int_o,         // 定时中断脉冲
  output wire       int_flag_o        // 中断标志
);

  logic [31:0] count_d, count_q;
  logic       int_flag_d, int_flag_q;
  logic       tc_int_d, tc_int_q;

  assign count_o    = count_q;
  assign int_flag_o = int_flag_q;
  assign tc_int_o   = tc_int_q;

  always_comb begin
    count_d    = count_q;
    int_flag_d = int_flag_q;
    tc_int_d   = 1'b0;

    if (en_i) begin
      if (count_q == 32'd0) begin
        count_d    = reload_i;
        int_flag_d = 1'b1;
        tc_int_d   = ie_i;
      end else begin
        count_d = count_q - 32'd1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      count_q     <= 32'd49999;  // 1ms @ 50MHz
      int_flag_q  <= 1'b0;
      tc_int_q    <= 1'b0;
    end else begin
      count_q     <= count_d;
      int_flag_q  <= int_flag_d;
      tc_int_q    <= tc_int_d;
    end
  end

endmodule
