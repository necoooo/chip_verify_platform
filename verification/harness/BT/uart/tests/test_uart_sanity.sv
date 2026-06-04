// UART Sanity Test V2.2: 回环TX→RX + agent monitor
class test_uart_sanity extends uart_base_test;
  `uvm_component_utils(test_uart_sanity)
  function new(string n = "test_uart_sanity", uvm_component p = null); super.new(n, p); endfunction
  task run_phase(uvm_phase phase);
    uart_sanity_seq seq;
    phase.raise_objection(this);
    seq = uart_sanity_seq::type_id::create("seq");
    seq.start(env.ahb_agt.sequencer);
    phase.drop_objection(this);
  endtask
endclass
