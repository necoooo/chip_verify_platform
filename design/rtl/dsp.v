// ============================================================================
// DSP 算法模块 — 8位加减法运算单元
// ============================================================================
// 功能：支持ADD/SUB、AHB配置操作数与启动、运算完成中断
// ============================================================================

module dsp (
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
    output reg        done_int
);

    // ========================================================================
    // 寄存器
    // ========================================================================
    reg [7:0]  opa;
    reg [7:0]  opb;
    reg        start;
    reg        op_sel;           // 0=ADD, 1=SUB
    reg [8:0]  result;
    reg        busy;
    reg        done;

    // ========================================================================
    // 运算执行（组合逻辑 → 单周期完成）
    // ========================================================================
    wire [8:0] add_result;
    wire [8:0] sub_result;

    assign add_result = {1'b0, opa} + {1'b0, opb};
    assign sub_result = {1'b0, opa} - {1'b0, opb};

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            opa      <= 8'd0;
            opb      <= 8'd0;
            start    <= 1'b0;
            op_sel   <= 1'b0;
            result   <= 9'd0;
            busy     <= 1'b0;
            done     <= 1'b0;
            done_int <= 1'b0;
        end else begin
            done_int <= 1'b0;

            if (start && !busy) begin
                // 启动运算
                busy <= 1'b1;
                start <= 1'b0;
            end else if (busy) begin
                // 单周期运算
                result <= op_sel ? sub_result : add_result;
                busy   <= 1'b0;
                done   <= 1'b1;
                done_int <= 1'b1;
            end

            // 读 STATUS 后清除 done
            // (在 AHB 读处理中清除)
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
                        4'h0: opa    <= hwdata[7:0];
                        4'h4: opb    <= hwdata[7:0];
                        4'h8: begin
                            start  <= hwdata[0];
                            op_sel <= hwdata[1];
                        end
                        default: ;
                    endcase
                    hready <= 1'b1;
                end else begin
                    case (haddr[3:0])
                        4'h0:  hrdata <= {24'h0, opa};
                        4'h4:  hrdata <= {24'h0, opb};
                        4'h8:  hrdata <= {30'h0, op_sel, start};
                        4'hC:  hrdata <= {23'h0, result};
                        4'h10: begin
                            hrdata <= {30'h0, done, busy};
                            done   <= 1'b0;   // 读后清除
                        end
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
