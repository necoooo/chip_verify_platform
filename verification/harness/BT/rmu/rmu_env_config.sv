// RMU Environment Configuration (rmu_env_config) V1.0
// 基地址: 0x4000_0000
class rmu_env_config extends env_config_base;
  `uvm_object_utils(rmu_env_config)
  function new(string name = "rmu_env_config");
    super.new(name);
    base_addr = 32'h4000_0000;
  endfunction
endclass
