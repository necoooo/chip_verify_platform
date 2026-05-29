// ============================================================================
// AHB 总线功能模型 (AHB BFM) — Bus Functional Model
// ============================================================================
// 功能：仿真AHB-Lite Master，替代CPU，提供ahb_write/ahb_read任务
// 注意：纯仿真模型，不可综合。使用前需在testbench中`include本文件
// ============================================================================

// 使用说明：
// 在仿真testbench中实例化本模块后，通过以下系统任务调用：
//   - bfm_write(addr, data)  — 发起AHB写操作
//   - bfm_read(addr, data)   — 发起AHB读操作，data为output

module ahb_bfm (
    // 时钟和复位
    input  wire        hclk,
    input  wire        hresetn,

    // AHB-Lite Master 接口
    output reg  [31:0] m_haddr,
    output reg         m_hwrite,
    output reg  [2:0]  m_hsize,
    output reg  [2:0]  m_hburst,
    output reg  [3:0]  m_hprot,
    output reg  [1:0]  m_htrans,
    output reg  [31:0] m_hwdata,
    input  wire [31:0] m_hrdata,
    input  wire        m_hready
);

    // ========================================================================
    // 参数定义
    // ========================================================================
    localparam HTRANS_IDLE   = 2'b00;
    localparam HTRANS_NONSEQ = 2'b10;

    // ========================================================================
    // 状态和任务控制
    // ========================================================================
    reg        task_pending;          // 有挂起的操作
    reg        task_write;            // 1=写操作, 0=读操作
    reg [31:0] task_addr;
    reg [31:0] task_wdata;
    reg [1:0]  task_phase;           // 0=ADDR, 1=DATA

    // 事件同步
    reg        operation_done;
    reg [31:0] read_result;

    // ========================================================================
    // AHB Master 状态机
    // ========================================================================
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            m_haddr      <= 32'h0;
            m_hwrite     <= 1'b0;
            m_hsize      <= 3'b010;     // 32-bit
            m_hburst     <= 3'b000;     // SINGLE
            m_hprot      <= 4'b0011;    // data/opcode, user mode
            m_htrans     <= HTRANS_IDLE;
            m_hwdata     <= 32'h0;
            task_phase   <= 2'd0;
            operation_done <= 1'b0;
            read_result  <= 32'h0;
        end else begin
            case (task_phase)
                2'd0: begin  // IDLE — 等待新任务
                    operation_done <= 1'b0;
                    if (task_pending) begin
                        // 地址阶段
                        m_haddr  <= task_addr;
                        m_hwrite <= task_write;
                        m_htrans <= HTRANS_NONSEQ;
                        if (task_write) begin
                            m_hwdata <= task_wdata;
                        end
                        task_phase <= 2'd1;
                    end else begin
                        m_htrans <= HTRANS_IDLE;
                    end
                end

                2'd1: begin  // ADDR阶段 — 等待HREADY
                    if (m_hready) begin
                        if (!m_hwrite) begin
                            read_result <= m_hrdata;  // 采样读数据
                        end
                        m_htrans     <= HTRANS_IDLE;
                        task_phase   <= 2'd0;
                        operation_done <= 1'b1;
                        // 任务完成，清除挂起标志
                        // （实际由外部task清除task_pending）
                    end
                end

                default: task_phase <= 2'd0;
            endcase
        end
    end

    // ========================================================================
    // AHB 写操作任务
    // ========================================================================
    task ahb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            // 等待当前操作完成
            wait(operation_done == 1'b0 || operation_done == 1'b1);
            @(posedge hclk);

            task_addr    = addr;
            task_wdata   = data;
            task_write   = 1'b1;
            task_pending = 1'b1;
            operation_done = 1'b0;

            // 等待操作完成
            @(posedge hclk);  // 地址阶段
            wait(m_hready == 1'b1);
            @(posedge hclk);  // 数据阶段完成

            task_pending = 1'b0;
            operation_done = 1'b1;
        end
    endtask

    // ========================================================================
    // AHB 读操作任务
    // ========================================================================
    task ahb_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            // 等待当前操作完成
            @(posedge hclk);

            task_addr    = addr;
            task_write   = 1'b0;
            task_pending = 1'b1;
            operation_done = 1'b0;

            // 等待地址阶段完成
            @(posedge hclk);
            wait(m_hready == 1'b1);

            // 采样读数据
            data = m_hrdata;

            task_pending = 1'b0;
            operation_done = 1'b1;
        end
    endtask

    // ========================================================================
    // 延迟等待任务
    // ========================================================================
    task ahb_delay;
        input [31:0] cycles;
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1) begin
                @(posedge hclk);
            end
        end
    endtask

endmodule
