// ============================================================================
// 系统定时器 (SYS_TC) — 可配置向下计数定时器
// ============================================================================
// 功能：32位向下计数、自动重载、可屏蔽中断、AHB可配周期、默认1ms@50MHz
// ============================================================================

module sys_tc (
    // 时钟和复位
    input  wire       hclk,
    input  wire       hresetn,

    // AHB 从机接口
    input  wire       hsel,
    input  wire [31:0] haddr,
    input  wire       hwrite,
    input  wire [1:0] htrans,
    input  wire [31:0] hwdata,
    output reg  [31:0] hrdata,
    output reg        hready,
    output wire [1:0] hresp,

    // 中断
    output reg        tc_int
);

    // ========================================================================
    // 寄存器
    // ========================================================================
    reg        en;               // 定时器使能
    reg        ie;               // 中断使能
    reg [31:0] reload;           // 重载值
    reg [31:0] count;            // 当前计数值
    reg        int_flag;         // 中断标志
    reg        count_zero_p;     // 计数到零脉冲（单周期）

    // ========================================================================
    // 向下计数器
    // ========================================================================
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            en       <= 1'b0;
            ie       <= 1'b0;
            reload   <= 32'd49999;    // 1ms @ 50MHz
            count    <= 32'd49999;
        end else begin
            if (en) begin
                if (count == 32'd0) begin
                    count <= reload;
                end else begin
                    count <= count - 32'd1;
                end
            end
        end
    end

    // 计数到零检测
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            count_zero_p <= 1'b0;
        end else begin
            count_zero_p <= en && (count == 32'd1);  // 下一拍将到零
            // 修正：实际到零时检测
            if (en && (count == 32'd0)) begin
                count_zero_p <= 1'b1;
            end else begin
                count_zero_p <= 1'b0;
            end
        end
    end

    // 中断标志与中断输出
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            int_flag <= 1'b0;
            tc_int   <= 1'b0;
        end else begin
            if (count == 32'd0 && en) begin
                int_flag <= 1'b1;
                tc_int   <= ie;        // 单周期中断脉冲
            end else begin
                tc_int <= 1'b0;
            end
            // 写1清零
            // (在 AHB 写处理中实现)
        end
    end

    // ========================================================================
    // AHB 从机接口
    // ========================================================================
    wire ahb_active;
    assign ahb_active = hsel && (htrans == 2'b10);
    assign hresp = 2'b00;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            hrdata <= 32'h0;
            hready <= 1'b1;
        end else begin
            if (ahb_active && hready) begin
                if (hwrite) begin
                    case (haddr[3:0])
                        4'h0: begin
                            en <= hwdata[0];
                            ie <= hwdata[1];
                            if (hwdata[0] && count == 32'd0) begin
                                count <= reload;  // 使能时若计数为0，重新加载
                            end
                        end
                        4'h4: begin
                            reload <= hwdata;
                            if (!en) begin
                                count <= hwdata;  // 停止时同步更新计数值
                            end
                        end
                        4'hC: begin
                            if (hwdata[0]) begin
                                int_flag <= 1'b0;  // 写1清零
                                tc_int   <= 1'b0;
                            end
                        end
                        default: ;
                    endcase
                    hready <= 1'b1;
                end else begin
                    case (haddr[3:0])
                        4'h0:  hrdata <= {30'h0, ie, en};
                        4'h4:  hrdata <= reload;
                        4'h8:  hrdata <= count;
                        4'hC:  hrdata <= {31'h0, int_flag};
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
