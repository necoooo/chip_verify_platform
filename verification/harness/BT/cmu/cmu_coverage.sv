// CMU Coverage V1.1: 增强覆盖点(clk_sel值/切换次数/STATUS/非法地址)
class cmu_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(cmu_coverage)

  int switch_count;

  covergroup cmu_cg with function sample(ahb_sequence_item item, bit clk_val, bit is_clk_sel, bit is_status, bit is_illegal);
    cp_clk_sel: coverpoint clk_val iff (is_clk_sel) { bins pll={0}; bins rch={1}; }
    cp_status:  coverpoint clk_val iff (is_status)  { bins pll_active={0}; bins rch_active={1}; }
    cp_operation: coverpoint item.write { bins read={0}; bins write={1}; }
    cp_register: coverpoint item.addr[3:0] { bins clk_sel={4'h0}; bins status={4'h4}; bins reserved=default; }
    cp_illegal: coverpoint is_illegal { bins legal={0}; bins illegal={1}; }
    cp_switch_cnt: coverpoint switch_count { bins zero={0}; bins low={[1:5]}; bins med={[6:20]}; bins high=default; }
    crx_op_reg: cross cp_operation, cp_register;
    crx_op_clk: cross cp_operation, cp_clk_sel;
    crx_reg_clk: cross cp_register, cp_clk_sel;
  endgroup

  function new(string name = "cmu_coverage", uvm_component parent = null);
    super.new(name, parent); cmu_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    bit clk_val, is_clk_sel, is_status, is_illegal;
    if (t.addr[31:28] != 4'h5) return;
    clk_val = t.write ? t.data[0] : t.rdata[0];
    is_clk_sel = (t.addr[3:0] == 4'h0);
    is_status  = (t.addr[3:0] == 4'h4);
    is_illegal = !is_clk_sel && !is_status;
    if (t.write && is_clk_sel) switch_count++;
    cmu_cg.sample(t, clk_val, is_clk_sel, is_status, is_illegal);
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("CMU Coverage: %.1f%% (%0d switches)", cmu_cg.get_coverage(), switch_count), UVM_LOW)
  endfunction
endclass
