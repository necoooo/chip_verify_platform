// AHB Matrix Sanity Sequence V1.1: 自动检查6区译码+保留区ERROR
class ahb_matrix_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(ahb_matrix_sanity_seq)
  task body();
    bit [31:0] rd;
    bit [3:0]  region;
    ahb_matrix_env_config cfg;
    if (!uvm_config_db #(ahb_matrix_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "AHB_Matrix config not found"); return;
    end
    `uvm_info(get_type_name(), "=== AHB Matrix Sanity ===", UVM_LOW)
    wait_cycles(10);

    for (region = 0; region < 6; region++) begin
      ahb_read({region, 28'h0000_0000}, rd);
      if (rd != 32'h0000_0000)
        `uvm_error(get_type_name(), $sformatf("Region %0d: exp=0x0 got=0x%08h", region, rd))
    end

    ahb_read(32'h6000_0000, rd);
    if (rd != 32'hDEAD_BEEF)
      `uvm_error(get_type_name(), $sformatf("Reserved: exp=0xDEAD_BEEF got=0x%08h", rd))

    `uvm_info(get_type_name(), "AHB Matrix Sanity PASS", UVM_LOW)
  endtask
  function new(string name = "ahb_matrix_sanity_seq"); super.new(name); endfunction
endclass
