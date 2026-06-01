// AHB总线功能模型 (BFM) — Bus Functional Model
//
// 功能：仿真AHB-Lite Master，替代CPU发起读写交易
// 接口：ahb_write(addr, data) / ahb_read(addr, data) 任务
// 注意：纯仿真模型，不可综合。SystemVerilog文件
// 使用方式：在testbench中实例化本模块后调用ahb_write/ahb_read任务

module ahb_bfm (
  input  wire       clk_i,
  input  wire       rst_ni,

  // AHB-Lite Master接口
  output reg  [31:0] m_haddr_o,
  output reg         m_hwrite_o,
  output reg  [2:0]  m_hsize_o,
  output reg  [2:0]  m_hburst_o,
  output reg  [3:0]  m_hprot_o,
  output reg  [1:0]  m_htrans_o,
  output reg  [31:0] m_hwdata_o,
  input  wire [31:0] m_hrdata_i,
  input  wire        m_hready_i
);

  localparam HTRANS_IDLE   = 2'b00;
  localparam HTRANS_NONSEQ = 2'b10;

  // 任务控制
  reg        task_pending;
  reg        task_write;
  reg [31:0] task_addr;
  reg [31:0] task_wdata;
  reg [1:0]  task_phase;         // 0=IDLE, 1=ADDR

  reg        operation_done;
  reg [31:0] read_result;

  // AHB Master状态机
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      m_haddr_o      <= 32'h0;
      m_hwrite_o     <= 1'b0;
      m_hsize_o      <= 3'b010;
      m_hburst_o     <= 3'b000;
      m_hprot_o      <= 4'b0011;
      m_htrans_o     <= HTRANS_IDLE;
      m_hwdata_o     <= 32'h0;
      task_phase     <= 2'd0;
      operation_done <= 1'b0;
      read_result    <= 32'h0;
    end else begin
      operation_done <= 1'b0;

      case (task_phase)
        2'd0: begin  // IDLE
          if (task_pending) begin
            m_haddr_o  <= task_addr;
            m_hwrite_o <= task_write;
            m_htrans_o <= HTRANS_NONSEQ;
            if (task_write) begin
              m_hwdata_o <= task_wdata;
            end
            task_phase <= 2'd1;
          end else begin
            m_htrans_o <= HTRANS_IDLE;
          end
        end

        2'd1: begin  // ADDR阶段
          if (m_hready_i) begin
            if (!m_hwrite_o) begin
              read_result <= m_hrdata_i;
            end
            m_htrans_o     <= HTRANS_IDLE;
            task_phase     <= 2'd0;
            operation_done <= 1'b1;
          end
        end

        default: task_phase <= 2'd0;
      endcase
    end
  end

  // AHB写任务
  task automatic ahb_write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk_i);
      task_addr    = addr;
      task_wdata   = data;
      task_write   = 1'b1;
      task_pending = 1'b1;
      operation_done = 1'b0;
      @(posedge clk_i);
      wait(m_hready_i == 1'b1);
      @(posedge clk_i);
      task_pending = 1'b0;
      operation_done = 1'b1;
    end
  endtask

  // AHB读任务
  task automatic ahb_read(input [31:0] addr, output [31:0] data);
    begin
      @(posedge clk_i);
      task_addr    = addr;
      task_write   = 1'b0;
      task_pending = 1'b1;
      operation_done = 1'b0;
      @(posedge clk_i);
      wait(m_hready_i == 1'b1);
      data = m_hrdata_i;
      task_pending = 1'b0;
      operation_done = 1'b1;
    end
  endtask

  // 延迟任务
  task automatic ahb_delay(input [31:0] cycles);
    integer i;
    begin
      for (i = 0; i < cycles; i = i + 1) begin
        @(posedge clk_i);
      end
    end
  endtask

endmodule
