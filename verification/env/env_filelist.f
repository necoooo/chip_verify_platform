../env/uvm_pre_import.sv
//--------------------------------------------------------------
// UVM公共组件Filelist (env_filelist.f)
// 包含: AHB Agent, UART Agent, 公共基类
// 注: 所有路径相对于 sim/ 目录 (VCS CWD)
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

// AHB Agent (模块级与系统级复用核心)
../env/ahb/ahb_if.sv
../env/ahb/ahb_sequence_item.sv
../env/ahb/ahb_sequencer.sv
../env/ahb/ahb_driver.sv
../env/ahb/ahb_monitor.sv
../env/ahb/ahb_agent.sv
../env/ahb/ahb_sequence_lib.sv
../env/ahb/ahb_coverage.sv

// UART物理层Agent (系统级使用)
../env/uart/uart_if.sv
../env/uart/uart_sequence_item.sv
../env/uart/uart_sequencer.sv
../env/uart/uart_driver.sv
../env/uart/uart_monitor.sv
../env/uart/uart_agent.sv

// 公共基类
../env/common/env_config_base.sv
../env/common/test_base.sv
