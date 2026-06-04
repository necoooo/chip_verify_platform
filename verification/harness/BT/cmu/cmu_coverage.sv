//--------------------------------------------------------------
// CMU Coverage Collector (cmu_coverage)
//
// 功能: 收集CMU模块功能覆盖率
// 覆盖项: 时钟源选择值、状态寄存器读取、时钟切换操作
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class cmu_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(cmu_coverage)

  // CMU功能覆盖率组
  covergroup cmu_cg with function sample(ahb_sequence_item item, bit addr_bit);
    // 时钟源选择覆盖
    cp_clk_sel: coverpoint addr_bit {
      bins pll_clk = {0};
      bins rch_clk = {1};
    }

    // 读写操作覆盖
    cp_operation: coverpoint item.write {
      bins read  = {0};
      bins write = {1};
    }

    // 寄存器访问覆盖
    cp_register: coverpoint item.addr[3:0] {
      bins clk_sel  = {4'h0};
      bins status   = {4'h4};
      bins reserved = default;
    }

    // 交叉覆盖: 读写 × 寄存器
    crx_op_reg: cross cp_operation, cp_register;

    // 交叉覆盖: 读写 × 时钟源
    crx_op_clk: cross cp_operation, cp_clk_sel;
  endgroup

  function new(string name = "cmu_coverage", uvm_component parent = null);
    super.new(name, parent);
    cmu_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    // 提取data[0]作为时钟源选择值用于覆盖采样
    bit clk_val;
    if (t.write) begin
      clk_val = t.data[0];
    end else begin
      clk_val = t.rdata[0];
    end
    if (t.addr[31:28] == 4'h5) begin  // CMU地址空间(0x50000000)
      cmu_cg.sample(t, clk_val);
    end
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(),
              $sformatf("CMU Coverage: %.1f%%", cmu_cg.get_coverage()), UVM_LOW)
  endfunction

endclass : cmu_coverage
