//--------------------------------------------------------------
// RMU Scoreboard (rmu_scoreboard) V1.0
// 功能: 维护期望软复位值，比对DUT实际RMU_SRST/RMU_STATUS
//--------------------------------------------------------------
class rmu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(rmu_scoreboard)

  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  bit [4:0] exp_soft_rst;  // 期望软复位值

  function new(string name = "rmu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahb_export = new("ahb_export", this);
    ahb_fifo   = new("ahb_fifo", this);
    exp_soft_rst = 5'b11111;  // 复位默认释放
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ahb_export.connect(ahb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    ahb_sequence_item item;
    forever begin
      ahb_fifo.get(item);
      if (item.addr[31:28] != 4'h4) continue;

      if (item.write && item.addr[3:0] == 4'h0) begin
        exp_soft_rst = item.data[4:0];
      end else if (!item.write && item.addr[3:0] == 4'h0) begin
        if (item.rdata[4:0] !== exp_soft_rst)
          `uvm_error(get_type_name(),
            $sformatf("RMU_SRST mismatch: exp=0x%h, got=0x%h", exp_soft_rst, item.rdata[4:0]))
      end
    end
  endtask
endclass
