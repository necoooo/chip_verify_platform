# DSP (数字信号处理单元) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证DSP模块的8位加/减法运算(含进位/借位)、AHB寄存器(OPA/OPB/CTRL/RESULT/STATUS)访问、运算状态机(S_IDLE/S_BUSY)及done_int中断输出。

## 2 验证环境架构

```
test_dsp_<name> (uvm_test, 继承 dsp_base_test)
  └── dsp_env (uvm_env)
        ├── ahb_agent (复用公共AHB Agent)
        ├── dsp_scoreboard — 内置8位ADD/SUB参考模型，比对RTL运算结果
        └── dsp_coverage — 收集操作码/操作数边界值/状态机转移覆盖
```

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_dsp_sanity | OPA=3, OPB=5, OP_SEL=0(ADD), START→DONE→读RESULT=8 | TP_DSP_001.01 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_dsp_add_carry | OPA=255, OPB=1, 验证进位RESULT[8]=1 | TP_DSP_001.02 |
| test_dsp_sub_basic | OPA=8, OPB=3, OP_SEL=1(SUB), RESULT=5 | TP_DSP_002.01 |
| test_dsp_sub_borrow | OPA=3, OPB=8, 验证借位RESULT[8]=1 | TP_DSP_002.02 |
| test_dsp_reg_rw | 5个寄存器(OPA/OPB/CTRL/RESULT/STATUS)读写属性验证 | TP_DSP_003 |
| test_dsp_random | 1000次随机OPA(0-255)/OPB(0-255)/OP_SEL(0/1)组合 | TP_DSP_004.01 |
| test_dsp_flow_normal | 标准运算流程(写OPA→OPB→CTRL→等DONE→读RESULT) | TP_DSP_005.01 |
| test_dsp_start_without_opa | 未配置OPA直接启动，验证使用默认值0 | TP_DSP_005.02 |
| test_dsp_consecutive_start | 连续两次启动运算，验证状态机正确复位 | TP_DSP_005.03 |
| test_dsp_done_int | done_int与DONE同步、脉冲宽度=1 cycle | TP_DSP_006.01 |
| test_dsp_status_clear | STATUS.DONE读后自动清零验证 | TP_DSP_007.01 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | OP_SEL(0/1)、OPA/OPB边界值(0,1,127,255)、状态机2状态 |
| 代码覆盖率 | 100% | 行/分支/条件/FSM |

## 4 检查器

- SVA: START到DONE延迟=1 cycle
- SVA: done_int脉冲宽度=1 cycle
- Scoreboard: 9位结果=OPA±OPB (参考模型比对)

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <2分钟
