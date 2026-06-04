//--------------------------------------------------------------
// CMU Sanity Test (test_cmu_sanity)
//
// 功能: CMU模块sanity测试用例
// 验证: 上电默认时钟源=pll_clk(50MHz)、CLK_SEL默认值=0
// 用例来源: TP_CMU_001.01
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class test_cmu_sanity extends cmu_base_test;
  `uvm_component_utils(test_cmu_sanity)

  function new(string name = "test_cmu_sanity", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    cmu_sanity_seq seq;
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "=== test_cmu_sanity starting ===", UVM_LOW)

    seq = cmu_sanity_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);

    `uvm_info(get_type_name(), "=== test_cmu_sanity finished ===", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass : test_cmu_sanity
