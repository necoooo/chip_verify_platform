//--------------------------------------------------------------
// 芯片顶层 RTL Filelist (chip_top.f)
// 路径: design/rtl/chip_top.f
// 用途: 芯片级仿真加载全部RTL设计文件
// 说明: 通过 -f 引用各模块目录下的 .f 文件，不重复列出文件
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

// 各模块RTL文件的搜索路径 (模块.f中仅含文件名，此处提供incdir)
+incdir+../design/rtl/cmu
+incdir+../design/rtl/rmu
+incdir+../design/rtl/ahb_matrix
+incdir+../design/rtl/uart
+incdir+../design/rtl/dsp
+incdir+../design/rtl/sys_tc
+incdir+../design/rtl/sram_ecc
+incdir+../design/rtl/ahb_bfm

// 各模块RTL文件清单 (每个模块目录下自行管理)
-f ../design/rtl/ahb_bfm/ahb_bfm.f
-f ../design/rtl/cmu/cmu.f
-f ../design/rtl/rmu/rmu.f
-f ../design/rtl/ahb_matrix/ahb_matrix.f
-f ../design/rtl/uart/uart.f
-f ../design/rtl/dsp/dsp.f
-f ../design/rtl/sys_tc/sys_tc.f
-f ../design/rtl/sram_ecc/sram_ecc.f

// 芯片顶层集成
../design/rtl/chip_top.v
