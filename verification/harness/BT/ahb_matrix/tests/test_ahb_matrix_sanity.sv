// AHB Matrix Sanity Test (test_ahb_matrix_sanity) V1.0
class test_ahb_matrix_sanity extends ahb_matrix_base_test;
  `uvm_component_utils(test_ahb_matrix_sanity)
  function new(string n = "test_ahb_matrix_sanity", uvm_component p = null); super.new(n, p); endfunction
  task run_phase(uvm_phase phase);
    ahb_matrix_sanity_seq seq;
    phase.raise_objection(this);
    seq = ahb_matrix_sanity_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
