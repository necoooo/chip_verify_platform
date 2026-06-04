//--------------------------------------------------------------
// DSP Base Test (dsp_base_test) V1.0
//--------------------------------------------------------------
class dsp_base_test extends uvm_test;
  `uvm_component_utils(dsp_base_test)
  dsp_env        env;
  dsp_env_config cfg;

  function new(string name = "dsp_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = dsp_env_config::type_id::create("cfg");
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", cfg.ahb_vif))
      `uvm_fatal(get_type_name(), "AHB vif not found")
    uvm_config_db #(dsp_env_config)::set(this, "env", "cfg", cfg);
    env = dsp_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass
