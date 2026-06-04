//--------------------------------------------------------------
// AHB Agent (ahb_agent)
//
// 功能: 封装AHB-Lite验证组件(driver/sequencer/monitor)
// 模式: active=driver+sequencer+monitor / passive=monitor only
// 复用: 模块级和系统级验证环境通用组件
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class ahb_agent extends uvm_agent;
  `uvm_component_utils(ahb_agent)

  // 子组件
  ahb_driver    driver;
  ahb_sequencer sequencer;
  ahb_monitor   monitor;

  // 配置
  bit is_active = 1;  // 1=active模式(含driver和sequencer), 0=passive模式(仅monitor)

  function new(string name = "ahb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------
  // Build Phase: 根据is_active创建子组件
  //--------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    monitor = ahb_monitor::type_id::create("monitor", this);

    if (is_active) begin
      driver    = ahb_driver::type_id::create("driver", this);
      sequencer = ahb_sequencer::type_id::create("sequencer", this);
      `uvm_info(get_type_name(), "AHB Agent configured as ACTIVE", UVM_MEDIUM)
    end else begin
      `uvm_info(get_type_name(), "AHB Agent configured as PASSIVE", UVM_MEDIUM)
    end
  endfunction

  //--------------------------------------------------------------
  // Connect Phase: 连接driver和sequencer
  //--------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : ahb_agent
