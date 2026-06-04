# SRAM_ECC (带ECC的SRAM) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证SRAM_ECC模块的256×32bit基本读写、(39,32)扩展汉明码SEC-DED纠错检错、ECC错误计数/地址记录、AHB寄存器(ECC_CTRL/ERR_CNT/ERR_ADDR)访问及复位行为。

## 2 验证环境架构

```
test_sram_ecc_<name> (uvm_test, 继承 sram_ecc_base_test)
  └── sram_ecc_env (uvm_env)
        ├── ahb_agent (复用公共AHB Agent)
        ├── sram_ecc_scoreboard — 内置ECC编码/解码参考模型，比对数据正确性
        └── sram_ecc_coverage — 数据bit位遍历、ECC错误类型、地址空间覆盖
```

### Scoreboard参考模型

Scoreboard内实现与RTL等价的(39,32)汉明码编解码器，用于：
- 写操作时计算期望ECC校验位
- 读操作时验证纠正后的数据与原始写入一致
- 验证单bit错误纠正、双bit错误检测逻辑

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_sram_ecc_sanity | 写0xDEAD_BEEF到地址0→读回验证一致 | TP_SRAM_001.01 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_sram_ecc_full_addr | 遍历256个地址(0x00-0xFF)分别读写验证 | TP_SRAM_001.02 |
| test_sram_ecc_consecutive_write | 同一地址连续写不同值，读回最后一次值 | TP_SRAM_001.03 |
| test_sram_ecc_sec_correct | 注入单bit错误→自动纠正，ecc_sec=1 | TP_SRAM_002.01 |
| test_sram_ecc_sec_all_bits | 遍历32个数据位分别注入单bit错误 | TP_SRAM_002.02 |
| test_sram_ecc_ded_detect | 注入2bit错误→ecc_ded=1，数据不纠正 | TP_SRAM_003.01 |
| test_sram_ecc_ded_combinations | 多种双bit组合验证DED检测 | TP_SRAM_003.02 |
| test_sram_ecc_err_cnt | 连续注入错误→ECC_ERR_CNT累加验证 | TP_SRAM_004.01 |
| test_sram_ecc_err_addr | ECC_ERR_ADDR记录最近错误地址 | TP_SRAM_004.02 |
| test_sram_ecc_random | 1000次随机数据ECC编解码往返验证 | TP_SRAM_005 |
| test_sram_ecc_reg_rw | ECC_CTRL/ERR_CNT/ERR_ADDR寄存器访问 | TP_SRAM_006 |
| test_sram_ecc_reset_data_keep | 写数据→复位→读回数据不变 | TP_SRAM_007.01 |
| test_sram_ecc_reset_ecc_clear | 复位后ECC_ERR_CNT/ERR_ADDR清零 | TP_SRAM_007.02 |
| test_sram_ecc_addr_space | 数据空间(0x00-0x3FC)与寄存器空间(0x400+)隔离 | TP_SRAM_008.01 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | 256地址遍历、32bit位置单bit错、多种双bit组合、ECC错误类型(SEC/DED) |
| 代码覆盖率 | 100% | 行/分支/条件/FSM |

## 4 检查器

- Scoreboard: ECC编码结果与参考模型比对
- Scoreboard: 纠正后数据 = 原始写入数据
- SVA: 读写操作时序正确

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <5分钟
