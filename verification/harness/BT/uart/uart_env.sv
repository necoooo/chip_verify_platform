// UART Environment (uart_env) V1.0
// 组件: ahb_agent + uart_agent + uart_scoreboard + uart_coverage
class uart_env extends uvm_env;
  `uvm_component_utils(uart_env)

  ahb_agent      ahb_agt;
  uart_agent     uart_agt;
  uart_scoreboard scoreboard;
  uart_coverage   coverage;
  uart_env_config cfg;

  function new(string name = "uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(uart_env_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "UART config not found")
    uvm_config_db #(virtual ahb_if)::set(this, "ahb_agt.*", "ahb_vif", cfg.ahb_vif);
    if (cfg.has_uart_agent) begin
      uvm_config_db #(virtual uart_if)::set(this, "uart_agt.*", "uart_vif", cfg.uart_vif);
      uart_agt = uart_agent::type_id::create("uart_agt", this);
    end
    ahb_agt = ahb_agent::type_id::create("ahb_agt", this);
    if (cfg.has_scoreboard) scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
    if (cfg.has_coverage)  coverage = uart_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.has_scoreboard) begin
      ahb_agt.monitor.item_collected_port.connect(scoreboard.ahb_export);
      if (cfg.has_uart_agent)
        uart_agt.monitor.item_collected_port.connect(scoreboard.uart_export);
    end
    if (cfg.has_coverage)
      ahb_agt.monitor.item_collected_port.connect(coverage.analysis_export);
  endfunction
endclass
