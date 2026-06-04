// SRAM_ECC Environment Configuration (sram_ecc_env_config) V1.0
// 基地址: 0x0000_0000
class sram_ecc_env_config extends env_config_base;
  `uvm_object_utils(sram_ecc_env_config)
  function new(string name = "sram_ecc_env_config");
    super.new(name);
    base_addr = 32'h0000_0000;
  endfunction
endclass
