//--------------------------------------------------------------
// AHB Sequence Library (ahb_sequence_lib)
//
// 功能: AHB基础sequence库，提供常用AHB读写操作sequence
// 包含: 单次读写、寄存器读写、地址遍历、随机读写
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

//--------------------------------------------------------------
// ahb_base_sequence: 所有AHB sequence的基类
//--------------------------------------------------------------
class ahb_base_sequence extends uvm_sequence #(ahb_sequence_item);
  `uvm_object_utils(ahb_base_sequence)

  function new(string name = "ahb_base_sequence");
    super.new(name);
  endfunction

  // V1.1: 测量hclk频率(MHz)
  task measure_hclk_freq(virtual ahb_if vif, input int n_cycles, output real freq_mhz);
    real t0, t1;
    t0 = $realtime; repeat(n_cycles) @(posedge vif.hclk); t1 = $realtime;
    freq_mhz = n_cycles * 1000.0 / (t1 - t0);
  endtask

  // V1.5: 毛刺检测 + 边沿计数调试
  task check_hclk_glitch(virtual ahb_if vif, input int min_half_ns, ref int glitch_cnt, ref int edge_total);
    real t_last, t_now, delta;
    glitch_cnt = 0;
    edge_total = 0;
    t_last = $realtime;
    forever begin
      @(posedge vif.hclk or negedge vif.hclk);
      t_now = $realtime;
      edge_total++;
      delta = t_now - t_last;
      if (t_last > 0 && delta > 0.001 && delta <= min_half_ns) begin
        `uvm_info("GLITCH", $sformatf("hclk glitch: %.3fns", delta), UVM_LOW)
        glitch_cnt++;
      end
      t_last = t_now;
    end
  endtask

  // 辅助任务: AHB写
  task ahb_write(input bit [31:0] addr, input bit [31:0] data);
    ahb_sequence_item item;
    item = ahb_sequence_item::type_id::create("item");
    start_item(item);
    item.addr  = addr;
    item.write = 1'b1;
    item.data  = data;
    finish_item(item);
  endtask

  // 辅助任务: AHB读
  task ahb_read(input bit [31:0] addr, output bit [31:0] data);
    ahb_sequence_item item;
    item = ahb_sequence_item::type_id::create("item");
    start_item(item);
    item.addr  = addr;
    item.write = 1'b0;
    finish_item(item);
    data = item.rdata;
  endtask

  // 辅助任务: 等待指定周期数
  task wait_cycles(input int unsigned n);
    repeat (n) begin
      ahb_sequence_item dummy;
      dummy = ahb_sequence_item::type_id::create("dummy");
      start_item(dummy);
      dummy.addr  = 32'h0;
      dummy.write = 1'b0;
      dummy.trans = 2'b00;  // IDLE
      finish_item(dummy);
    end
  endtask

endclass : ahb_base_sequence

//--------------------------------------------------------------
// ahb_reg_write_seq: 单次寄存器写操作
//--------------------------------------------------------------
class ahb_reg_write_seq extends ahb_base_sequence;
  `uvm_object_utils(ahb_reg_write_seq)

  bit [31:0] reg_addr;
  bit [31:0] reg_data;

  function new(string name = "ahb_reg_write_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), $sformatf("Writing reg 0x%08h = 0x%08h", reg_addr, reg_data), UVM_LOW)
    ahb_write(reg_addr, reg_data);
  endtask

endclass : ahb_reg_write_seq

//--------------------------------------------------------------
// ahb_reg_read_seq: 单次寄存器读操作
//--------------------------------------------------------------
class ahb_reg_read_seq extends ahb_base_sequence;
  `uvm_object_utils(ahb_reg_read_seq)

  bit [31:0] reg_addr;
  bit [31:0] reg_data;

  function new(string name = "ahb_reg_read_seq");
    super.new(name);
  endfunction

  task body();
    ahb_read(reg_addr, reg_data);
    `uvm_info(get_type_name(), $sformatf("Read reg 0x%08h = 0x%08h", reg_addr, reg_data), UVM_LOW)
  endtask

endclass : ahb_reg_read_seq

//--------------------------------------------------------------
// ahb_reg_rw_seq: 寄存器回读验证sequence
// 功能: 写寄存器 → 读回 → 比对
//--------------------------------------------------------------
class ahb_reg_rw_seq extends ahb_base_sequence;
  `uvm_object_utils(ahb_reg_rw_seq)

  bit [31:0] reg_addr;
  bit [31:0] reg_data;
  bit [31:0] exp_data;    // 期望读回值
  bit        status;      // 读写结果状态

  function new(string name = "ahb_reg_rw_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] rd_data;
    `uvm_info(get_type_name(), $sformatf("Reg RW test @ 0x%08h: write=0x%08h, expect=0x%08h",
              reg_addr, reg_data, exp_data), UVM_LOW)
    ahb_write(reg_addr, reg_data);
    ahb_read(reg_addr, rd_data);
    status = (rd_data == exp_data);
    if (!status) begin
      `uvm_error(get_type_name(), $sformatf("Reg mismatch @ 0x%08h: wrote 0x%08h, got 0x%08h, expected 0x%08h",
                reg_addr, reg_data, rd_data, exp_data))
    end
  endtask

endclass : ahb_reg_rw_seq

//--------------------------------------------------------------
// ahb_random_seq: 随机AHB读写sequence
// 功能: 在指定地址范围内随机生成读写事务
//--------------------------------------------------------------
class ahb_random_seq extends ahb_base_sequence;
  `uvm_object_utils(ahb_random_seq)

  bit [31:0] base_addr = 32'h0;
  bit [31:0] addr_range = 32'h1000;
  int        num_trans = 100;

  function new(string name = "ahb_random_seq");
    super.new(name);
  endfunction

  task body();
    ahb_sequence_item item;
    `uvm_info(get_type_name(), $sformatf("Random AHB sequence: %0d transactions", num_trans), UVM_LOW)

    repeat (num_trans) begin
      item = ahb_sequence_item::type_id::create("item");
      start_item(item);
      if (!item.randomize() with {
        addr  inside {[base_addr : base_addr + addr_range - 1]};
        addr[1:0] == 2'b00;
      }) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      finish_item(item);
    end
  endtask

endclass : ahb_random_seq
