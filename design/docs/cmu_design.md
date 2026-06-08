# 时钟管理单元（CMU）

## 设计文档

**版本：V1.3.0 2026.06.08**

---

## 1 修改记录

| 版本号 | 修改人 | 修改日期 | 更改理由 | 主要更改内容 |
|--------|--------|----------|----------|-------------|
| V0.1.0 | — | 2026-05-28 | 初建 | CMU初始版本 |
| V1.1.0 | — | 2026-06-04 | 验证反馈(BUG CMU-01) | 添加上电initial块，修复无复位导致X态扩散至clk_sel/hclk_o |
| V1.2.0 | — | 2026-06-04 | 验证反馈(BUG CMU-02) | FSM时钟由hclk_o改为pll_clk_i(始终运行)，修复时钟切换时hclk停振导致FSM死锁 |
| V1.3.0 | — | 2026-06-08 | 验证反馈(BUG CMU-03) | 新增CDC 2-FF同步器链+hwdata toggle握手，修复切rch后AHB写无法被FSM可靠采样 |

---

## 2 简介

时钟管理单元（CMU）是整个芯片验证教学平台的时钟源模块，接收两路外部时钟输入——内部 RC 振荡器 rch_clk（16MHz）和 PLL 输出 pll_clk（50MHz），通过内部选择逻辑生成主时钟 hclk 供所有模块使用。CMU 还集成时钟分频器，支持输出可调的分频时钟。

---

## 3 特点

- 双时钟源输入：rch_clk（16MHz，内部RC振荡器）、pll_clk（50MHz，PLL输出）
- 可配置时钟选择：通过 AHB 寄存器选择主时钟源，默认为 pll_clk（50MHz）
- 输出主时钟 hclk，供所有功能模块使用
- 可选分频时钟输出（用于低速外设，预留）
- 结构简单，适合验证教学

---

## 4 基本原理

CMU 接收两路异步时钟源 rch_clk 和 pll_clk，通过内部无毛刺时钟切换电路（glitch-free clock mux）选择其中一路作为主时钟 hclk 输出。时钟切换由 AHB 配置寄存器控制。上电默认选择 pll_clk（50MHz）。

---

## 5 结构框图

```
                 ┌────────────── CMU ───────────────┐
                 │                                   │
  rch_clk (16M) ─┤──►┐                              │
                 │   │   ┌──────────────────┐        │
  pll_clk (50M) ─┤──►┼──►│ Glitch-Free      │──► hclk│
                 │   │   │ Clock Mux        │        │
                 │   │   │ (上电默认pll_clk)  │        │
                 │   │   └────┬─────────────┘        │
                 │   │        │ 选择信号               │
                 │   │   ┌────┴─────────────┐        │
  hclk ◄─────────┼───┼───┤  分频器（预留）    │──► hclk_div
                 │   │   │  ÷2/÷4/÷8/...   │        │
                 │   │   └──────────────────┘        │
                 │   │                               │
  hresetn ───────┤   │   ┌──────────────────┐        │
  hsel ──────────┤   │   │  AHB 从机接口     │        │
  haddr ─────────┤   │   │  （时钟选择寄存器） │        │
  hwrite ────────┤   │   └──────────────────┘        │
  hwdata ────────┤   │                               │
  htrans ────────┤   │                               │
  hrdata ◄───────┤   │                               │
  hready ◄───────┤   │                               │
  hresp ◄────────┤   │                               │
                 │   │                               │
                 └───────────────────────────────────┘
```

---

## 6 接口定义

| 信号名 | 方向 | 位宽 | 说明 |
|--------|------|------|------|
| rch_clk_i | Input | 1 | 内部RC振荡器时钟（16MHz） |
| pll_clk_i | Input | 1 | PLL输出时钟（50MHz） |
| hclk_o | Output | 1 | 主时钟输出 |
| hsel_i | Input | 1 | AHB Slave选择 |
| haddr_i | Input | 32 | AHB地址 |
| hwrite_i | Input | 1 | AHB读写控制 |
| htrans_i | Input | 2 | AHB传输类型 |
| hwdata_i | Input | 32 | AHB写数据 |
| hrdata_o | Output | 32 | AHB读数据 |
| hready_o | Output | 1 | AHB传输完成 |
| hresp_o | Output | 2 | AHB传输响应 |

> **V1.2变更**: 移除了V0.1.0中的hclk_div(预留分频输出)和hresetn输入, 简化接口。CMU无专用复位输入，依赖initial块初始化。

---

## 7 时钟和复位

- **输入时钟**: rch_clk_i（16MHz）和 pll_clk_i（50MHz），两路异步
- **输出时钟**: hclk_o，根据寄存器选择为 16MHz 或 50MHz
- **FSM时钟域**: 使用pll_clk_i（50MHz，始终运行）。V1.2之前使用hclk_o，切换时钟源时hclk_o停振导致FSM死锁
- **AHB寄存器**: 组合逻辑读，时序逻辑与FSM共用pll_clk_i时钟域
- **复位**: CMU无专用复位输入，依赖initial块上电初始化（默认选择pll_clk, 50MHz）
- **上电默认**: clk_sel=0（pll_clk）, gate_pll=1（使能）, gate_rch=0（关闭）

---

## 8 功能描述

### 8.1 时钟源选择

通过 CMU_CLK_SEL 寄存器选择主时钟源：

| CMU_CLK_SEL[0] | 选择源 | 频率 |
|----------------|--------|------|
| 1'b0 | pll_clk | 50 MHz |
| 1'b1 | rch_clk | 16 MHz |

上电默认值为 1'b0，即选择 pll_clk（50MHz）。

### 8.2 无毛刺切换

时钟切换采用"先关后开"策略，由三段式FSM控制（pll_clk_i时钟域，始终运行）：

**FSM状态**: S_IDLE → S_GATE_OFF → S_SWITCH → S_GATE_ON → S_IDLE

1. **S_IDLE**: 等待AHB写CMU_CLK_SEL寄存器，检测到clk_sel_req后进入S_GATE_OFF
2. **S_GATE_OFF**: 关闭当前时钟源门控（gate_pll或gate_rch），计数3个pll_clk周期后进入S_SWITCH
3. **S_SWITCH**: 切换clk_sel到目标时钟源，立即进入S_GATE_ON
4. **S_GATE_ON**: 使能新时钟源门控，计数3个pll_clk周期稳定后回到S_IDLE，清除clk_sel_req

切换期间hclk_o会短暂停止（至少6个pll_clk周期），确保输出无毛刺。

### 8.3 时钟状态监控（预留）

预留 CMU_STATUS 寄存器，用于反馈当前时钟选择状态和时钟源有效性。

---

## 9 寄存器描述

### 9.1 寄存器列表

| 偏移地址 | 寄存器名 | 属性 | 复位值 | 说明 |
|----------|----------|------|--------|------|
| 0x00 | CMU_CLK_SEL | RW | 0x0000_0000 | 时钟源选择寄存器 |
| 0x04 | CMU_STATUS | RO | 0x0000_0000 | 时钟状态寄存器（预留） |

### 9.2 CMU_CLK_SEL（0x00）— 时钟源选择寄存器

| 位 | 属性 | 复位值 | 说明 |
|----|------|--------|------|
| [0] | RW | 1'b0 | 主时钟源选择：0=pll_clk(50MHz)，1=rch_clk(16MHz) |
| [31:1] | RSVD | 31'h0 | 保留 |

### 9.3 CMU_STATUS（0x04）— 时钟状态寄存器

| 位 | 属性 | 复位值 | 说明 |
|----|------|--------|------|
| [0] | RO | 1'b0 | 当前时钟源：0=pll_clk，1=rch_clk |
| [31:1] | RSVD | 31'h0 | 保留 |

---

## 10 软件配置流程

```
配置示例：切换主时钟为 rch_clk（16MHz）
  1. 读 CMU_STATUS    // 确认当前时钟源
  2. 写 CMU_CLK_SEL = 1  // 选择 rch_clk（16MHz）
  3. 等待至少 10 个 hclk 周期
  4. 读 CMU_STATUS    // 确认切换完成（bit[0]=1）
```
