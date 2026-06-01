// SRAM_ECC存储阵列 — 256×39位双端口仿真SRAM
//
// 功能：ECC编码后的码字存储（32位数据 + 7位ECC）
// 写操作：组合编码后的39位码字写入
// 读操作：通过AHB字地址读取39位码字

module sram_ecc_mem #(
  parameter int Depth = 256,
  localparam int AddrWidth = $clog2(Depth)
) (
  input  wire       clk_i,
  input  wire       rst_ni,

  // 写端口
  input  wire       wr_en_i,
  input  wire [AddrWidth-1:0] wr_addr_i,
  input  wire [38:0] wr_data_i,

  // 读端口
  input  wire [AddrWidth-1:0] rd_addr_i,
  output wire [38:0] rd_data_o
);

  reg [38:0] mem [0:Depth-1];

  assign rd_data_o = mem[rd_addr_i];

  always_ff @(posedge clk_i) begin
    if (wr_en_i) begin
      mem[wr_addr_i] <= wr_data_i;
    end
  end

endmodule
