//--------------------------------------------------------------
// DSP Environment (dsp_env) V1.0
// 组件: ahb_agent(复用) + dsp_scoreboard + dsp_coverage
//--------------------------------------------------------------
class dsp_env extends uvm_env;
  `uvm_component_utils(dsp_env)

  ahb_agent      ahb_agt;
  dsp_scoreboard scoreboard;
  dsp_coverage   coverage;
  dsp_env_config cfg;

  function new(string name = "dsp_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(dsp_env_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "DSP config not found")
    uvm_config_db #(virtual ahb_if)::set(this, "ahb_agt.*", "ahb_vif", cfg.ahb_vif);
    ahb_agt = ahb_agent::type_id::create("ahb_agt", this);
    if (cfg.has_scoreboard) scoreboard = dsp_scoreboard::type_id::create("scoreboard", this);
    if (cfg.has_coverage)  coverage = dsp_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.has_scoreboard) ahb_agt.monitor.item_collected_port.connect(scoreboard.ahb_export);
    if (cfg.has_coverage)  ahb_agt.monitor.item_collected_port.connect(coverage.analysis_export);
  endfunction
endclass
