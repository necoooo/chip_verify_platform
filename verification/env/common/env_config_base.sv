//--------------------------------------------------------------
// Environment Configuration Base Class (env_config_base)
//
// 功能: 所有模块env配置类的公共基类
// 通用配置项: AHB虚拟接口、agent模式、覆盖率使能等
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class env_config_base extends uvm_object;
  `uvm_object_utils(env_config_base)

  // Virtual interfaces
  virtual ahb_if   ahb_vif;       // AHB总线虚拟接口
  virtual uart_if  uart_vif;      // UART物理接口（系统级使用）

  // Agent配置
  bit ahb_is_active    = 1;       // AHB agent模式: 1=active
  bit has_coverage     = 1;       // 是否启用功能覆盖率收集
  bit has_scoreboard   = 1;       // 是否启用scoreboard
  bit has_uart_agent   = 0;       // 是否包含UART agent（系统级启用）

  // 模块基地址（每个模块不同，子类覆盖）
  bit [31:0] base_addr = 32'h0;

  // 仿真控制
  int  reset_wait_cycles = 10;   // 复位后等待周期数

  function new(string name = "env_config_base");
    super.new(name);
  endfunction

endclass : env_config_base
