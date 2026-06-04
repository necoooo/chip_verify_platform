//--------------------------------------------------------------
// AHB Monitor (ahb_monitor)
//
// 功能: 被动监测AHB-Lite总线，采集传输事务并通过analysis port广播
// 用途: 供scoreboard和coverage collector订阅
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class ahb_monitor extends uvm_monitor;
  `uvm_component_utils(ahb_monitor)

  // Virtual interface
  virtual ahb_if vif;

  // Analysis port: 广播检测到的事务
  uvm_analysis_port #(ahb_sequence_item) item_collected_port;

  function new(string name = "ahb_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------
  // Build Phase
  //--------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual AHB interface not found in config_db")
    end
  endfunction

  //--------------------------------------------------------------
  // Run Phase: 监测AHB总线事务
  //--------------------------------------------------------------
  task run_phase(uvm_phase phase);
    ahb_sequence_item item;

    `uvm_info(get_type_name(), "AHB Monitor starting...", UVM_MEDIUM)

    forever begin
      @(posedge vif.hclk);

      // 检测非IDLE传输（地址阶段）
      if (vif.htrans[1] && vif.hresetn) begin
        item = ahb_sequence_item::type_id::create("item");
        item.addr  = vif.haddr;
        item.write = vif.hwrite;
        item.size  = vif.hsize;
        item.burst = vif.hburst;
        item.prot  = vif.hprot;
        item.trans = vif.htrans;

        if (vif.hwrite) begin
          item.data = vif.hwdata;
        end

        // 等待数据阶段完成
        @(posedge vif.hclk);
        if (!vif.hready) begin
          while (!vif.hready) begin
            @(posedge vif.hclk);
          end
        end

        if (!vif.hwrite) begin
          item.rdata = vif.hrdata;
        end
        item.resp = vif.hresp;

        `uvm_info(get_type_name(), $sformatf("Monitored: %s", item.convert2string()), UVM_HIGH)

        // 广播事务
        item_collected_port.write(item);
      end
    end
  endtask

endclass : ahb_monitor
