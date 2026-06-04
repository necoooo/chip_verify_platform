# UART (通用异步收发器) 验证方案

**版本：V1.0 2026.05.29**

## 1 验证目标

验证UART模块的全双工异步收发(8N1格式)、可配置波特率(115200/57600/9600)、AHB寄存器(CTRL/BAUD/STATUS/TXD/RXD)访问、接收器抗干扰(假起始位/帧错误/溢出)、tx_int/rx_int中断输出。

## 2 验证环境架构

```
test_uart_<name> (uvm_test, 继承 uart_base_test)
  └── uart_env (uvm_env)
        ├── ahb_agent (复用公共AHB Agent, 寄存器配置)
        ├── uart_agent (UART物理层Agent, 系统级复用)
        │     ├── uart_driver — 驱动uart_rx引脚模拟外部发送
        │     └── uart_monitor — 监测uart_tx引脚解析数据帧
        ├── uart_scoreboard — 比对发送/接收数据一致性
        └── uart_coverage — 数据字节遍历/波特率/错误类型覆盖
```

### 模块级测试连接

模块级测试中：
- uart_driver驱动uart_rx_i → DUT接收
- uart_monitor监测uart_tx_o → 采集DUT发送的数据
- ahb_agent通过AHB配置寄存器、读状态、写TXD/读RXD

## 3 测试策略

### 3.1 Sanity测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_uart_sanity | 写TXD=0x55，uart_monitor采集tx波形验证起始+数据+停止 | TP_UART_001.01 |

### 3.2 功能测试

| 用例名 | 描述 | 对应测试点 |
|--------|------|-----------|
| test_uart_tx_all_bytes | 遍历发送0x00-0xFF全部256种字节 | TP_UART_001.02 |
| test_uart_rx_basic | uart_driver驱动rx=0xAA，读RXD验证 | TP_UART_002.01 |
| test_uart_rx_all_bytes | 遍历接收0x00-0xFF全部数据 | TP_UART_002.02 |
| test_uart_full_duplex | 同时发送和接收，验证全双工互不干扰 | TP_UART_003.01 |
| test_uart_baud_default | 读BAUD_DIV默认=433，测量位宽验证115200bps | TP_UART_004.01 |
| test_uart_baud_change_57600 | 修改BAUD_DIV=867，验证57600bps | TP_UART_004.02 |
| test_uart_baud_change_9600 | 修改BAUD_DIV=5207，验证9600bps | TP_UART_004.03 |
| test_uart_rx_false_start | 驱动短脉冲(<半bit)假起始位，验证不误触发 | TP_UART_005.01 |
| test_uart_frame_err | 驱动停止位=0的帧，验证FRAME_ERR=1 | TP_UART_006.01 |
| test_uart_rx_overflow | 连续驱动两帧不读RXD，验证RX_OVERFLOW=1 | TP_UART_006.02 |
| test_uart_tx_disable | TX_EN=0→写TXD无波形输出 | TP_UART_007.01 |
| test_uart_rx_disable | RX_EN=0→RX不响应 | TP_UART_007.02 |
| test_uart_reg_rw | 5个UART寄存器(CTRL/BAUD/STATUS/TXD/RXD)属性验证 | TP_UART_008.01 |
| test_uart_int_tx | 发送完成后tx_int脉冲与TX_DONE同步 | TP_UART_009.01 |
| test_uart_int_rx | 接收完成后rx_int脉冲与RX_VALID同步 | TP_UART_009.02 |
| test_uart_full_flow | 初始化→发送→接收→中断处理完整流程 | TP_UART_010.01 |

### 3.3 覆盖率目标

| 覆盖类型 | 目标 | 关键覆盖项 |
|----------|------|-----------|
| 功能覆盖率 | 100% | 256字节遍历、3种波特率、EN组合、所有错误类型 |
| 代码覆盖率 | 100% | 行/分支/条件/FSM(TX状态机4状态+RX状态机4状态) |

## 4 检查器

- SVA: 发送帧格式正确(起始+8数据LSB+停止)
- SVA: 接收16倍过采样时序
- Scoreboard: 收发数据一致性比对

## 5 资源需求

- 仿真器: Synopsys VCS + UVM 1.2
- 预计仿真时间: <5分钟
