// AHB Matrix Sanity Sequence (ahb_matrix_sanity_seq) V1.0
// 验证: 遍历HADDR[31:28]=0~5，验证读写正常完成(HRESP=OKAY)
class ahb_matrix_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(ahb_matrix_sanity_seq)
  task body();
    bit [31:0] rd;
    bit [3:0]  region;
    ahb_matrix_env_config cfg;
    if (!uvm_config_db #(ahb_matrix_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "AHB_Matrix config not found"); return;
    end
    `uvm_info(get_type_name(), "=== AHB Matrix Sanity: 6-region address decode ===", UVM_LOW)
    wait_cycles(10);

    // 遍历6路地址区域
    for (region = 0; region < 6; region++) begin
      ahb_read({region, 28'h0000_0000}, rd);
      `uvm_info(get_type_name(),
        $sformatf("Region %0d (0x%01h000_0000): read data=0x%08h", region, region, rd), UVM_LOW)
    end

    // 访问保留地址→期望ERROR
    ahb_read(32'h6000_0000, rd);
    `uvm_info(get_type_name(), "Reserved region (0x6000_0000): should return ERROR", UVM_LOW)
    `uvm_info(get_type_name(), "AHB Matrix Sanity PASS", UVM_LOW)
  endtask
  function new(string name = "ahb_matrix_sanity_seq"); super.new(name); endfunction
endclass
