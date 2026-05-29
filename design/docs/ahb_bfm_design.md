# AHB 总线功能模型（AHB BFM）

## 设计文档

**版本：V0.1.0 2026.05.28**

---

## 1 修改记录

| 版本号 | 修改人 | 修改日期 | 更改理由 | 主要更改内容 |
|--------|--------|----------|----------|-------------|
| V0.1.0 | — | 2026-05-28 | 初建 | AHB BFM初始版本 |

---

## 2 简介

AHB 总线功能模型（Bus Functional Model, BFM）是一个用于芯片验证仿真的 AHB-Lite Master 行为模型。它替代真实 CPU，在仿真环境中发起 AHB-Lite 读写交易，用于验证各从模块的寄存器访问和 SRAM 读写功能。

---

## 3 特点

- 实现 AHB-Lite Master 协议
- 支持单次读写（SINGLE burst）
- 支持任务级接口：`ahb_write(addr, data)` 和 `ahb_read(addr)` → data
- 自动处理 HREADY 等待状态
- 32位地址、32位数据
- 纯仿真模型，不可综合

---

## 4 基本原理

BFM 内部包含一个简单的 AHB-Lite Master 状态机，通过 SystemVerilog task（或 Verilog 的 task 等效行为）封装 AHB 读写时序。外部测试代码调用 `ahb_write` / `ahb_read` 任务即可发起 AHB 传输，BFM 自动完成地址阶段和数据阶段的时序控制。

---

## 5 结构框图

```
                    ┌────────────── AHB BFM ──────────────┐
                    │                                      │
                    │  ┌────────────────────┐              │
   ahb_write() ────►│  │   Task Interface    │              │
   ahb_read()  ────►│  │   (仿真任务封装)     │              │
                    │  └────────┬───────────┘              │
                    │           │                          │
                    │  ┌────────┴───────────┐              │
  hclk ────────────►│  │  AHB Master 状态机  │─────────────►│──► m_haddr
  hresetn ─────────►│  │                    │─────────────►│──► m_hwrite
                    │  │  IDLE → ADDR → DATA │─────────────►│──► m_htrans
                    │  │                    │─────────────►│──► m_hwdata
  m_hrdata ◄────────│──│                    │◄─────────────│─── m_hrdata
  m_hready ◄────────│──│                    │◄─────────────│─── m_hready
                    │  └────────────────────┘              │
                    │                                      │
                    └──────────────────────────────────────┘
```

---

## 6 接口定义

| 信号名 | 方向 | 位宽 | 说明 |
|--------|------|------|------|
| hclk | Input | 1 | AHB 总线时钟 |
| hresetn | Input | 1 | AHB 总线复位（低有效） |
| m_haddr | Output | 32 | Master 地址 |
| m_hwrite | Output | 1 | Master 读写控制 |
| m_hsize | Output | 3 | Master 传输大小（固定 010=32bit） |
| m_hburst | Output | 3 | Master 突发类型（固定 000=SINGLE） |
| m_hprot | Output | 4 | Master 保护控制（固定 4'b0011） |
| m_htrans | Output | 2 | Master 传输类型 |
| m_hwdata | Output | 32 | Master 写数据 |
| m_hrdata | Input | 32 | Slave 返回的读数据 |
| m_hready | Input | 1 | Slave 返回的传输完成 |

---

## 7 时钟和复位

- **时钟域**: hclk 域（50MHz）
- **复位**: 复位后状态机回到 IDLE，所有 Master 输出清零

---

## 8 功能描述

### 8.1 AHB 读操作（ahb_read）

```
时序：
         ADDR_PHASE    DATA_PHASE
HCLK    _/‾\_/‾\_/‾\_/‾\_/‾\_
HTRANS  ----<NONSEQ>----<IDLE>----
HADDR   ----< ADDR >--------------
HWRITE  ----<  0   >--------------
HREADY  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
HRDATA  ------------<RDATA>-------
```

流程：
1. 地址阶段：驱动 HADDR=addr, HWRITE=0, HTRANS=NONSEQ
2. 等待 HREADY=1（地址阶段完成）
3. 数据阶段：采样 HRDATA，HTRANS=IDLE
4. 返回读取的32位数据

### 8.2 AHB 写操作（ahb_write）

```
时序：
         ADDR_PHASE    DATA_PHASE
HCLK    _/‾\_/‾\_/‾\_/‾\_/‾\_
HTRANS  ----<NONSEQ>----<IDLE>----
HADDR   ----< ADDR >--------------
HWRITE  ----<  1   >--------------
HWDATA  ----<WDATA>--------------
HREADY  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
```

流程：
1. 地址阶段：驱动 HADDR=addr, HWRITE=1, HWDATA=data, HTRANS=NONSEQ
2. 等待 HREADY=1（地址阶段+数据阶段同时完成）
3. 回到 IDLE

---

## 9 使用示例

```verilog
// 在测试代码中调用
initial begin
    // 等待复位释放
    @(posedge hclk);
    @(posedge hclk);

    // 写操作：配置 UART 波特率
    ahb_write(32'h1000_0004, 32'd434);  // UART_BAUD = 434 (115200bps@50MHz)

    // 读操作：读取 UART 状态
    ahb_read(32'h1000_0008, read_data);
    $display("UART_STATUS = 0x%h", read_data);
end
```
