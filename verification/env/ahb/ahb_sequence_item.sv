//--------------------------------------------------------------
// AHB Sequence Item (ahb_sequence_item)
//
// 功能: 定义AHB-Lite总线传输事务的数据结构
// 字段: 地址/读写控制/数据/传输属性/响应
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class ahb_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(ahb_sequence_item)

  // AHB传输属性
  rand bit [31:0] addr;      // 32位地址
  rand bit        write;     // 1=写, 0=读
  rand bit [31:0] data;      // 32位数据
  rand bit [2:0]  size;      // 传输大小（默认010=32bit）
  rand bit [2:0]  burst;     // 突发类型（默认000=SINGLE）
  rand bit [3:0]  prot;      // 保护控制（默认0011）
  rand bit [1:0]  trans;     // 传输类型（默认10=NONSEQ）

  // 响应字段（monitor填充）
  bit [31:0] rdata;          // 读回数据
  bit [1:0]  resp;           // 传输响应

  //--------------------------------------------------------------
  // 约束
  //--------------------------------------------------------------
  constraint c_size_default  { size  == 3'b010; }   // 固定32位传输
  constraint c_burst_default { burst == 3'b000; }   // 固定SINGLE突发
  constraint c_prot_default  { prot  == 4'b0011; }  // 默认数据访问
  constraint c_trans_default { trans == 2'b10;  }   // 默认NONSEQ传输
  constraint c_addr_aligned  { addr[1:0] == 2'b00; } // 32位对齐

  //--------------------------------------------------------------
  // 构造函数
  //--------------------------------------------------------------
  function new(string name = "ahb_sequence_item");
    super.new(name);
  endfunction

  //--------------------------------------------------------------
  // UVM打印
  //--------------------------------------------------------------
  function string convert2string();
    return $sformatf("AHB %s @ 0x%08h, data=0x%08h, resp=%0d",
                     write ? "WR" : "RD", addr, write ? data : rdata, resp);
  endfunction

  //--------------------------------------------------------------
  // UVM比较
  //--------------------------------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    ahb_sequence_item _rhs;
    if (!$cast(_rhs, rhs)) return 0;
    return (addr  == _rhs.addr)  &&
           (write == _rhs.write) &&
           (data  == _rhs.data)  &&
           (resp  == _rhs.resp);
  endfunction

  //--------------------------------------------------------------
  // UVM复制
  //--------------------------------------------------------------
  function void do_copy(uvm_object rhs);
    ahb_sequence_item _rhs;
    if (!$cast(_rhs, rhs)) begin
      `uvm_error(get_type_name(), "Copy failed: type mismatch")
      return;
    end
    super.do_copy(rhs);
    addr  = _rhs.addr;
    write = _rhs.write;
    data  = _rhs.data;
    size  = _rhs.size;
    burst = _rhs.burst;
    prot  = _rhs.prot;
    trans = _rhs.trans;
    rdata = _rhs.rdata;
    resp  = _rhs.resp;
  endfunction

endclass : ahb_sequence_item
