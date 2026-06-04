//--------------------------------------------------------------
// DSP Sanity Test (test_dsp_sanity) V1.0
// 对应测试点: TP_DSP_001.01
//--------------------------------------------------------------
class test_dsp_sanity extends dsp_base_test;
  `uvm_component_utils(test_dsp_sanity)

  function new(string name = "test_dsp_sanity", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dsp_sanity_seq seq;
    phase.raise_objection(this);
    seq = dsp_sanity_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
