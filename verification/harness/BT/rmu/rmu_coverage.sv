// RMU Coverage Collector (rmu_coverage) V1.0
class rmu_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(rmu_coverage)

  covergroup rmu_cg with function sample(bit [4:0] srst_val);
    cp_srst_bits: coverpoint srst_val {
      bins all_released = {5'b11111};
      bins all_asserted = {5'b00000};
      bins single[]      = {5'b11110, 5'b11101, 5'b11011, 5'b10111, 5'b01111};
    }
  endgroup

  function new(string name = "rmu_coverage", uvm_component parent = null);
    super.new(name, parent); rmu_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    if (t.addr[31:28] == 4'h4 && t.write && t.addr[3:0] == 4'h0)
      rmu_cg.sample(t.data[4:0]);
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("RMU Coverage: %.1f%%", rmu_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
