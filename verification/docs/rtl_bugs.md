# RTL Bugs 记录

**创建**: 2026-06-04 | **阶段**: Sanity 调试 → 详细验证
**最后更新**: 2026-06-08

---

## CMU
| ID | 严重度 | 描述 | 修复 | 日期 |
|----|--------|------|------|------|
| CMU-01 | HIGH | 无上电复位, X态扩散至clk_sel/hclk_o | V1.1 initial块 | 0604 |
| CMU-02 | HIGH | FSM用hclk_o做时钟, 切换时钟时hclk停振→死锁 | V1.2 改用pll_clk_i | 0604 |
| CMU-03 | HIGH | AHB(hclk_o域)与FSM(pll_clk_i域)跨时钟域 | V1.4 CDC 2-FF同步 | 0608 |
| CMU-04 | HIGH | clk_sel_req兼具触发+数据→写0时if(clk_sel_req)为假→FSM不启动 | V1.5 分离触发与数据 | 0608 |

## RMU
| ID | 严重度 | 描述 | 修复 | 日期 |
|----|--------|------|------|------|
| RMU-01 | HIGH | por_rst_ni直连高, 滤波器寄存器无异步复位→X态扩散 | V1.1 initial块 | 0604 |

## SYS_TC — 无RTL问题
## DSP — 无RTL问题

## SRAM_ECC
| ID | 严重度 | 描述 | 修复 | 日期 |
|----|--------|------|------|------|
| SRAM-01 | MEDIUM | regif读路径一周期延迟, hready恒为1→读返回前一地址数据 | V1.1 rd_addr_o改组合逻辑 | 0604 |

## UART
| ID | 严重度 | 描述 | 修复 | 日期 |
|----|--------|------|------|------|
| UART-01 | HIGH | 寄存器地址解码用haddr[3:0], RXD(0x10)与CTRL(0x00)冲突 | 改为[5:0] | 0604 |
| UART-02 | HIGH | TX/RX共享波特率计数器, 回环时互相干扰 | V1.2 独立计数器 | 0604 |
| UART-03 | MEDIUM | agent: is_active遮蔽+缺sequencer+uart_if无hclk | 修复agent架构 | 0604 |
| UART-04 | MEDIUM | driver NBA(`<=`)驱动virtual interface不生效 | 📝 待修复(验证环境) | 0604 |
| UART-05 | HIGH | rx_overflow_o: NBA导致if(rx_valid_o)永远读到旧值0, 溢出永不检测 | V1.3 rx_pending标志+rx_clear信号 | 0608 |

## DSP
| ID | 严重度 | 描述 | 修复 | 日期 |
|----|--------|------|------|------|
| DSP-01 | MEDIUM | done_latch清除未检查ahb_active/hwrite, 空闲周期误清除 | V1.1 添加ahb_active+!hwrite_i条件 | 0608 |

## AHB_MATRIX — 无RTL问题

---

**统计**: HIGH 8(已修复8) | MEDIUM 4(已修复3) | 待修复 1(UART-04验证环境) |
