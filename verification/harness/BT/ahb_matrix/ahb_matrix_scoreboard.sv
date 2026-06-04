//--------------------------------------------------------------
// AHB Matrix Scoreboard (ahb_matrix_scoreboard) V1.0
// 功能: 验证地址译码正确性、响应多路复用
//--------------------------------------------------------------
class ahb_matrix_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ahb_matrix_scoreboard)

  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  function new(string name = "ahb_matrix_scoreboard", uvm_component parent = null);
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

  task run_phase(uvm_phase phase);
    ahb_sequence_item item;
    forever begin
      ahb_fifo.get(item);
      // 验证HRESP: 保留地址(6~15)应返回ERROR
      if (item.addr[31:28] > 4'h5) begin
        if (item.resp != 2'b01) begin
          `uvm_error(get_type_name(),
            $sformatf("Reserved addr 0x%08h: expected HRESP=ERROR, got=%0d",
                      item.addr, item.resp))
        end
      end
    end
  endtask
endclass
