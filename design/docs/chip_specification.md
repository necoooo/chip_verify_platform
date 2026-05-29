# 芯片验证教学平台

## 规格书

**版本：V0.1.0 2026.05.28**

---

## 修改记录

| 版本号 | 修改人 | 修改日期 | 更改理由 | 主要更改内容 |
|--------|--------|----------|----------|-------------|
| V0.1.0 | — | 2026-05-28 | 初建 | 芯片验证教学平台初始版本 |

---

## 1 概述

### 1.1 文档约定

**寄存器属性说明**:

| 属性 | 说明 |
|------|------|
| RW | 可读可写 |
| RO | 只读 |
| WC | 只写，写1清零 |
| RSVD | 保留位 |

**名词定义**:

| 术语 | 说明 |
|------|------|
| AHB | Advanced High-performance Bus，AMBA 高性能总线 |
| BFM | Bus Functional Model，总线功能模型 |
| CMU | Clock Management Unit，时钟管理单元 |
| RMU | Reset Management Unit，复位管理单元 |
| DSP | Digital Signal Processor，数字信号处理单元（本平台为简易ALU） |
| UART | Universal Asynchronous Receiver/Transmitter，通用异步收发器 |
| SYS_TC | System Timer Counter，系统定时器/计数器 |
| SRAM | Static Random Access Memory，静态随机存储器 |
| ECC | Error Correction Code，纠错码 |
| SEC-DED | Single Error Correction, Double Error Detection，单比特纠错、双比特检错 |

### 1.2 芯片概述

芯片验证教学平台是一款面向芯片验证教学的简易数字SoC设计，集成了时钟管理、复位管理、AHB-Lite总线、UART通信、简易DSP运算、系统定时器及带ECC校验的SRAM等基础模块。平台所有模块均配备独立的AHB从机接口，支持通过AHB BFM进行仿真验证，适用于Verilog验证入门教学。

### 1.3 主要特点

- 基于AMBA AHB-Lite总线协议的统一互联架构
- 1主4从AHB总线矩阵，地址解码简洁直观
- 各模块独立软复位控制，支持分级复位管理
- 带ECC单比特纠错、双比特检错的SRAM存储
- 完整的AHB BFM行为模型，可直接用于仿真验证
- 模块化设计，各模块功能独立、接口清晰

---

## 2 系统架构

### 2.1 整体框图

```
                          ┌──────────────────┐
                          │     AHB BFM      │
                          │   (仿真Master)    │
                          └────────┬─────────┘
                                   │ AHB-Lite Master
                    ┌──────────────┼──────────────┐
                    │              │              │
               ┌────┴────┐   ┌────┴────┐   ┌────┴────┐
               │  UART   │   │   DSP   │   │ SYS_TC  │
               │ (Slave) │   │ (Slave) │   │ (Slave) │
               └─────────┘   └─────────┘   └─────────┘
                    │              │              │
                    └──────────────┼──────────────┘
                                   │ AHB-Lite Slave
                    ┌──────────────┼──────────────┐
                    │              │              │
               ┌────┴────┐   ┌────┴────┐   ┌────┴────┐
               │RMU(reg) │   │SRAM_ECC │   │(Reserve)│
               │ (Slave) │   │ (Slave) │   │         │
               └─────────┘   └─────────┘   └─────────┘

  rch_clk(16MHz)  pll_clk(50MHz)
       │               │
       └───────┬───────┘
               │
          ┌────┴─────┐              ┌──────────┐
          │   CMU    │              │   RMU    │
          │  时钟    │              │  复位    │
          └────┬─────┘              └────┬─────┘
               │ hclk                     │ rst_n[x]
               └──────────────────────────┘
                     (送至所有模块)
```

### 2.2 模块列表

| 编号 | 模块名 | 类型 | 功能描述 |
|------|--------|------|----------|
| 1 | CMU | 时钟 | 产生50MHz主时钟hclk，供所有模块使用 |
| 2 | RMU | 复位 | 管理pin_rst_n、por_rst_n及AHB可配的各模块软复位 |
| 3 | AHB BFM | 总线Master | 仿真AHB-Lite Master，支持读写交易 |
| 4 | AHB Matrix | 总线互联 | 1主5从AHB-Lite总线矩阵，地址译码路由 |
| 5 | UART | 通信 | 标准UART，115200bps/8N1，AHB可配 |
| 6 | DSP | 算法 | 8位加减法器，AHB可配操作数与启动 |
| 7 | SYS_TC | 定时器 | 可配置周期定时器，支持中断输出 |
| 8 | SRAM_ECC | 存储 | 256×32bit SRAM，带SEC-DED ECC保护 |

---

## 3 时钟与复位架构

### 3.1 时钟架构

```
  rch_clk (16MHz 内部RC振荡器) ──┐
                                 ├──► CMU (选择/切换) ──► hclk ──► 所有模块
  pll_clk (50MHz PLL输出) ───────┘
```

- **时钟源1**: rch_clk，内部RC振荡器，固定16MHz
- **时钟源2**: pll_clk，PLL输出，固定50MHz
- **主时钟 hclk**: 由CMU选择输出，上电默认pll_clk (50MHz)，可通过AHB寄存器切换为rch_clk (16MHz)
- **时钟域**: 单一同步时钟域，所有模块共用hclk

### 3.2 复位架构

```
  pin_rst_n ──────┐
                  ├──► RMU ──┬── sys_rst_n (全局复位)
  por_rst_n ──────┘         ├── uart_rst_n
                             ├── dsp_rst_n
                             ├── timer_rst_n
                             ├── sram_rst_n
                             └── bfm_rst_n
```

- **pin_rst_n**: 外部引脚复位，低有效，带500μs数字滤波
- **pin_rst_n 滤波**: RMU内部500μs消抖计数器（25000 cycles @ 50MHz），滤除毛刺干扰
- **por_rst_n**: 模拟域上电复位，低有效
- **软复位**: 各模块独立软复位信号，由AHB总线写RMU寄存器配置
- **复位策略**: 各模块实际复位 = pin_rst_n(滤波后) & por_rst_n & 模块软复位
- **复位释放**: 异步复位、同步释放

### 3.3 时钟性能指标

| 参数 | 指标 |
|------|------|
| 主时钟频率 | 50 MHz |
| 时钟周期 | 20 ns |
| 复位脉冲最小宽度 | 100 ns (5个时钟周期) |

---

## 4 AHB-Lite 总线协议

### 4.1 总线概述

平台采用AMBA AHB-Lite协议，1个Master（AHB BFM），6个Slave（SRAM_ECC、UART、DSP、SYS_TC、RMU、CMU）。

### 4.2 AHB-Lite 信号列表

| 信号 | 方向 | 位宽 | 说明 |
|------|------|------|------|
| HCLK | Global | 1 | 总线时钟 |
| HRESETn | Global | 1 | 总线复位（低有效） |
| HADDR | M→S | 32 | 地址总线 |
| HWRITE | M→S | 1 | 读写控制：1=写，0=读 |
| HSIZE | M→S | 3 | 传输大小：010=32bit |
| HBURST | M→S | 3 | 突发类型：000=SINGLE |
| HPROT | M→S | 4 | 保护控制 |
| HTRANS | M→S | 2 | 传输类型：00=IDLE, 10=NONSEQ |
| HWDATA | M→S | 32 | 写数据总线 |
| HSELx | M→S | 1 | Slave选择信号（每个Slave独立） |
| HRDATA | S→M | 32 | 读数据总线 |
| HREADY | S→M | 1 | 传输完成指示 |
| HRESP | S→M | 2 | 传输响应：00=OKAY, 01=ERROR |

### 4.3 传输时序

**基本读传输（无等待）**:

```
         T1        T2
HCLK    _/‾\_/‾\_/‾\_
HTRANS  ----<NONSEQ>----
HADDR   ----< ADDR >----
HWRITE  ----<  0   >----
HREADY  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
HRDATA  ------------<DATA>----
```

**基本写传输（无等待）**:

```
         T1        T2
HCLK    _/‾\_/‾\_/‾\_
HTRANS  ----<NONSEQ>----
HADDR   ----< ADDR >----
HWRITE  ----<  1   >----
HWDATA  ----< DATA >----
HREADY  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
```

---

## 5 地址映射

### 5.1 详细地址映射表

| 模块 | 基地址 | 地址范围 | 空间大小 | 说明 |
|------|--------|----------|----------|------|
| SRAM_ECC | 0x0000_0000 | 0x0000_0000 - 0x0000_03FF | 1KB | 256×32bit |
| UART | 0x1000_0000 | 0x1000_0000 - 0x1000_0FFF | 4KB | 寄存器访问 |
| DSP | 0x2000_0000 | 0x2000_0000 - 0x2000_0FFF | 4KB | 寄存器访问 |
| SYS_TC | 0x3000_0000 | 0x3000_0000 - 0x3000_0FFF | 4KB | 寄存器访问 |
| RMU | 0x4000_0000 | 0x4000_0000 - 0x4000_0FFF | 4KB | 软复位寄存器 |
| CMU | 0x5000_0000 | 0x5000_0000 - 0x5000_0FFF | 4KB | 时钟选择寄存器 |

### 5.2 地址解码方案

使用 HADDR[31:28] 进行Slave选择：

| HADDR[31:28] | 目标Slave |
|--------------|-----------|
| 4'h0 | SRAM_ECC |
| 4'h1 | UART |
| 4'h2 | DSP |
| 4'h3 | SYS_TC |
| 4'h4 | RMU |
| 4'h5 | CMU |
| 其他 | 保留（返回ERROR）|

---

## 6 中断映射

| 中断编号 | 中断源 | 说明 |
|----------|--------|------|
| 0 | SYS_TC | 定时器中断 |
| 1 | UART | UART接收中断 |
| 2 | UART | UART发送完成中断 |
| 3 | DSP | DSP运算完成中断 |
| 4-7 | — | 保留 |

---

## 7 关键性能指标

| 指标 | 参数 |
|------|------|
| 主频 | 50 MHz |
| 工艺节点 | 教学用，不限 |
| 总线协议 | AHB-Lite (AMBA 2.0) |
| SRAM容量 | 256 × 32 bit (1 KB) |
| ECC能力 | SEC-DED (单纠错/双检错) |
| UART波特率 | 115200 bps (可配) |
| 定时器分辨率 | 20 ns (50MHz时钟) |
| 定时器默认周期 | 1 ms (可配) |
| 模块总数 | 8 个 |
| 总线主设备数 | 1 个 |
| 总线从设备数 | 5 个 |
