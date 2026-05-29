# SRAM_ECC 存储模块

## 设计文档

**版本：V0.1.0 2026.05.28**

---

## 1 修改记录

| 版本号 | 修改人 | 修改日期 | 更改理由 | 主要更改内容 |
|--------|--------|----------|----------|-------------|
| V0.1.0 | — | 2026-05-28 | 初建 | SRAM_ECC初始版本 |

---

## 2 简介

SRAM_ECC 模块是一个带 ECC（Error Correction Code）保护的静态随机存储器，容量为 256×32 bit（1KB）。ECC 采用扩展汉明码实现单比特纠错（SEC）和双比特检错（DED），适用于芯片验证教学中的数据完整性保护场景。

---

## 3 特点

- 存储容量：256 × 32 bit（1 KB 数据空间）
- ECC 方案：SEC-DED 扩展汉明码（(39,32) Hamming Code）
- 单比特错误自动纠错，双比特错误检测并报错
- AHB-Lite 从机接口，支持32位字读写
- 字地址访问（AHB 地址 [9:2] 选择 256 个32位字）
- 支持 ECC 状态回读（错误计数、错误地址等）

---

## 4 基本原理

### 4.1 ECC 编码

使用 (39,32) 扩展汉明码：对 32 位数据计算 7 位 ECC 校验位，形成 39 位码字存入 SRAM。

- 6 位 SEC 校验位（p1~p6），实现单比特纠错
- 1 位全局偶校验位（p0），与 SEC 配合实现双比特检错

校验位生成原理：每个校验位对应数据位中特定二进制位置的 XOR 和。

### 4.2 ECC 解码与纠错

读取时重新计算校验位并与存储的校验位比较，得到 6 位 syndrome：
- syndrome = 0：无错误
- syndrome 奇校验（bitcount 为奇数）：单比特错误 → 定位并翻转错误位
- syndrome 非零且偶校验：双比特错误（不可纠正）

---

## 5 结构框图

```
                    ┌──────────── SRAM_ECC ────────────┐
                    │                                    │
  AHB ◄────────────►│  ┌──────────────────┐             │
  从机接口           │  │  AHB 地址译码     │             │
                    │  │  (字地址[9:2])    │             │
                    │  └────────┬─────────┘             │
                    │           │                        │
                    │  ┌────────┴─────────┐             │
                    │  │  ECC 编码器       │             │
                    │  │  32bit→39bit      │──► 39bit   │
                    │  │  (写路径)          │   写入      │
                    │  └──────────────────┘    SRAM     │
                    │                                    │
                    │  ┌──────────────────┐             │
                    │  │  SRAM 存储阵列     │             │
                    │  │  256 × 39 bit     │             │
                    │  └────────┬─────────┘             │
                    │           │                        │
                    │  ┌────────┴─────────┐             │
                    │  │  ECC 解码器       │             │
                    │  │  39bit→32bit      │──► 纠错后   │
                    │  │  + syndrome计算    │    数据     │
                    │  │  + 单bit纠错       │             │
                    │  │  + 双bit检错       │──► ecc_err │
                    │  └──────────────────┘             │
                    │                                    │
                    └────────────────────────────────────┘
```

---

## 6 接口定义

| 信号名 | 方向 | 位宽 | 说明 |
|--------|------|------|------|
| hclk | Input | 1 | AHB 总线时钟 |
| hresetn | Input | 1 | AHB 总线复位（低有效） |
| hsel | Input | 1 | AHB Slave 选择 |
| haddr | Input | 32 | AHB 地址 |
| hwrite | Input | 1 | AHB 读写控制 |
| htrans | Input | 2 | AHB 传输类型 |
| hwdata | Input | 32 | AHB 写数据 |
| hrdata | Output | 32 | AHB 读数据 |
| hready | Output | 1 | AHB 传输完成 |
| hresp | Output | 2 | AHB 传输响应 |
| ecc_err | Output | 1 | ECC 错误指示 |
| ecc_sec | Output | 1 | 单比特错误纠正指示 |
| ecc_ded | Output | 1 | 双比特错误检测指示 |

---

## 7 时钟和复位

- **时钟域**: hclk 域
- **复位**: 复位后 SRAM 内容不变（不初始化），ECC 状态寄存器清零

---

## 8 ECC 算法

### 8.1 (39,32) 扩展汉明码

- **数据位**: d[31:0]（32位）
- **校验位**: p[6:0]（7位）
- **码字**: 39位
- **SEC**: 6位 syndrome 可定位 2^6-1=63 个错误位置，覆盖 39 位码字
- **DED**: 全局偶校验位 p0 与 SEC 配合，区分单bit错误和双bit错误

### 8.2 校验位计算

6 个 SEC 校验位 p[6:1]（p0为全局偶校验）：

每组校验位 = 对应位置 bit 为 1 的所有数据位和数据位位置的 XOR：

```
p[1] = XOR of data bits at positions with bit 0 of index = 1
p[2] = XOR of data bits at positions with bit 1 of index = 1
p[3] = XOR of data bits at positions with bit 2 of index = 1
p[4] = XOR of data bits at positions with bit 3 of index = 1
p[5] = XOR of data bits at positions with bit 4 of index = 1
p[6] = XOR of data bits at positions with bit 5 of index = 1
p[0] = XOR of all 38 bits (32 data + 6 SEC) (整体偶校验)
```

### 8.3 Syndrome 计算与纠错

读取时：
1. 重新计算 6 位校验位 p_calc[6:1]
2. syndrome[6:1] = p_stored[6:1] XOR p_calc[6:1]
3. 计算全局校验 p0_calc，与 p0_stored 比较：
   - 若 syndrome=0, p0_match：无错误
   - 若 syndrome≠0, p0_mismatch：单比特错误，按 syndrome 定位并翻转
   - 若 syndrome≠0, p0_match：双比特错误（仅检测、不纠正）
   - 若 syndrome=0, p0_mismatch：校验位 p0 自身单bit错误（可纠正，可选）

---

## 9 寄存器描述（扩展状态寄存器）

| 偏移地址 | 寄存器名 | 属性 | 复位值 | 说明 |
|----------|----------|------|--------|------|
| 0x00~0x3FC | SRAM | RW | — | 256×32bit 数据空间（字地址） |
| 0x400 | ECC_ERR_CNT | RO | 0x0 | ECC 错误计数 |
| 0x404 | ECC_ERR_ADDR | RO | 0x0 | 最近一次 ECC 错误地址 |
| 0x408 | ECC_CTRL | RW | 0x0 | ECC 控制/状态 |

注：数据空间通过基地址 0x0000_0000 + 字偏移访问（HADDR[9:2]）。

---

## 10 软件配置流程

```
SRAM 基本读写：
  1. 写 SRAM[0] = 0xDEAD_BEEF  // 写入地址0
  2. 读 SRAM[0]                 // 读取地址0，应返回0xDEAD_BEEF

ECC 错误注入与检测（通过 ECC_CTRL 寄存器）：
  1. 写 ECC_CTRL[0]=1          // 使能错误注入模式
  2. 写 SRAM[addr] = data       // 写入时会翻转1个bit
  3. 读 SRAM[addr]              // 读取时自动纠正，返回正确数据
  4. 读 ECC_ERR_CNT             // 应为1，记录一次纠正
```
