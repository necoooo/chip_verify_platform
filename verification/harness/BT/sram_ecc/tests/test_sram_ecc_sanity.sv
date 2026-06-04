// SRAM_ECC Sanity Test (test_sram_ecc_sanity) V1.0
class test_sram_ecc_sanity extends sram_ecc_base_test;
  `uvm_component_utils(test_sram_ecc_sanity)
  function new(string n = "test_sram_ecc_sanity", uvm_component p = null); super.new(n, p); endfunction
  task run_phase(uvm_phase phase);
    sram_ecc_sanity_seq seq;
    phase.raise_objection(this);
    seq = sram_ecc_sanity_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
