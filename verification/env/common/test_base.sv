//--------------------------------------------------------------
// Test Base Class (test_base)
//
// 功能: 所有模块验证test的公共基类
// 提供: 公共phase控制、超时机制、覆盖率报告
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class test_base extends uvm_test;
  `uvm_component_utils(test_base)

  // 环境组件引用（子类负责创建具体类型）
  uvm_env        env;
  env_config_base cfg;

  // 仿真超时（默认100万周期 @ 50MHz = 20ms）
  int timeout_cycles = 1000000;

  function new(string name = "test_base", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------
  // Build Phase: 创建配置对象
  //--------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = env_config_base::type_id::create("cfg");
  endfunction

  //--------------------------------------------------------------
  // End of Elaboration Phase: 打印testbench拓扑
  //--------------------------------------------------------------
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Testbench topology:", UVM_LOW)
    uvm_top.print_topology();
  endfunction

  //--------------------------------------------------------------
  // Run Phase: 设置超时看门狗
  //--------------------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Test starting...", UVM_LOW)

    // 超时保护
    fork
      begin
        repeat (timeout_cycles) @(posedge cfg.ahb_vif.hclk);
        `uvm_fatal(get_type_name(), $sformatf("Test timeout after %0d cycles!", timeout_cycles))
      end
    join_none
  endtask

  //--------------------------------------------------------------
  // Report Phase: 打印测试结果摘要
  //--------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
              $sformatf("Test %s completed. UVM_ERROR=%0d, UVM_FATAL=%0d",
                        get_name(), uvm_report_server::get_server().get_severity_count(UVM_ERROR),
                        uvm_report_server::get_server().get_severity_count(UVM_FATAL)),
              UVM_LOW)
  endfunction

endclass : test_base
