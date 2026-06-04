//--------------------------------------------------------------
// AHB Sequencer (ahb_sequencer)
//
// 功能: UVM sequencer，管理ahb_sequence_item的调度和路由
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class ahb_sequencer extends uvm_sequencer #(ahb_sequence_item);
  `uvm_component_utils(ahb_sequencer)

  function new(string name = "ahb_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "AHB Sequencer built", UVM_MEDIUM)
  endfunction

endclass : ahb_sequencer
