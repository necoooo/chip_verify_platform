# AHB 总线矩阵（AHB Matrix）

## 设计文档

**版本：V0.1.0 2026.05.28**

---

## 1 修改记录

| 版本号 | 修改人 | 修改日期 | 更改理由 | 主要更改内容 |
|--------|--------|----------|----------|-------------|
| V0.1.0 | — | 2026-05-28 | 初建 | AHB Matrix初始版本 |

---

## 2 简介

AHB 总线矩阵是芯片的总线互联中枢，负责将一个 AHB-Lite Master（AHB BFM）的访问请求根据地址路由到对应的 Slave，并将 Slave 的响应信号（HRDATA、HREADY、HRESP）多路复用回 Master。支持1主6从的 AHB-Lite 总线拓扑。

---

## 3 特点

- 1 Master × 6 Slave AHB-Lite 总线矩阵
- 地址解码：HADDR[31:28] 选择目标 Slave
- 所有 Slave 共享同一套 Master 侧控制信号（HADDR、HWRITE、HWDATA 等）
- 输出 HSELx 选择信号给各 Slave
- 集中 HRDATA/HREADY/HRESP 多路复用
- 纯组合逻辑，无时钟依赖

---

## 4 基本原理

AHB Matrix 为全互联结构，接收 Master 的地址和控制信号，根据 HADDR[31:28] 译码产生 HSELx 信号，选中唯一的目标 Slave 进行通信。同时，根据当前选中的 Slave，将其 HRDATA、HREADY、HRESP 信号多路复用后返回给 Master。

---

## 5 结构框图

```
                     ┌─────── AHB Matrix ───────┐
                     │                            │
  Master ───────────►│ HADDR[31:28] ──► 地址译码   │
   HADDR             │                    │        │
   HWRITE            │                    v        │
   HSIZE             │               HSEL[5:0]     │──► Slave[5:0]
   HWDATA            │               ──────────────│
   HTRANS            │                             │
   ...               │  共享信号 ─────────────────────│──► 所有Slave
                     │                             │
  Master ◄───────────│  HRDATA ◄── 多路复用 ◄───────│─── Slave HRDATA
   HRDATA            │  HREADY ◄── 多路复用 ◄───────│─── Slave HREADY
   HREADY            │  HRESP  ◄── 多路复用 ◄───────│─── Slave HRESP
   HRESP             │                             │
                     └─────────────────────────────┘
```

---

## 6 接口定义

### 6.1 Master 侧

| 信号名 | 方向 | 位宽 | 说明 |
|--------|------|------|------|
| m_haddr | Input | 32 | Master地址 |
| m_hwrite | Input | 1 | Master读写控制 |
| m_hsize | Input | 3 | Master传输大小 |
| m_hburst | Input | 3 | Master突发类型 |
| m_hprot | Input | 4 | Master保护控制 |
| m_htrans | Input | 2 | Master传输类型 |
| m_hwdata | Input | 32 | Master写数据 |
| m_hrdata | Output | 32 | 返回Master的读数据 |
| m_hready | Output | 1 | 返回Master的传输完成 |
| m_hresp | Output | 2 | 返回Master的传输响应 |

### 6.2 Slave 侧

| 信号名 | 方向 | 位宽 | 说明 |
|--------|------|------|------|
| s_hsel[5:0] | Output | 6 | 各Slave选择信号 |
| s_haddr | Output | 32 | 共享地址总线 |
| s_hwrite | Output | 1 | 共享读写控制 |
| s_hsize | Output | 3 | 共享传输大小 |
| s_hburst | Output | 3 | 共享突发类型 |
| s_hprot | Output | 4 | 共享保护控制 |
| s_htrans | Output | 2 | 共享传输类型 |
| s_hwdata | Output | 32 | 共享写数据总线 |
| s_hrdata[5:0] | Input | 32×6 | 各Slave读数据（展开） |
| s_hready[5:0] | Input | 6 | 各Slave传输完成 |
| s_hresp[5:0] | Input | 2×6 | 各Slave传输响应 |

---

## 7 地址译码

| HADDR[31:28] | HSEL | 目标Slave |
|--------------|------|-----------|
| 4'h0 | [0] | SRAM_ECC |
| 4'h1 | [1] | UART |
| 4'h2 | [2] | DSP |
| 4'h3 | [3] | SYS_TC |
| 4'h4 | [4] | RMU |
| 4'h5 | [5] | CMU |
| 其他 | 无 | 保留（默认选SRAM_ECC，返回ERROR） |

---

## 8 功能描述

### 8.1 地址译码

地址译码为纯组合逻辑，当 HTRANS 为非 IDLE（即 HTRANS[1] = 1）时，根据 HADDR[31:28] 产生唯一的 HSEL 信号。IDLE 周期不产生 HSEL。

### 8.2 响应多路复用

根据当前 HSEL 选中的 Slave，将其 HRDATA、HREADY、HRESP 多路复用送回 Master。默认状态（无 Slave 选中时）返回 HREADY=1、HRESP=ERROR、HRDATA=0。

---

## 9 关键技术指标

| 参数 | 值 |
|------|-----|
| Master数量 | 1 |
| Slave数量 | 6 |
| 地址总线宽度 | 32 bit |
| 数据总线宽度 | 32 bit |
| 译码方式 | 高4位地址译码 |
| 延迟 | 组合逻辑，0周期 |
