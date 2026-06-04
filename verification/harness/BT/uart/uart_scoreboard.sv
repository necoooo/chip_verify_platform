//--------------------------------------------------------------
// UART Scoreboard (uart_scoreboard) V1.0
// 功能: 比对AHB寄存器侧收发数据与UART物理层数据一致性
//--------------------------------------------------------------
class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  uvm_analysis_export #(uart_sequence_item) uart_export;
  uvm_tlm_analysis_fifo #(uart_sequence_item) uart_fifo;

  bit [7:0] tx_exp_data;   // 期望发送数据(AHB侧写入TXD)
  bit [7:0] rx_exp_data;   // 期望接收数据(uart_driver侧发送)

  function new(string name = "uart_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahb_export  = new("ahb_export", this);
    uart_export = new("uart_export", this);
    ahb_fifo    = new("ahb_fifo", this);
    uart_fifo   = new("uart_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ahb_export.connect(ahb_fifo.analysis_export);
    uart_export.connect(uart_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    fork
      check_ahb_tx();
      check_uart_rx();
    join
  endtask

  task check_ahb_tx();
    ahb_sequence_item item;
    forever begin
      ahb_fifo.get(item);
      if (item.addr[31:28] == 4'h1 && item.write && item.addr[3:0] == 4'hC) begin
        tx_exp_data = item.data[7:0];  // 记录AHB写入的TXD值
      end
    end
  endtask

  task check_uart_rx();
    uart_sequence_item item;
    forever begin
      uart_fifo.get(item);
      // uart_monitor采集到tx引脚数据, 验证与AHB写TXD一致
      if (!item.is_tx && item.data !== tx_exp_data) begin
        `uvm_error(get_type_name(),
          $sformatf("UART TX mismatch: AHB wrote 0x%02h, uart_tx monitored 0x%02h",
                    tx_exp_data, item.data))
      end
    end
  endtask
endclass
