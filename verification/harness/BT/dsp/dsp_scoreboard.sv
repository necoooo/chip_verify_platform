//--------------------------------------------------------------
// DSP Scoreboard (dsp_scoreboard) V1.0
// 功能: 8位ADD/SUB参考模型，比对RTL运算结果
//--------------------------------------------------------------
class dsp_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(dsp_scoreboard)

  uvm_analysis_export #(ahb_sequence_item) ahb_export;
  uvm_tlm_analysis_fifo #(ahb_sequence_item) ahb_fifo;

  // 参考模型寄存器
  bit [7:0] exp_opa, exp_opb;
  bit       exp_op_sel;
  bit [8:0] exp_result;

  dsp_env_config cfg;

  function new(string name = "dsp_scoreboard", uvm_component parent = null);
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
    forever begin
      ahb_fifo.get(item);
      if (item.addr[31:28] != 4'h2) continue;  // 仅处理DSP地址空间

      if (item.write) begin
        case (item.addr[3:0])
          4'h0: exp_opa = item.data[7:0];
          4'h4: exp_opb = item.data[7:0];
          4'h8: begin
            exp_op_sel = item.data[1];
            if (item.data[0]) begin  // START
              exp_result = exp_op_sel ? ({1'b0, exp_opa} - {1'b0, exp_opb}) :
                                       ({1'b0, exp_opa} + {1'b0, exp_opb});
            end
          end
        endcase
      end else begin
        if (item.addr[3:0] == 4'hC) begin  // RESULT
          if (item.rdata[8:0] !== exp_result) begin
            `uvm_error(get_type_name(),
              $sformatf("DSP RESULT mismatch @ OPA=%0d OPB=%0d OP=%0s: exp=%0d, got=%0d",
                        exp_opa, exp_opb, exp_op_sel ? "SUB" : "ADD",
                        exp_result, item.rdata[8:0]))
          end
        end
      end
    end
  endtask
endclass
