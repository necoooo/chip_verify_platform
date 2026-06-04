// RMU Sanity Test (test_rmu_sanity) V1.0
class test_rmu_sanity extends rmu_base_test;
  `uvm_component_utils(test_rmu_sanity)
  function new(string name = "test_rmu_sanity", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    rmu_sanity_seq seq;
    phase.raise_objection(this);
    seq = rmu_sanity_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
