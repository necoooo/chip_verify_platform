// AHB Matrix Environment Configuration (ahb_matrix_env_config) V1.0
class ahb_matrix_env_config extends env_config_base;
  `uvm_object_utils(ahb_matrix_env_config)
  function new(string name = "ahb_matrix_env_config");
    super.new(name);
    base_addr = 32'h0000_0000;  // Matrix无固定基地址，但不影响配置
  endfunction
endclass
