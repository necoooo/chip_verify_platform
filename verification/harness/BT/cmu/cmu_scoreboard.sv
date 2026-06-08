// CMU Scoreboard V1.1: 增强CLK_SEL/STATUS一致性+AHB协议+切换计数
class cmu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cmu_scoreboard)
  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  bit        exp_clk_sel;
  int        switch_count, read_count, write_count, error_count;

  function new(string name = "cmu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahb_export = new("ahb_export", this);
    ahb_fifo   = new("ahb_fifo", this);
    exp_clk_sel = 1'b0;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ahb_export.connect(ahb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    ahb_sequence_item item;
    `uvm_info(get_type_name(), "CMU Scoreboard V1.1 starting...", UVM_MEDIUM)
    forever begin
      ahb_fifo.get(item);

      // 仅处理CMU地址空间(0x5000_0000)
      if (item.addr[31:28] != 4'h5) continue;

      if (item.resp != 2'b00) begin
        `uvm_error(get_type_name(), $sformatf("AHB ERROR: addr=0x%0h resp=%b", item.addr, item.resp))
        error_count++;
      end

      if (item.write) begin
        write_count++;
        if (item.addr[11:0] == 12'h000) begin
          if (exp_clk_sel != item.data[0]) switch_count++;
          exp_clk_sel = item.data[0];
        end
      end else begin
        read_count++;
        if (item.addr[11:0] == 12'h000) begin
          if (item.rdata[0] !== exp_clk_sel) begin
            `uvm_error(get_type_name(), $sformatf("CLK_SEL mismatch: exp=%b got=%b", exp_clk_sel, item.rdata[0]))
            error_count++;
          end
        end
        if (item.addr[11:0] == 12'h004) begin
          if (item.rdata[0] !== exp_clk_sel) begin
            `uvm_error(get_type_name(), $sformatf("STATUS[0] mismatch: exp=%b got=%b", exp_clk_sel, item.rdata[0]))
            error_count++;
          end
        end
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("R:%0d W:%0d Sw:%0d Err:%0d", read_count, write_count, switch_count, error_count), UVM_LOW)
  endfunction
endclass
