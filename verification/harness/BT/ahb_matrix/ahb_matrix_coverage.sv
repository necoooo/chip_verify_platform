// AHB Matrix Coverage Collector (ahb_matrix_coverage) V1.0
class ahb_matrix_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(ahb_matrix_coverage)

  covergroup matrix_cg with function sample(bit [3:0] addr_high, bit [1:0] trans, bit [1:0] resp);
    cp_addr_decode: coverpoint addr_high {
      bins sram  = {4'h0}; bins uart = {4'h1}; bins dsp  = {4'h2};
      bins tc    = {4'h3}; bins rmu  = {4'h4}; bins cmu  = {4'h5};
      bins reserv = {[4'h6:4'hF]};
    }
    cp_trans: coverpoint trans {
      bins idle   = {2'b00}; bins nonseq = {2'b10};
    }
    cp_resp: coverpoint resp { bins okay = {0}; bins err = {1}; }
    crx_addr_resp: cross cp_addr_decode, cp_resp;
  endgroup

  function new(string name = "ahb_matrix_coverage", uvm_component parent = null);
    super.new(name, parent); matrix_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    matrix_cg.sample(t.addr[31:28], t.trans, t.resp);
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("AHB_Matrix Coverage: %.1f%%", matrix_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
