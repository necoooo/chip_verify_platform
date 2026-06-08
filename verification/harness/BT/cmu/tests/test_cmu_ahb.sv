//--------------------------------------------------------------
// CMU AHB Test V1.0
//--------------------------------------------------------------
class test_cmu_ahb extends cmu_base_test;
  `uvm_component_utils(test_cmu_ahb)
  function new(string n = "test_cmu_ahb", uvm_component p = null); super.new(n, p); endfunction
  task run_phase(uvm_phase phase);
    cmu_ahb_seq seq;
    phase.raise_objection(this);
    seq = cmu_ahb_seq::type_id::create("seq");
    if (!seq.randomize()) `uvm_fatal(get_type_name(), "Randomize failed")
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
