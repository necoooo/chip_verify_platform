//--------------------------------------------------------------
// CMU Environment Configuration (cmu_env_config)
//
// 功能: CMU模块验证环境配置类
// 基地址: 0x5000_0000 (CMU)
// 寄存器: CMU_CLK_SEL(0x00), CMU_STATUS(0x04)
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class cmu_env_config extends env_config_base;
  `uvm_object_utils(cmu_env_config)

  // CMU寄存器地址偏移
  localparam ADDR_CMU_CLK_SEL  = 12'h000;  // 时钟选择寄存器
  localparam ADDR_CMU_STATUS   = 12'h004;  // 时钟状态寄存器

  // CMU时钟频率参数
  real pll_clk_freq = 50.0;   // pll_clk 50MHz
  real rch_clk_freq = 16.0;   // rch_clk 16MHz

  function new(string name = "cmu_env_config");
    super.new(name);
    base_addr = 32'h5000_0000;  // CMU基地址
  endfunction

endclass : cmu_env_config
