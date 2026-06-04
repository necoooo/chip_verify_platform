// UART Environment Configuration (uart_env_config) V1.0
// 基地址: 0x1000_0000
class uart_env_config extends env_config_base;
  `uvm_object_utils(uart_env_config)
  function new(string name = "uart_env_config");
    super.new(name);
    base_addr = 32'h1000_0000;
  endfunction
endclass
