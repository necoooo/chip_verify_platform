# AHB Matrix (AHB总线矩阵) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证AHB Matrix模块的地址译码路由(HADDR[31:28]→HSEL[5:0])、IDLE周期处理、Slave→Master响应多路复用(HRDATA/HREADY/HRESP)、Master→Slave信号组合逻辑直通及保留地址ERROR响应。

## 2 验证环境架构

```
test_ahb_matrix_<name> (uvm_test, 继承 ahb_matrix_base_test)
  └── ahb_matrix_env (uvm_env)
        ├── ahb_agent (复用公共AHB Agent, 作为Master驱动)
        ├── ahb_matrix_scoreboard — 验证HSEL译码正确性/响应复用
        └── ahb_matrix_coverage — 6路地址译码/响应类型/HTRANS类型
```

### 特殊考虑

AHB Matrix为纯组合逻辑模块，需要6个Slave端有响应源。模块级测试时：
- 在testbench中实例化6个简单的Slave响应模型 (回显写入数据+OKAY响应)
- 或使用force语句提供hrdata/hready/hresp激励

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_ahb_matrix_sanity | 遍历6路地址(HADDR[31:28]=0~5)，验证HSEL独热正确 | TP_MATRIX_001.01 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_ahb_matrix_addr_reserved | 访问保留地址(0x60000000)→HRESP=ERROR, HRDATA=0xDEAD_BEEF | TP_MATRIX_001.02 |
| test_ahb_matrix_idle_hsel | HTRANS=IDLE→HSEL全0 | TP_MATRIX_002.01 |
| test_ahb_matrix_mux | 6路Slave响应通过MUX正确回传Master | TP_MATRIX_003 |
| test_ahb_matrix_passthrough | Master→Slave共享信号(HADDR/HWRITE/HWDATA)组合逻辑直通 | TP_MATRIX_004.01 |
| test_ahb_matrix_zero_delay | HSEL与HADDR[31:28]同周期生效(组合逻辑0延迟) | TP_MATRIX_005.01 |
| test_ahb_matrix_data_width | 随机32位数据全bit透明传输 | TP_MATRIX_006.01 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | 6路地址译码、HTRANS类型(IDLE/NONSEQ)、HRESP(OKAY/ERROR) |
| 代码覆盖率 | 100% | 行/分支/条件(纯组合逻辑，无条件覆盖) |

## 4 检查器

- SVA: HSEL与HADDR[31:28]同周期生效(0延迟)
- SVA: HTRANS[1]=0 → HSEL=6'b0
- Scoreboard: 选中Slave响应=Master侧响应

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <2分钟
