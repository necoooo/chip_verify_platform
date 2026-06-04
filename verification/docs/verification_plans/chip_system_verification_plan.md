# 芯片系统级 (chip_top) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证chip_top芯片顶层集成功能的正确性，包括：上电复位序列、时钟分发(hclk→所有模块)、复位网络(6路独立复位正确连接)、AHB总线互联(BFM→Matrix→全部Slave)、地址空间隔离、中断系统(4路)、ECC状态信号连接、跨模块软复位隔离及系统级并发操作。

## 2 验证环境架构

```
test_chip_<name> (uvm_test, 继承 chip_base_test)
  └── chip_env (uvm_env)  [位于 harness/ST/chip/]
        ├── ahb_agent (复用公共AHB Agent — 模块级组件)
        ├── uart_agent (复用公共UART Agent — 系统级启用)
        ├── chip_scoreboard — 系统级数据比对(多模块协同检查)
        ├── chip_coverage — 跨模块交叉覆盖收集
        └── interrupt_monitor — 监测4路中断信号
```

### 模块级组件复用

| 复用组件 | 来源 | 复用方式 |
|----------|------|----------|
| ahb_agent | env/ahb/ | 直接复用，通过config_db传入chip级ahb_vif |
| uart_agent | env/uart/ | 直接复用，连接chip_top的uart_tx/uart_rx引脚 |
| cmu/rmu/dsp等env | harness/BT/ | 以sub_env方式集成，各模块scoreboard作为chip_scoreboard的子组件 |

### 系统级Testbench

chip_tb实例化完整的chip_top + 时钟源(rch_clk/pll_clk) + 复位源(pin_rst_n/por_rst_n)，ahb_agent通过顶层AHB信号驱动BFM→Matrix→各Slave。

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_chip_sanity | 上电复位序列→确认hclk=50MHz→AHB读各模块寄存器 | TP_CHIP_001 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_chip_clk_distribution | monitor检查8个模块时钟端口均收到hclk | TP_CHIP_002.01 |
| test_chip_reset_network | monitor检查6路复位连接与chip_top实例化一致 | TP_CHIP_003.01 |
| test_chip_ahb_all_slaves | BFM→Matrix→全部6路Slave读写验证 | TP_CHIP_004.01 |
| test_chip_addr_space | 各模块基地址空间独立无冲突 | TP_CHIP_005.01 |
| test_chip_int_sys_tc | 使能SYS_TC中断→tc_int_o输出验证 | TP_CHIP_006.01 |
| test_chip_int_uart | 触发UART收发→uart_tx_int_o/uart_rx_int_o验证 | TP_CHIP_006.02 |
| test_chip_int_dsp | 触发DSP运算→dsp_done_int_o验证 | TP_CHIP_006.03 |
| test_chip_int_concurrent | SYS_TC+UART+DSP同时中断→不丢失 | TP_CHIP_006.04 |
| test_chip_ecc_status | 注入ECC错误→顶层ecc_err_o/sec_o/ded_o验证 | TP_CHIP_007.01 |
| test_chip_soft_reset_isolation | RMU复位UART→DSP/SYS_TC/SRAM仍正常 | TP_CHIP_008.01 |
| test_chip_concurrent | UART收发+DSP运算+SYS_TC定时+SRAM读写并发 | TP_CHIP_009.01 |
| test_chip_clk_switch_stress | CMU切换时钟→立即访问各Slave→恢复正常 | TP_CHIP_009.02 |
| test_chip_stress | 长时间多模块随机并发压力测试 | TP_CHIP_009.03 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | 6路Slave交叉访问、4路中断组合、多模块并发场景 |
| 代码覆盖率 | 100% | chip_top行/分支/条件(顶层为连线，主要覆盖率在子模块) |
| 跨模块覆盖 | 100% | 地址空间隔离、中断仲裁、复位级联影响 |

## 4 检查器

- SVA: 上电复位序列时序检查(por→pin→soft_rst释放顺序)
- SVA: 各模块时钟端口收到hclk
- Scoreboard: 多模块并发操作数据一致性

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <15分钟 (含压力测试)
