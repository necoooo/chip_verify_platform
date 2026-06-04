# CMU (时钟管理单元) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证CMU模块的双时钟源选择(rch_clk/pll_clk)、无毛刺时钟切换、AHB寄存器(CLK_SEL/STATUS)访问及时钟频率精度。

## 2 验证环境架构

```
test_cmu_<name> (uvm_test, 继承 cmu_base_test)
  └── cmu_env (uvm_env)
        ├── ahb_agent (复用公共AHB Agent, active模式)
        │     ├── ahb_driver — 通过virtual interface驱动AHB写/读CMU寄存器
        │     ├── ahb_monitor — 监测AHB总线事务并广播
        │     └── ahb_sequencer — sequence调度
        ├── cmu_scoreboard — 维护期望CLK_SEL值，比对AHB读写一致性
        └── cmu_coverage — 收集时钟源选择、寄存器访问功能覆盖率
```

### 关键接口

| 接口 | DUT信号 | 验证环境连接方式 |
|------|--------|-----------------|
| rch_clk_i (16MHz) | DUT输入 | testbench产生 31.25ns 周期时钟 |
| pll_clk_i (50MHz) | DUT输入 | testbench产生 10ns 周期时钟 |
| hclk_o | DUT输出 | 作为AHB interface时钟源，同时用作UVM环境时钟 |
| AHB从机接口 | DUT AHB端口 | 通过ahb_if virtual interface连接ahb_driver/monitor |

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_cmu_sanity | 上电后读CMU_CLK_SEL默认值=0，验证默认pll_clk | TP_CMU_001.01 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_cmu_clk_switch_pll_to_rch | AHB写CLK_SEL=1，切换pll→rch(16MHz)，读STATUS确认 | TP_CMU_002.01 |
| test_cmu_clk_switch_rch_to_pll | AHB写CLK_SEL=0，切换rch→pll(50MHz) | TP_CMU_002.02 |
| test_cmu_glitch_free | 时钟切换过程中SVA断言检查hclk无毛刺 | TP_CMU_003.01 |
| test_cmu_state_machine | 功能覆盖率收集状态机S_IDLE→GATE_OFF→SWITCH→GATE_ON遍历 | TP_CMU_003.02 |
| test_cmu_reg_rw | CMU_CLK_SEL和CMU_STATUS寄存器读写/只读属性验证 | TP_CMU_004, TP_CMU_005 |
| test_cmu_freq_accuracy | 测量pll模式hclk=20ns±5%，rch模式hclk=62.5ns±5% | TP_CMU_006 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | 时钟源选择(0/1)、状态机4状态、寄存器访问(读/写) |
| 代码覆盖率 | 100% | 行/分支/条件/FSM状态 |
| 断言覆盖率 | 100% | 无毛刺切换、复位期间安全状态 |

## 4 检查器

- SVA: hclk无毛刺检查(最小脉冲宽度≥源时钟周期)
- SVA: 复位期间HTRANS=IDLE
- Scoreboard: CLK_SEL寄存器读写一致性

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <2分钟 (模块级)
