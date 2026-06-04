// RMU Environment (rmu_env) V1.0
class rmu_env extends uvm_env;
  `uvm_component_utils(rmu_env)

  ahb_agent      ahb_agt;
  rmu_scoreboard scoreboard;
  rmu_coverage   coverage;
  rmu_env_config cfg;

  function new(string name = "rmu_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(rmu_env_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "RMU config not found")
    uvm_config_db #(virtual ahb_if)::set(this, "ahb_agt.*", "ahb_vif", cfg.ahb_vif);
    ahb_agt = ahb_agent::type_id::create("ahb_agt", this);
    if (cfg.has_scoreboard) scoreboard = rmu_scoreboard::type_id::create("scoreboard", this);
    if (cfg.has_coverage)  coverage = rmu_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.has_scoreboard) ahb_agt.monitor.item_collected_port.connect(scoreboard.ahb_export);
    if (cfg.has_coverage)  ahb_agt.monitor.item_collected_port.connect(coverage.analysis_export);
  endfunction
endclass
