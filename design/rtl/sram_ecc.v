// ============================================================================
// SRAM_ECC — 带ECC保护的SRAM (256×32bit, SEC-DED)
// ============================================================================
// 功能：AHB读写、(39,32)扩展汉明码、单bit纠错、双bit检错
// ============================================================================

module sram_ecc (
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

    // ECC 状态指示
    output reg        ecc_err,       // ECC 错误发生
    output reg        ecc_sec,       // 单bit错误已纠正
    output reg        ecc_ded        // 双bit错误已检测
);

    // ========================================================================
    // SRAM 存储阵列：256 × 39 bit (32 data + 7 ECC)
    // ========================================================================
    reg [38:0] sram [0:255];          // [38:32]=ECC, [31:0]=数据
    integer    sram_init_idx;

    // ========================================================================
    // 数据位置映射 (39-bit codeword, positions 1-38, 0-indexed in array)
    // data_pos[i] = codeword bit position (1-indexed) for data bit i
    // ========================================================================
    reg [5:0]  data_pos [0:31];      // 6 bits to represent positions 1-38
    integer    init_i;
    // Array for reverse lookup: syndrome → which data bit to flip
    reg [4:0]  syn_to_data [1:38];   // position → data bit index (0-31), or 5'h1F if check bit

    initial begin
        // Data positions in codeword (non-power-of-2 positions from 1 to 38)
        data_pos[0]  = 6'd3;  data_pos[1]  = 6'd5;  data_pos[2]  = 6'd6;
        data_pos[3]  = 6'd7;  data_pos[4]  = 6'd9;  data_pos[5]  = 6'd10;
        data_pos[6]  = 6'd11; data_pos[7]  = 6'd12; data_pos[8]  = 6'd13;
        data_pos[9]  = 6'd14; data_pos[10] = 6'd15; data_pos[11] = 6'd17;
        data_pos[12] = 6'd18; data_pos[13] = 6'd19; data_pos[14] = 6'd20;
        data_pos[15] = 6'd21; data_pos[16] = 6'd22; data_pos[17] = 6'd23;
        data_pos[18] = 6'd24; data_pos[19] = 6'd25; data_pos[20] = 6'd26;
        data_pos[21] = 6'd27; data_pos[22] = 6'd28; data_pos[23] = 6'd29;
        data_pos[24] = 6'd30; data_pos[25] = 6'd31; data_pos[26] = 6'd33;
        data_pos[27] = 6'd34; data_pos[28] = 6'd35; data_pos[29] = 6'd36;
        data_pos[30] = 6'd37; data_pos[31] = 6'd38;

        // Reverse lookup initialization
        for (init_i = 0; init_i < 32; init_i = init_i + 1) begin
            syn_to_data[data_pos[init_i]] = init_i[4:0];
        end
    end

    // ========================================================================
    // ECC 编码函数：32bit data → 7bit ECC
    // ========================================================================
    function [6:0] ecc_encode;
        input [31:0] data;
        integer i, j;
        reg [5:0] p;     // 6 SEC check bits
        reg       p0;    // overall parity
        begin
            p = 6'd0;
            // Compute each SEC check bit
            for (i = 0; i < 32; i = i + 1) begin
                for (j = 0; j < 6; j = j + 1) begin
                    if (data_pos[i][j]) begin
                        p[j] = p[j] ^ data[i];
                    end
                end
            end
            // Overall parity (even parity over data + 6 SEC bits)
            p0 = (^data) ^ (^p);
            ecc_encode = {p0, p};
        end
    endfunction

    // ========================================================================
    // ECC 解码与纠错
    // ========================================================================
    function [31:0] ecc_decode;
        input [38:0] codeword;           // [38:32]=ECC_stored, [31:0]=data_stored
        output reg single_err;
        output reg double_err;
        integer i, j;
        reg [5:0] p_calc;                // Recalculated SEC check bits
        reg [5:0] syndrome;
        reg       p0_stored, p0_calc;
        reg       p0_mismatch;
        reg [31:0] corrected_data;
        reg [5:0] err_pos;               // Error position in codeword (1-indexed)
        begin
            // Separate stored values
            p0_stored = codeword[38];
            // p[6:1] stored at codeword[37:32]
            // data at codeword[31:0]

            // Recalculate ECC
            p_calc = 6'd0;
            for (i = 0; i < 32; i = i + 1) begin
                for (j = 0; j < 6; j = j + 1) begin
                    if (data_pos[i][j]) begin
                        p_calc[j] = p_calc[j] ^ codeword[i];
                    end
                end
            end

            // Recalculate overall parity
            p0_calc = (^codeword[31:0]) ^ (^p_calc);

            // Syndrome
            syndrome = p_calc ^ codeword[37:32];
            p0_mismatch = p0_calc ^ p0_stored;

            corrected_data = codeword[31:0];
            single_err = 1'b0;
            double_err = 1'b0;
            err_pos = syndrome;

            if (syndrome == 6'd0) begin
                if (p0_mismatch) begin
                    // Only p0 bit error (minor, data is correct)
                    single_err = 1'b1;
                end
                // else: no error
            end else begin
                if (p0_mismatch) begin
                    // Single-bit error: syndrome indicates position to flip
                    single_err = 1'b1;
                    // Check if error is in a data bit position
                    if (err_pos == 6'd3)  corrected_data[0]  = ~corrected_data[0];
                    else if (err_pos == 6'd5)  corrected_data[1]  = ~corrected_data[1];
                    else if (err_pos == 6'd6)  corrected_data[2]  = ~corrected_data[2];
                    else if (err_pos == 6'd7)  corrected_data[3]  = ~corrected_data[3];
                    else if (err_pos == 6'd9)  corrected_data[4]  = ~corrected_data[4];
                    else if (err_pos == 6'd10) corrected_data[5]  = ~corrected_data[5];
                    else if (err_pos == 6'd11) corrected_data[6]  = ~corrected_data[6];
                    else if (err_pos == 6'd12) corrected_data[7]  = ~corrected_data[7];
                    else if (err_pos == 6'd13) corrected_data[8]  = ~corrected_data[8];
                    else if (err_pos == 6'd14) corrected_data[9]  = ~corrected_data[9];
                    else if (err_pos == 6'd15) corrected_data[10] = ~corrected_data[10];
                    else if (err_pos == 6'd17) corrected_data[11] = ~corrected_data[11];
                    else if (err_pos == 6'd18) corrected_data[12] = ~corrected_data[12];
                    else if (err_pos == 6'd19) corrected_data[13] = ~corrected_data[13];
                    else if (err_pos == 6'd20) corrected_data[14] = ~corrected_data[14];
                    else if (err_pos == 6'd21) corrected_data[15] = ~corrected_data[15];
                    else if (err_pos == 6'd22) corrected_data[16] = ~corrected_data[16];
                    else if (err_pos == 6'd23) corrected_data[17] = ~corrected_data[17];
                    else if (err_pos == 6'd24) corrected_data[18] = ~corrected_data[18];
                    else if (err_pos == 6'd25) corrected_data[19] = ~corrected_data[19];
                    else if (err_pos == 6'd26) corrected_data[20] = ~corrected_data[20];
                    else if (err_pos == 6'd27) corrected_data[21] = ~corrected_data[21];
                    else if (err_pos == 6'd28) corrected_data[22] = ~corrected_data[22];
                    else if (err_pos == 6'd29) corrected_data[23] = ~corrected_data[23];
                    else if (err_pos == 6'd30) corrected_data[24] = ~corrected_data[24];
                    else if (err_pos == 6'd31) corrected_data[25] = ~corrected_data[25];
                    else if (err_pos == 6'd33) corrected_data[26] = ~corrected_data[26];
                    else if (err_pos == 6'd34) corrected_data[27] = ~corrected_data[27];
                    else if (err_pos == 6'd35) corrected_data[28] = ~corrected_data[28];
                    else if (err_pos == 6'd36) corrected_data[29] = ~corrected_data[29];
                    else if (err_pos == 6'd37) corrected_data[30] = ~corrected_data[30];
                    else if (err_pos == 6'd38) corrected_data[31] = ~corrected_data[31];
                    // else: error in check bit, data is fine
                end else begin
                    // Double-bit error (syndrome≠0 but p0 matches) — uncorrectable
                    double_err = 1'b1;
                end
            end

            ecc_decode = corrected_data;
        end
    endfunction

    // ========================================================================
    // ECC 状态寄存器
    // ========================================================================
    reg [7:0]  ecc_err_cnt;
    reg [9:0]  ecc_err_addr;
    reg        ecc_inject_en;         // Error injection enable (for testing)

    // ========================================================================
    // 读写逻辑
    // ========================================================================
    wire        ahb_active;
    wire [7:0]  word_addr;
    wire [38:0] wr_codeword;
    wire [38:0] rd_codeword;
    wire [31:0] rd_data_corrected;
    wire        rd_single_err;
    wire        rd_double_err;

    assign ahb_active = hsel && (htrans == 2'b10);
    assign hresp = 2'b00;

    // 字地址：HADDR[9:2] — 256 word range
    assign word_addr = haddr[9:2];

    // 写码字 = data + ECC
    assign wr_codeword = {ecc_encode(hwdata), hwdata};

    // 读码字
    assign rd_codeword = sram[word_addr];

    // ECC 解码
    assign rd_data_corrected = ecc_decode(rd_codeword, rd_single_err, rd_double_err);

    // ========================================================================
    // AHB 读写控制
    // ========================================================================
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            hready     <= 1'b1;
            hrdata     <= 32'h0;
            ecc_err    <= 1'b0;
            ecc_sec    <= 1'b0;
            ecc_ded    <= 1'b0;
            ecc_err_cnt <= 8'd0;
            ecc_err_addr <= 10'd0;
            ecc_inject_en <= 1'b0;
        end else begin
            ecc_err <= 1'b0;
            ecc_sec <= 1'b0;
            ecc_ded <= 1'b0;

            if (ahb_active && hready) begin
                if (hwrite) begin
                    // 写操作
                    if (haddr[11:10] == 2'b00) begin
                        // SRAM 数据空间 (0x000 - 0x3FF)
                        if (ecc_inject_en) begin
                            // 错误注入模式：翻转 bit0
                            sram[word_addr] <= {wr_codeword[38:1], ~wr_codeword[0]};
                        end else begin
                            sram[word_addr] <= wr_codeword;
                        end
                    end else begin
                        // ECC 控制寄存器空间 (0x400+)
                        case (haddr[11:0])
                            12'h408: ecc_inject_en <= hwdata[0];
                            default: ;
                        endcase
                    end
                    hready <= 1'b1;
                end else begin
                    // 读操作
                    if (haddr[11:10] == 2'b00) begin
                        // SRAM 数据空间
                        hrdata <= rd_data_corrected;
                        if (rd_single_err) begin
                            ecc_err    <= 1'b1;
                            ecc_sec    <= 1'b1;
                            ecc_err_cnt <= ecc_err_cnt + 8'd1;
                            ecc_err_addr <= word_addr;
                        end
                        if (rd_double_err) begin
                            ecc_err    <= 1'b1;
                            ecc_ded    <= 1'b1;
                            ecc_err_cnt <= ecc_err_cnt + 8'd1;
                            ecc_err_addr <= word_addr;
                            hrdata <= 32'hDEAD_BEEF;  // Indicate uncorrectable error
                        end
                    end else begin
                        // ECC 状态寄存器空间
                        case (haddr[11:0])
                            12'h400: hrdata <= {24'h0, ecc_err_cnt};
                            12'h404: hrdata <= {22'h0, ecc_err_addr};
                            12'h408: hrdata <= {31'h0, ecc_inject_en};
                            default: hrdata <= 32'h0;
                        endcase
                    end
                    hready <= 1'b1;
                end
            end else begin
                hready <= 1'b1;
            end
        end
    end

endmodule
