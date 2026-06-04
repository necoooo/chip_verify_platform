//--------------------------------------------------------------
// DSP Sanity Sequence (dsp_sanity_seq) V1.0
// 验证: OPA=3, OPB=5, ADD → RESULT=8
//--------------------------------------------------------------
class dsp_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(dsp_sanity_seq)

  function new(string name = "dsp_sanity_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] rd_data;
    dsp_env_config cfg;
    if (!uvm_config_db #(dsp_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "DSP config not found"); return;
    end
    `uvm_info(get_type_name(), "=== DSP Sanity: OPA=3, OPB=5, ADD → expect 8 ===", UVM_LOW)
    wait_cycles(10);
    ahb_write(cfg.base_addr + 12'h00, 32'd3);     // OPA=3
    ahb_write(cfg.base_addr + 12'h04, 32'd5);     // OPB=5
    ahb_write(cfg.base_addr + 12'h08, 32'd1);     // START=1, OP_SEL=0(ADD)
    wait_cycles(5);  // 等待运算完成
    ahb_read(cfg.base_addr + 12'h0C, rd_data);    // 读RESULT
    if (rd_data[8:0] != 9'd8)
      `uvm_error(get_type_name(), $sformatf("DSP sanity FAIL: exp=8, got=%0d", rd_data[8:0]))
    else
      `uvm_info(get_type_name(), "DSP Sanity PASS: 3+5=8", UVM_LOW)
  endtask
endclass
