//--------------------------------------------------------------
// CMU Scoreboard (cmu_scoreboard)
//
// 功能: CMU模块参考模型，维护期望的时钟选择状态并与DUT实际值比对
// 检查项: CLK_SEL寄存器读写一致性、时钟源切换状态
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class cmu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cmu_scoreboard)

  // Analysis port订阅AHB monitor输出
  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  // 期望状态
  bit        exp_clk_sel;    // 期望时钟选择值

  // 配置引用
  cmu_env_config cfg;

  function new(string name = "cmu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahb_export = new("ahb_export", this);
    ahb_fifo   = new("ahb_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ahb_export.connect(ahb_fifo.analysis_export);
  endfunction

  //--------------------------------------------------------------
  // Run Phase: 持续检查AHB事务
  //--------------------------------------------------------------
  task run_phase(uvm_phase phase);
    ahb_sequence_item item;

    `uvm_info(get_type_name(), "CMU Scoreboard starting...", UVM_MEDIUM)
    exp_clk_sel = 1'b0;  // 复位默认值

    forever begin
      ahb_fifo.get(item);

      if (item.write) begin
        // 写操作：检查对CMU_CLK_SEL的写入
        if (item.addr[11:0] == 12'h000) begin
          exp_clk_sel = item.data[0];  // 更新期望值
          `uvm_info(get_type_name(),
                    $sformatf("Scoreboard: CMU_CLK_SEL write -> exp_clk_sel=%0b", exp_clk_sel),
                    UVM_MEDIUM)
        end
      end else begin
        // 读操作：比对期望值
        if (item.addr[11:0] == 12'h000) begin
          if (item.rdata[0] !== exp_clk_sel) begin
            `uvm_error(get_type_name(),
                       $sformatf("CMU_CLK_SEL mismatch: expected=%0b, got=%0b",
                                 exp_clk_sel, item.rdata[0]))
          end else begin
            `uvm_info(get_type_name(),
                      $sformatf("CMU_CLK_SEL match: %0b", exp_clk_sel), UVM_MEDIUM)
          end
        end

        if (item.addr[11:0] == 12'h004) begin
          if (item.rdata[0] !== exp_clk_sel) begin
            `uvm_error(get_type_name(),
                       $sformatf("CMU_STATUS[0] mismatch: expected=%0b, got=%0b",
                                 exp_clk_sel, item.rdata[0]))
          end
        end
      end
    end
  endtask

endclass : cmu_scoreboard
