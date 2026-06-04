// SYS_TC Coverage Collector (sys_tc_coverage) V1.0
class sys_tc_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(sys_tc_coverage)

  covergroup tc_cg with function sample(bit en, bit ie);
    cp_en: coverpoint en;
    cp_ie: coverpoint ie;
    crx_en_ie: cross cp_en, cp_ie;
  endgroup

  function new(string name = "sys_tc_coverage", uvm_component parent = null);
    super.new(name, parent); tc_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    if (t.addr[31:28] == 4'h3 && t.write && t.addr[3:0] == 4'h0)
      tc_cg.sample(t.data[0], t.data[1]);
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("SYS_TC Coverage: %.1f%%", tc_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
