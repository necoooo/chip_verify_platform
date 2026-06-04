# RMU (复位管理单元) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证RMU模块的双复位源(pin_rst_n/por_rst_n)输入、500us数字消抖滤波、5模块独立软复位控制、异步复位同步释放机制及AHB寄存器(RMU_SRST/RMU_STATUS)访问。

## 2 验证环境架构

```
test_rmu_<name> (uvm_test, 继承 rmu_base_test)
  └── rmu_env (uvm_env)
        ├── ahb_agent (复用公共AHB Agent, active模式)
        ├── rmu_scoreboard — 维护期望复位状态(pin_filtered/各模块软复位)，比对DUT输出
        └── rmu_coverage — 收集双复位源组合/软复位遍历/滤波场景覆盖
```

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_rmu_sanity | 上电后验证RMU_SRST默认=0x1F(全部释放)，各模块复位=1 | TP_RMU_003 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_rmu_por_reset | por_rst_n拉低→所有复位输出=0 | TP_RMU_001.01 |
| test_rmu_pin_reset | pin_rst_n持续>500us→滤波后全局复位 | TP_RMU_001.02 |
| test_rmu_dual_reset | pin_rst_n和por_rst_n同时拉低 | TP_RMU_001.03 |
| test_rmu_filter_glitch | pin_rst_n短脉冲(<25000 cycle)被滤除 | TP_RMU_002.01 |
| test_rmu_filter_valid | pin_rst_n持续≥25000 cycle→有效复位 | TP_RMU_002.02 |
| test_rmu_filter_recovery | 滤波窗口内恢复高电平→计数重置 | TP_RMU_002.03 |
| test_rmu_soft_reset_uart | RMU_SRST[0]=0/1→uart_rst_n控制 | TP_RMU_003.01 |
| test_rmu_soft_reset_dsp | RMU_SRST[1]=0/1→dsp_rst_n控制 | TP_RMU_003.02 |
| test_rmu_soft_reset_timer | RMU_SRST[2]=0/1→timer_rst_n控制 | TP_RMU_003.03 |
| test_rmu_soft_reset_sram | RMU_SRST[3]=0/1→sram_rst_n控制 | TP_RMU_003.04 |
| test_rmu_soft_reset_bfm | RMU_SRST[4]=0/1→bfm_rst_n控制 | TP_RMU_003.05 |
| test_rmu_soft_reset_multi | 多bit同时写0→多模块同时复位 | TP_RMU_003.06 |
| test_rmu_reset_override | 全局复位(pin_rst_n=0)覆盖软复位(全1) | TP_RMU_004.01 |
| test_rmu_soft_reset_isolation | 单个软复位不影响其他模块 | TP_RMU_004.02 |
| test_rmu_sync_release | SVA检查异步复位同步释放时序 | TP_RMU_005.01 |
| test_rmu_reg_rw | RMU_SRST/RMU_STATUS寄存器读写属性验证 | TP_RMU_006 |
| test_rmu_soft_reset_flow | 完整软复位流程(写0→等待2cycle→写1) | TP_RMU_007.01 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | 双复位源8种组合、5bit软复位(0/1遍历)、滤波计数边界值 |
| 代码覆盖率 | 100% | 行/分支/条件/FSM |

## 4 检查器

- SVA: 复位同步释放双触发器检查
- SVA: 复位脉冲最小宽度≥2 cycle
- Scoreboard: 各模块复位输出=(pin_filtered AND por_rst_n AND soft_rst)

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <5分钟 (含500us滤波仿真时间)
