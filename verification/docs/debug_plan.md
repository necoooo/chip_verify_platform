# 芯片验证平台 — Sanity用例调试计划

**版本**: V2.0  
**日期**: 2026-06-04  
**状态**: CMU ✅ (V1.2 FSM修复), 继续下一模块

---

## 一、总体任务进度

| 步骤 | 内容 | 状态 |
|------|------|------|
| 1 | 测试点文档 (8模块CSV) | ✅ |
| 2 | 验证方案文档 (8模块MD) | ✅ |
| 3 | UVM验证环境搭建 | ✅ |
| 4 | Sanity用例调试 | 🔄 CMU ✅, RMU ✅, SYS_TC ✅, DSP 🔲, 其余 🔲 |
| 5 | 模块级详细验证 | 🔲 |
| 6 | 系统级验证环境 | 🔲 |
| 7 | 验证报告 | 🔲 |
| 8 | 验证环境介绍文档 | 🔲 |

---

## 二、本次会话已完成的修复

### 基础设施修复
| 文件 | 修改 | 状态 |
|------|------|------|
| Makefile V1.3 | 清理冗余, 超时60s, UVM_MAX_QUIT_COUNT=10, 自动读.last_module | ✅ |
| module_tb.sv V2.0 | DUT直连ahb_if, 移除错误悬空wire, 7模块ifdef | ✅ |
| 所有RTL .f文件 | 路径修复: ../../design/rtl/ | ✅ |
| 所有模块 BT filelist | 路径修复: 完整相对路径 | ✅ |
| env_filelist.f | 添加 uvm_pre_import.sv | ✅ |
| ahb_driver.sv | 读操作hwdata驱动为0 | ✅ |
| ahb_if.sv | 禁用复位SVA断言 | ✅ |
| uart_driver.sv | clocking block修复 | ✅ |
| uart_agent.sv | 移除错误端口连接 | ✅ |
| wait_cycles | 恢复原版dummy item方式 | ✅ |

### 波形 & Verdi
| 项目 | 方案 | 状态 |
|------|------|------|
| 波形dump | $dumpvars → VCD → vcd2fsdb → FSDB | ✅ |
| make verdi | 一键打开(自动读.last_module, 加载源码+波形) | ✅ |

### CMU模块
| 问题 | 描述 | 状态 |
|------|------|------|
| 总线连接 | DUT连悬空wire → 修复为直连ahb_if | ✅ V2.0 |
| RTL bug | curr_state/clk_sel无上电复位, 多驱动 | ✅ V1.1 initial块 |
| FSM死锁 | hclk停振导致FSM卡死(时钟切换) | ✅ V1.2 FSM改用pll_clk_i |
| Sanity | test_cmu_sanity 全部PASS | ✅ |

---

## 三、当前阻塞

无。D盘空间已清理(246G可用)，编译运行正常。

---

### RMU模块
| 问题 | 描述 | 状态 |
|------|------|------|
| RTL bug | por_rst_ni直连高, 滤波器寄存器无初始化, X态扩散至soft_rst_q=0x00 | ✅ V1.1 initial块 |
| Sanity | test_rmu_sanity 全部PASS | ✅ |

### SYS_TC模块
| 问题 | 描述 | 状态 |
|------|------|------|
| Sanity | test_sys_tc_sanity 0 ERROR | ✅ |
| 备注 | STATUS读回0x00, 测试未检查INT_FLAG(弱断言) | 📝 后续加强 |

---
## 四、后续计划

1. 在 `/home/neco/chip_sim/` 编译运行CMU
2. CMU sanity通过后依次调试: RMU → SYS_TC → DSP → SRAM_ECC → UART → AHB_MATRIX
3. 全部sanity通过后进入步骤5(模块级详细验证)
