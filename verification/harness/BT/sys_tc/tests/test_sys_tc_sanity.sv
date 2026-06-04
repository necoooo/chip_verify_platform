// SYS_TC Sanity Test (test_sys_tc_sanity) V1.0
class test_sys_tc_sanity extends sys_tc_base_test;
  `uvm_component_utils(test_sys_tc_sanity)
  function new(string name = "test_sys_tc_sanity", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    sys_tc_sanity_seq seq;
    phase.raise_objection(this);
    seq = sys_tc_sanity_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
