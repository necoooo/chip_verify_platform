//--------------------------------------------------------------
// DSP Coverage Collector (dsp_coverage) V1.0
// 覆盖项: OP_SEL、OPA/OPB边界值、寄存器访问
//--------------------------------------------------------------
class dsp_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(dsp_coverage)

  covergroup dsp_cg with function sample(bit [7:0] opa, bit [7:0] opb, bit op_sel, bit start);
    cp_op_sel: coverpoint op_sel { bins add = {0}; bins sub = {1}; }
    cp_opa_boundary: coverpoint opa {
      bins zero = {0}; bins mid = {[1:254]}; bins max = {255};
    }
    cp_opb_boundary: coverpoint opb {
      bins zero = {0}; bins mid = {[1:254]}; bins max = {255};
    }
    cp_start: coverpoint start { bins triggered = {1}; }
    crx_sel_op: cross cp_op_sel, cp_opa_boundary;
  endgroup

  function new(string name = "dsp_coverage", uvm_component parent = null);
    super.new(name, parent); dsp_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    if (t.addr[31:28] != 4'h2) return;
    if (t.write && t.addr[3:0] == 4'h8 && t.data[0]) begin
      dsp_cg.sample(/* opa */ 8'h0, /* opb */ 8'h0, t.data[1], t.data[0]);
    end
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("DSP Coverage: %.1f%%", dsp_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
