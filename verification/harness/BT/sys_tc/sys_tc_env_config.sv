// SYS_TC Environment Configuration (sys_tc_env_config) V1.0
// 基地址: 0x3000_0000
class sys_tc_env_config extends env_config_base;
  `uvm_object_utils(sys_tc_env_config)
  function new(string name = "sys_tc_env_config");
    super.new(name);
    base_addr = 32'h3000_0000;
  endfunction
endclass
