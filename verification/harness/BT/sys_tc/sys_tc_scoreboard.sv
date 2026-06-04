//--------------------------------------------------------------
// SYS_TC Scoreboard (sys_tc_scoreboard) V1.0
// 功能: 维护期望计数器值和中断状态，比对DUT实际值
//--------------------------------------------------------------
class sys_tc_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sys_tc_scoreboard)

  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  bit        exp_en, exp_ie;
  bit [31:0] exp_reload;
  bit [31:0] exp_count;

  sys_tc_env_config cfg;

  function new(string name = "sys_tc_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahb_export = new("ahb_export", this);
    ahb_fifo   = new("ahb_fifo", this);
    exp_reload = 32'd49999;  // 默认值
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ahb_export.connect(ahb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    ahb_sequence_item item;
    forever begin
      ahb_fifo.get(item);
      if (item.addr[31:28] != 4'h3) continue;

      if (item.write) begin
        case (item.addr[3:0])
          4'h0: begin exp_en = item.data[0]; exp_ie = item.data[1]; end
          4'h4: exp_reload = item.data;
        endcase
      end else begin
        case (item.addr[3:0])
          4'h0: if ({30'h0, item.rdata[1:0]} != {30'h0, exp_ie, exp_en})
                  `uvm_error(get_type_name(), $sformatf("CTRL mismatch"))
          4'h4: if (item.rdata != exp_reload)
                  `uvm_error(get_type_name(), $sformatf("LOAD mismatch"))
        endcase
      end
    end
  endtask
endclass
