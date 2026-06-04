// SRAM_ECC Coverage Collector (sram_ecc_coverage) V1.0
class sram_ecc_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(sram_ecc_coverage)

  covergroup sram_cg with function sample(bit [7:0] addr, bit wr);
    cp_addr: coverpoint addr {
      bins zero = {0}; bins mid = {[1:254]}; bins max = {255};
    }
    cp_operation: coverpoint wr { bins read = {0}; bins write = {1}; }
    crx_op_addr: cross cp_operation, cp_addr;
  endgroup

  function new(string name = "sram_ecc_coverage", uvm_component parent = null);
    super.new(name, parent); sram_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    if (t.addr[31:28] == 4'h0 && t.addr[11:10] == 2'b00)
      sram_cg.sample(t.addr[9:2], t.write);
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("SRAM_ECC Coverage: %.1f%%", sram_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
