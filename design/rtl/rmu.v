// ============================================================================
// 复位管理单元 (RMU) — Reset Management Unit
// ============================================================================
// 功能：pin_rst_n 500μs滤波 / por_rst_n / 各模块独立软复位 / AHB可配
// ============================================================================

module rmu #(
    parameter PIN_FILTER_CYCLES = 25000   // 500us @ 50MHz; 8000 @ 16MHz
) (
    // 时钟和复位
    input  wire       hclk,
    input  wire       hresetn,         // AHB总线复位（低有效）

    // AHB 从机接口
    input  wire       hsel,
    input  wire [31:0] haddr,
    input  wire       hwrite,
    input  wire [1:0] htrans,
    input  wire [31:0] hwdata,
    output reg  [31:0] hrdata,
    output reg        hready,
    output wire [1:0] hresp,

    // 外部复位输入
    input  wire       pin_rst_n,       // 外部引脚复位（低有效，需500us滤波）
    input  wire       por_rst_n,       // 模拟域上电复位（低有效）

    // 复位输出
    output wire       sys_rst_n,       // 系统全局复位
    output wire       uart_rst_n,      // UART模块复位
    output wire       dsp_rst_n,       // DSP模块复位
    output wire       timer_rst_n,     // SYS_TC模块复位
    output wire       sram_rst_n,      // SRAM_ECC模块复位
    output wire       bfm_rst_n        // AHB BFM模块复位
);

    // ========================================================================
    // 500μs 数字滤波
    // ========================================================================
    reg  [14:0] filter_cnt;
    reg         pin_rst_n_sync1;       // 同步器第一级
    reg         pin_rst_n_sync2;       // 同步器第二级
    reg         pin_rst_n_prev;        // 前一拍采样值
    reg         pin_filtered_n;        // 滤波后输出
    reg         filter_active;         // 滤波计数进行中

    // 双触发同步（避免亚稳态）
    always @(posedge hclk or negedge pin_rst_n) begin
        if (!pin_rst_n) begin
            pin_rst_n_sync1 <= 1'b0;
            pin_rst_n_sync2 <= 1'b0;
        end else begin
            pin_rst_n_sync1 <= 1'b1;
            pin_rst_n_sync2 <= pin_rst_n_sync1;
        end
    end

    // 500μs 消抖滤波
    always @(posedge hclk or negedge por_rst_n) begin
        if (!por_rst_n) begin
            filter_cnt      <= 15'd0;
            pin_rst_n_prev  <= 1'b1;
            pin_filtered_n  <= 1'b0;
            filter_active   <= 1'b0;
        end else begin
            pin_rst_n_prev <= pin_rst_n_sync2;

            // 检测跳变（前一拍 != 当前拍）
            if (pin_rst_n_sync2 != pin_rst_n_prev) begin
                filter_cnt    <= 15'd0;
                filter_active <= 1'b1;
            end else if (filter_active) begin
                if (filter_cnt < PIN_FILTER_CYCLES - 1) begin
                    filter_cnt <= filter_cnt + 15'd1;
                end else begin
                    // 滤波窗口到期，信号有效
                    pin_filtered_n <= pin_rst_n_sync2;
                    filter_active  <= 1'b0;
                end
            end
        end
    end

    // ========================================================================
    // 软件复位寄存器
    // ========================================================================
    reg [4:0] soft_rst;                // [4]=bfm, [3]=sram, [2]=timer, [1]=dsp, [0]=uart
    // 上电默认全部释放（1=释放）
    // 注：por_rst_n 释放后默认值为 5'b11111

    // ========================================================================
    // 复位合并
    // ========================================================================
    wire global_rst_raw;
    assign global_rst_raw = pin_filtered_n & por_rst_n;

    // 各模块复位 = 全局复位 AND 模块软复位
    wire [4:0] module_rst_raw;
    assign module_rst_raw[0] = global_rst_raw & soft_rst[0];  // uart
    assign module_rst_raw[1] = global_rst_raw & soft_rst[1];  // dsp
    assign module_rst_raw[2] = global_rst_raw & soft_rst[2];  // timer
    assign module_rst_raw[3] = global_rst_raw & soft_rst[3];  // sram
    assign module_rst_raw[4] = global_rst_raw & soft_rst[4];  // bfm

    // ========================================================================
    // 同步释放（异步复位、同步释放）— 每个模块独立
    // ========================================================================
    reg [1:0] sys_sync;
    reg [1:0] uart_sync;
    reg [1:0] dsp_sync;
    reg [1:0] timer_sync;
    reg [1:0] sram_sync;
    reg [1:0] bfm_sync;

    always @(posedge hclk or negedge global_rst_raw) begin
        if (!global_rst_raw) begin
            sys_sync <= 2'b00;
        end else begin
            sys_sync <= {sys_sync[0], 1'b1};
        end
    end

    always @(posedge hclk or negedge module_rst_raw[0]) begin
        if (!module_rst_raw[0]) begin
            uart_sync <= 2'b00;
        end else begin
            uart_sync <= {uart_sync[0], 1'b1};
        end
    end

    always @(posedge hclk or negedge module_rst_raw[1]) begin
        if (!module_rst_raw[1]) begin
            dsp_sync <= 2'b00;
        end else begin
            dsp_sync <= {dsp_sync[0], 1'b1};
        end
    end

    always @(posedge hclk or negedge module_rst_raw[2]) begin
        if (!module_rst_raw[2]) begin
            timer_sync <= 2'b00;
        end else begin
            timer_sync <= {timer_sync[0], 1'b1};
        end
    end

    always @(posedge hclk or negedge module_rst_raw[3]) begin
        if (!module_rst_raw[3]) begin
            sram_sync <= 2'b00;
        end else begin
            sram_sync <= {sram_sync[0], 1'b1};
        end
    end

    always @(posedge hclk or negedge module_rst_raw[4]) begin
        if (!module_rst_raw[4]) begin
            bfm_sync <= 2'b00;
        end else begin
            bfm_sync <= {bfm_sync[0], 1'b1};
        end
    end

    assign sys_rst_n   = sys_sync[1];
    assign uart_rst_n  = uart_sync[1];
    assign dsp_rst_n   = dsp_sync[1];
    assign timer_rst_n = timer_sync[1];
    assign sram_rst_n  = sram_sync[1];
    assign bfm_rst_n   = bfm_sync[1];

    // ========================================================================
    // AHB 从机接口
    // ========================================================================
    wire ahb_active;
    assign ahb_active = hsel && (htrans == 2'b10);
    assign hresp = 2'b00;              // 始终 OKAY

    always @(posedge hclk or negedge module_rst_raw[4]) begin
        if (!module_rst_raw[4]) begin
            soft_rst <= 5'b11111;      // bfm复位时，软件复位全部释放
            hrdata   <= 32'h0;
            hready   <= 1'b1;
        end else begin
            if (ahb_active && hready) begin
                if (hwrite) begin
                    case (haddr[3:0])
                        4'h0: soft_rst <= hwdata[4:0];  // RMU_SRST
                        default: ;
                    endcase
                    hready <= 1'b1;
                end else begin
                    case (haddr[3:0])
                        4'h0: hrdata <= {27'h0, soft_rst};              // RMU_SRST
                        4'h4: hrdata <= {29'h0, filter_active, por_rst_n, pin_filtered_n};  // RMU_STATUS
                        default: hrdata <= 32'h0;
                    endcase
                    hready <= 1'b1;
                end
            end else begin
                hready <= 1'b1;
            end
        end
    end

endmodule
