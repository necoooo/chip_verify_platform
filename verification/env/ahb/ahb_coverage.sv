//--------------------------------------------------------------
// AHB Coverage Collector (ahb_coverage)
//
// 功能: 收集AHB-Lite总线协议相关的功能覆盖率
// 覆盖项: 读写类型、传输类型、地址范围、响应类型
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class ahb_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(ahb_coverage)

  // Coverage groups
  covergroup ahb_trans_cg with function sample(ahb_sequence_item item);
    // 读写类型
    cp_write: coverpoint item.write {
      bins read  = {0};
      bins write = {1};
    }

    // 地址范围覆盖（按AHB地址映射区域划分）
    cp_addr_region: coverpoint item.addr[31:28] {
      bins sram_ecc = {4'h0};
      bins uart     = {4'h1};
      bins dsp      = {4'h2};
      bins sys_tc   = {4'h3};
      bins rmu      = {4'h4};
      bins cmu      = {4'h5};
      bins reserved = default;
    }

    // 传输响应
    cp_resp: coverpoint item.resp {
      bins okay  = {2'b00};
      bins error = {2'b01};
    }

    // 读写 x 地址区域交叉覆盖
    crx_write_region: cross cp_write, cp_addr_region;

    // 读写 x 响应交叉覆盖
    crx_write_resp: cross cp_write, cp_resp;
  endgroup

  function new(string name = "ahb_coverage", uvm_component parent = null);
    super.new(name, parent);
    ahb_trans_cg = new();
  endfunction

  //--------------------------------------------------------------
  // write: UVM analysis port回调
  //--------------------------------------------------------------
  function void write(ahb_sequence_item t);
    ahb_trans_cg.sample(t);
  endfunction

  //--------------------------------------------------------------
  // extract_phase: 报告覆盖率
  //--------------------------------------------------------------
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(),
              $sformatf("AHB Coverage: %.1f%%", ahb_trans_cg.get_coverage()), UVM_LOW)
  endfunction

endclass : ahb_coverage
