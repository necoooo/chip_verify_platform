//--------------------------------------------------------------
// CMU Glitch-Free Test V1.0
//--------------------------------------------------------------
class test_cmu_glitch_free extends cmu_base_test;
  `uvm_component_utils(test_cmu_glitch_free)
  function new(string n = "test_cmu_glitch_free", uvm_component p = null); super.new(n, p); endfunction
  task run_phase(uvm_phase phase);
    cmu_glitch_free_seq seq;
    phase.raise_objection(this);
    seq = cmu_glitch_free_seq::type_id::create("seq");
    if (!seq.randomize()) `uvm_fatal(get_type_name(), "Randomize failed")
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
