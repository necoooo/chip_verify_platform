//--------------------------------------------------------------
// DSP Environment Configuration (dsp_env_config) V1.0
// 基地址: 0x2000_0000
//--------------------------------------------------------------
class dsp_env_config extends env_config_base;
  `uvm_object_utils(dsp_env_config)
  function new(string name = "dsp_env_config");
    super.new(name);
    base_addr = 32'h2000_0000;
  endfunction
endclass
