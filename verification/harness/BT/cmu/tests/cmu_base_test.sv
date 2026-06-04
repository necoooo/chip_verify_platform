//--------------------------------------------------------------
// CMU Base Test (cmu_base_test)
//
// 功能: CMU模块验证test基类，创建cmu_env并配置virtual interface
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class cmu_base_test extends uvm_test;
  `uvm_component_utils(cmu_base_test)

  cmu_env        env;
  cmu_env_config cfg;

  function new(string name = "cmu_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------
  // Build Phase: 创建env和配置
  //--------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // 创建配置
    cfg = cmu_env_config::type_id::create("cfg");

    // 从config_db获取AHB virtual interface
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", cfg.ahb_vif)) begin
      `uvm_fatal(get_type_name(), "AHB virtual interface not found in config_db")
    end

    // 设置配置到config_db供env获取
    uvm_config_db #(cmu_env_config)::set(this, "env", "cfg", cfg);

    // 创建env
    env = cmu_env::type_id::create("env", this);
  endfunction

  //--------------------------------------------------------------
  // End of Elaboration: 打印拓扑
  //--------------------------------------------------------------
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : cmu_base_test
