//--------------------------------------------------------------
// AHB Driver (ahb_driver)
//
// 功能: 实现AHB-Lite Master协议，在virtual interface上驱动读写传输
// 协议: 2阶段传输（地址阶段 + 数据阶段），支持HREADY等待
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class ahb_driver extends uvm_driver #(ahb_sequence_item);
  `uvm_component_utils(ahb_driver)

  // Virtual interface
  virtual ahb_if vif;

  // 配置
  bit disable_hready_wait = 0;  // 禁止hready等待（加速仿真，默认允许等待）

  function new(string name = "ahb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------
  // Build Phase: 获取virtual interface
  //--------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual AHB interface not found in config_db")
    end
  endfunction

  //--------------------------------------------------------------
  // Run Phase: 主驱动循环
  //--------------------------------------------------------------
  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "AHB Driver starting...", UVM_MEDIUM)

    // 复位等待
    @(posedge vif.hclk);
    while (!vif.hresetn) begin
      @(posedge vif.hclk);
    end
    repeat (5) @(posedge vif.hclk);  // 复位释放后等待5周期

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("Driving: %s", req.convert2string()), UVM_HIGH)

      if (req.write) begin
        ahb_write(req.addr, req.data);
      end else begin
        ahb_read(req.addr, req.rdata);
      end

      req.resp = 2'b00;  // 默认OKAY
      seq_item_port.item_done();
    end
  endtask

  //--------------------------------------------------------------
  // AHB写操作
  // 时序: 地址阶段(HTRANS=NONSEQ,HWRITE=1,HADDR=addr,HWDATA=data)
  //       → 等待HREADY=1 → 数据阶段 → IDLE
  //--------------------------------------------------------------
  task ahb_write(input [31:0] addr, input [31:0] data);
    // 地址阶段
    vif.htrans <= 2'b10;  // NONSEQ
    vif.hwrite <= 1'b1;
    vif.haddr  <= addr;
    vif.hwdata <= 32'h0;   // 读操作hwdata为0
    vif.hwdata <= data;
    vif.hsize  <= 3'b010;
    vif.hburst <= 3'b000;
    vif.hprot  <= 4'b0011;

    @(posedge vif.hclk);

    // 等待HREADY
    if (!disable_hready_wait) begin
      while (!vif.hready) begin
        @(posedge vif.hclk);
      end
    end

    // 回到IDLE
    vif.htrans <= 2'b00;
    @(posedge vif.hclk);
  endtask

  //--------------------------------------------------------------
  // AHB读操作
  // 时序: 地址阶段(HTRANS=NONSEQ,HWRITE=0,HADDR=addr)
  //       → 等待HREADY=1 → 采样HRDATA → IDLE
  //--------------------------------------------------------------
  task ahb_read(input [31:0] addr, output [31:0] data);
    // 地址阶段
    vif.htrans <= 2'b10;
    vif.hwrite <= 1'b0;
    vif.haddr  <= addr;
    vif.hwdata <= 32'h0;   // 读操作hwdata为0
    vif.hsize  <= 3'b010;
    vif.hburst <= 3'b000;
    vif.hprot  <= 4'b0011;

    @(posedge vif.hclk);

    // 等待HREADY
    if (!disable_hready_wait) begin
      while (!vif.hready) begin
        @(posedge vif.hclk);
      end
    end

    // 采样数据
    data = vif.hrdata;

    // 回到IDLE
    vif.htrans <= 2'b00;
    @(posedge vif.hclk);
  endtask

endclass : ahb_driver
