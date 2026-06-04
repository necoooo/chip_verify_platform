//--------------------------------------------------------------
// SRAM_ECC Scoreboard (sram_ecc_scoreboard) V1.0
// 功能: ECC参考模型比对，验证数据读写和ECC纠错正确性
//--------------------------------------------------------------
class sram_ecc_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sram_ecc_scoreboard)

  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  // 期望存储模型 (256×32bit)
  bit [31:0] exp_mem [256];

  function new(string name = "sram_ecc_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahb_export = new("ahb_export", this);
    ahb_fifo   = new("ahb_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ahb_export.connect(ahb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    ahb_sequence_item item;
    bit [7:0] addr_idx;
    forever begin
      ahb_fifo.get(item);
      if (item.addr[31:28] != 4'h0) continue;

      addr_idx = item.addr[9:2];
      if (item.write && item.addr[11:10] == 2'b00) begin
        exp_mem[addr_idx] = item.data;
      end else if (!item.write && item.addr[11:10] == 2'b00) begin
        if (item.rdata !== exp_mem[addr_idx]) begin
          `uvm_error(get_type_name(),
            $sformatf("SRAM mismatch @ addr=%0d: exp=0x%08h, got=0x%08h",
                      addr_idx, exp_mem[addr_idx], item.rdata))
        end
      end
    end
  endtask
endclass
