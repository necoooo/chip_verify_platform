//--------------------------------------------------------------
// CMU Environment (cmu_env)
//
// 功能: CMU模块UVM验证环境顶层
// 组件: ahb_agent(复用) + cmu_scoreboard + cmu_coverage
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class cmu_env extends uvm_env;
  `uvm_component_utils(cmu_env)

  // 公共组件（复用）
  ahb_agent      ahb_agt;

  // CMU专用组件
  cmu_scoreboard scoreboard;
  cmu_coverage   coverage;

  // 配置
  cmu_env_config cfg;

  function new(string name = "cmu_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------
  // Build Phase: 创建和配置所有子组件
  //--------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // 获取配置
    if (!uvm_config_db #(cmu_env_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "CMU env config not found in config_db")
    end

    // 设置AHB agent配置
    uvm_config_db #(virtual ahb_if)::set(this, "ahb_agt.*", "ahb_vif", cfg.ahb_vif);

    // 创建AHB agent（active模式）
    ahb_agt = ahb_agent::type_id::create("ahb_agt", this);

    // 创建CMU组件
    if (cfg.has_scoreboard) begin
      scoreboard = cmu_scoreboard::type_id::create("scoreboard", this);
    end
    if (cfg.has_coverage) begin
      coverage = cmu_coverage::type_id::create("coverage", this);
    end
  endfunction

  //--------------------------------------------------------------
  // Connect Phase: 连接monitor输出到scoreboard和coverage
  //--------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.has_scoreboard) begin
      ahb_agt.monitor.item_collected_port.connect(scoreboard.ahb_export);
    end
    if (cfg.has_coverage) begin
      ahb_agt.monitor.item_collected_port.connect(coverage.analysis_export);
    end
  endfunction

endclass : cmu_env
