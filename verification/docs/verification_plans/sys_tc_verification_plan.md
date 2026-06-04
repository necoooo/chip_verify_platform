# SYS_TC (系统定时器) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证SYS_TC模块的32位向下计数、自动重载、可屏蔽中断(IE/EN控制)、AHB寄存器(CTRL/LOAD/COUNT/STATUS)访问及定时周期精度。

## 2 验证环境架构

```
test_sys_tc_<name> (uvm_test, 继承 sys_tc_base_test)
  └── sys_tc_env (uvm_env)
        ├── ahb_agent (复用公共AHB Agent)
        ├── sys_tc_scoreboard — 维护期望计数器值/中断状态，比对TC_COUNT/tc_int
        └── sys_tc_coverage — EN/IE组合、LOAD边界值、中断标志覆盖
```

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_sys_tc_sanity | 读TC_LOAD默认值=49999，配置LOAD=10使能后等INT_FLAG | TP_TC_001.02 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_sys_tc_count_down | EN=1后COUNT每个cycle递减1 | TP_TC_002.01 |
| test_sys_tc_auto_reload | COUNT=0下一cycle自动跳到LOAD值 | TP_TC_003.01 |
| test_sys_tc_custom_load | 修改LOAD=1000，验证重载值 | TP_TC_003.02 |
| test_sys_tc_int_enabled | EN=1/IE=1, COUNT=0→tc_int脉冲 | TP_TC_004.01 |
| test_sys_tc_int_disabled | EN=1/IE=0, COUNT=0→无tc_int | TP_TC_004.02 |
| test_sys_tc_en_disable | EN=0后COUNT停止不变 | TP_TC_004.03 |
| test_sys_tc_int_flag_clear | STATUS[0]写1清零INT_FLAG | TP_TC_005.01 |
| test_sys_tc_reg_rw | CTRL/LOAD/COUNT/STATUS寄存器访问验证 | TP_TC_006.01 |
| test_sys_tc_period_accuracy | 中断间隔=LOAD+1 cycle精度测量 | TP_TC_007.01 |
| test_sys_tc_load_zero | LOAD=0边界，立即触发中断 | TP_TC_008.01 |
| test_sys_tc_load_max | LOAD=0xFFFFFFFF最大值边界 | TP_TC_008.02 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | EN/IE交叉4种组合、LOAD边界值、INT_FLAG状态转移 |
| 代码覆盖率 | 100% | 行/分支/条件/翻转 |

## 4 检查器

- SVA: tc_int脉冲宽度=1 cycle
- SVA: COUNT递减每cycle为1
- Scoreboard: 中断间隔 = LOAD+1 cycle

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <3分钟
