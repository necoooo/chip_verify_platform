//--------------------------------------------------------------
// CMU Reset Test V1.0
//--------------------------------------------------------------
class test_cmu_reset extends cmu_base_test;
  `uvm_component_utils(test_cmu_reset)
  function new(string n = "test_cmu_reset", uvm_component p = null); super.new(n, p); endfunction
  task run_phase(uvm_phase phase);
    cmu_reset_seq seq;
    phase.raise_objection(this);
    seq = cmu_reset_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
