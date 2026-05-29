// ============================================================================
// UART 通信模块 — 标准异步串行收发器
// ============================================================================
// 功能：115200bps / 8N1 / 全双工 / AHB可配波特率
// ============================================================================

module uart (
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

    // UART 引脚
    output reg        uart_tx,
    input  wire       uart_rx,

    // 中断
    output wire       tx_int,
    output wire       rx_int
);

    // ========================================================================
    // 寄存器
    // ========================================================================
    reg        tx_en, rx_en;
    reg [15:0] baud_div;
    reg [7:0]  tx_data;
    reg [7:0]  rx_data;
    reg        tx_busy, tx_done, rx_valid, rx_overflow, frame_err;

    // ========================================================================
    // 波特率发生器
    // ========================================================================
    reg [15:0] baud_cnt;
    wire       baud_tick;
    assign baud_tick = (baud_cnt == 16'd0);

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            baud_cnt <= 16'd0;
        end else begin
            if (baud_tick || !tx_en && !rx_en) begin
                baud_cnt <= baud_div;
            end else begin
                baud_cnt <= baud_cnt - 16'd1;
            end
        end
    end

    // ========================================================================
    // TX 状态机
    // ========================================================================
    localparam TX_IDLE   = 3'd0;
    localparam TX_START  = 3'd1;
    localparam TX_DATA   = 3'd2;
    localparam TX_STOP   = 3'd3;

    reg [2:0] tx_state;
    reg [2:0] tx_bit_cnt;
    reg [7:0] tx_shift;
    reg       tx_start_pulse;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            tx_state       <= TX_IDLE;
            tx_bit_cnt     <= 3'd0;
            tx_shift       <= 8'd0;
            tx_busy        <= 1'b0;
            tx_done        <= 1'b0;
            uart_tx        <= 1'b1;   // 空闲高电平
            tx_start_pulse <= 1'b0;
        end else begin
            tx_start_pulse <= 1'b0;
            tx_done        <= 1'b0;

            case (tx_state)
                TX_IDLE: begin
                    uart_tx  <= 1'b1;
                    tx_busy  <= 1'b0;
                    if (tx_start_pulse && tx_en) begin
                        tx_shift   <= tx_data;
                        tx_bit_cnt <= 3'd0;
                        tx_state   <= TX_START;
                        tx_busy    <= 1'b1;
                    end
                end

                TX_START: begin
                    if (baud_tick) begin
                        uart_tx    <= 1'b0;   // 起始位
                        tx_state   <= TX_DATA;
                    end
                end

                TX_DATA: begin
                    if (baud_tick) begin
                        uart_tx    <= tx_shift[0];       // LSB first
                        tx_shift   <= {1'b0, tx_shift[7:1]};
                        tx_bit_cnt <= tx_bit_cnt + 3'd1;
                        if (tx_bit_cnt == 3'd7) begin
                            tx_state <= TX_STOP;
                        end
                    end
                end

                TX_STOP: begin
                    if (baud_tick) begin
                        uart_tx  <= 1'b1;   // 停止位
                        tx_done  <= 1'b1;
                        tx_busy  <= 1'b0;
                        tx_state <= TX_IDLE;
                    end
                end

                default: tx_state <= TX_IDLE;
            endcase
        end
    end

    // ========================================================================
    // RX 状态机（16倍过采样）
    // ========================================================================
    localparam RX_IDLE   = 3'd0;
    localparam RX_START  = 3'd1;
    localparam RX_DATA   = 3'd2;
    localparam RX_STOP   = 3'd3;

    reg [2:0]  rx_state;
    reg [2:0]  rx_bit_cnt;
    reg [7:0]  rx_shift;
    reg        rx_sync1, rx_sync2;     // 同步器
    reg        rx_prev;

    // 同步器（避免亚稳态）
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
            rx_prev  <= 1'b1;
        end else begin
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
            rx_prev  <= rx_sync2;
        end
    end

    // 起始位下降沿检测
    wire rx_falling;
    assign rx_falling = rx_prev && !rx_sync2;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            rx_state    <= RX_IDLE;
            rx_bit_cnt  <= 3'd0;
            rx_shift    <= 8'd0;
            rx_data     <= 8'd0;
            rx_valid    <= 1'b0;
            rx_overflow <= 1'b0;
            frame_err   <= 1'b0;
        end else begin
            rx_valid <= 1'b0;

            case (rx_state)
                RX_IDLE: begin
                    frame_err <= 1'b0;
                    if (rx_falling && rx_en) begin
                        rx_state   <= RX_START;
                        rx_bit_cnt <= 3'd0;
                    end
                end

                RX_START: begin
                    if (baud_tick) begin
                        // 在半位处验证起始位
                        if (!rx_sync2) begin
                            rx_state <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE;  // 假起始位
                        end
                    end
                end

                RX_DATA: begin
                    if (baud_tick) begin
                        rx_shift    <= {rx_sync2, rx_shift[7:1]};
                        rx_bit_cnt  <= rx_bit_cnt + 3'd1;
                        if (rx_bit_cnt == 3'd7) begin
                            rx_state <= RX_STOP;
                        end
                    end
                end

                RX_STOP: begin
                    if (baud_tick) begin
                        if (rx_sync2) begin
                            rx_data  <= rx_shift;
                            rx_valid <= 1'b1;
                            if (rx_valid) begin
                                rx_overflow <= 1'b1;  // 前一个数据未被读取
                            end
                        end else begin
                            frame_err <= 1'b1;
                        end
                        rx_state <= RX_IDLE;
                    end
                end

                default: rx_state <= RX_IDLE;
            endcase
        end
    end

    assign tx_int = tx_done;
    assign rx_int = rx_valid;

    // ========================================================================
    // AHB 从机接口
    // ========================================================================
    wire ahb_active;
    assign ahb_active = hsel && (htrans == 2'b10);
    assign hresp = 2'b00;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            tx_en      <= 1'b1;
            rx_en      <= 1'b1;
            baud_div   <= 16'd433;     // 115200 @ 50MHz
            tx_data    <= 8'd0;
            hready     <= 1'b1;
            hrdata     <= 32'h0;
        end else begin
            // 读后自动清零
            if (ahb_active && !hwrite && haddr[3:0] == 4'h8 && hready) begin
                // 读取 STATUS 后清除 TX_DONE 和 RX_VALID
                // （状态位在读操作后自动清除）
            end

            if (ahb_active && hready) begin
                if (hwrite) begin
                    case (haddr[3:0])
                        4'h0: begin
                            tx_en <= hwdata[0];
                            rx_en <= hwdata[1];
                        end
                        4'h4: baud_div <= hwdata[15:0];
                        4'hC: begin
                            tx_data        <= hwdata[7:0];
                            tx_start_pulse <= 1'b1;
                        end
                        default: ;
                    endcase
                    hready <= 1'b1;
                end else begin
                    case (haddr[3:0])
                        4'h0: hrdata <= {27'h0, 3'b0, rx_en, tx_en};
                        4'h4: hrdata <= {16'h0, baud_div};
                        4'h8: begin
                            hrdata   <= {27'h0, frame_err, rx_overflow, rx_valid, tx_done, tx_busy};
                            // 读后自动清除
                            tx_done  <= 1'b0;
                            rx_valid <= 1'b0;
                            rx_overflow <= 1'b0;
                            frame_err   <= 1'b0;
                        end
                        4'hC: hrdata <= {24'h0, tx_data};
                        4'h10: hrdata <= {24'h0, rx_data};
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
