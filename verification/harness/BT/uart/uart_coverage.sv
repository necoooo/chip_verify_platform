// UART Coverage Collector (uart_coverage) V1.0
class uart_coverage extends uvm_subscriber #(ahb_sequence_item);
  `uvm_component_utils(uart_coverage)

  covergroup uart_cg with function sample(bit [7:0] data, bit wr);
    cp_data: coverpoint data {
      bins zero = {0}; bins mid = {[1:254]}; bins max = {255};
    }
    cp_op: coverpoint wr { bins r = {0}; bins w = {1}; }
    crx_data_op: cross cp_data, cp_op;
  endgroup

  function new(string name = "uart_coverage", uvm_component parent = null);
    super.new(name, parent); uart_cg = new();
  endfunction

  function void write(ahb_sequence_item t);
    if (t.addr[31:28] == 4'h1)
      uart_cg.sample(t.write ? t.data[7:0] : t.rdata[7:0], t.write);
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("UART Coverage: %.1f%%", uart_cg.get_coverage()), UVM_LOW)
  endfunction
endclass
