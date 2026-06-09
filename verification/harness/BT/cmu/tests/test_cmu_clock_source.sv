// CMU Clock Source Test V1.0
class test_cmu_clock_source extends cmu_base_test;
  `uvm_component_utils(test_cmu_clock_source)
  function new(string n = "test_cmu_clock_source", uvm_component p = null); super.new(n, p); endfunction
  task run_phase(uvm_phase phase);
    cmu_clock_source_seq seq;
    phase.raise_objection(this);
    seq = cmu_clock_source_seq::type_id::create("seq");
    if (!seq.randomize()) `uvm_fatal(get_type_name(), "Randomize failed")
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
