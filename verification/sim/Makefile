#--------------------------------------------------------------
# VCS仿真Makefile
# 版本: V1.0 2026.05.29
#       V1.1 2026.06.03 (添加-timescale, 修复RTL/env路径)
#       V1.2 2026.06.03 (添加make verdi一键波形, .last_module)
#       V1.3 2026.06.03 (改用VCD dump, 清理冗余)
#
# 用法:
#   make compile MODULE=cmu       # 编译
#   make run                      # 运行仿真
#   make all MODULE=cmu           # 编译+运行
#   make verdi                    # 一键打开Verdi(代码+波形)
#   make cov_report MODULE=cmu    # 覆盖率报告
#   make clean                    # 清理
#--------------------------------------------------------------

# ==============================================================
# 仿真器配置
# ==============================================================
VCS         = vcs
SIMV        = ./simv
VCS_FLAGS   = -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 -full64 -debug_access+all -kdb -lca
COV_FLAGS   = -cm line+cond+tgl+branch+fsm -cm_dir coverage/$(MODULE).vdb

# 默认测试用例
# MODULE从命令行或.last_module获取
MODULE     ?= $(shell cat .last_module 2>/dev/null)
TEST       ?= test_$(MODULE)_sanity

# 路径 (相对于sim/目录)
VERIF_DIR   = ..
TB_SRC      = $(VERIF_DIR)/tb/module_tb.sv
ENV_FLIST   = $(VERIF_DIR)/env/env_filelist.f
MODULE_FLIST= $(VERIF_DIR)/harness/BT/$(MODULE)/$(MODULE)_filelist.f
MODULE_RTL_F= ../../design/rtl/$(MODULE)/$(MODULE).f
MODULE_RTL_INCDIR = +incdir+../../design/rtl/$(MODULE)
CHIP_RTL_F  = ../../design/rtl/chip_top.f
MODULE_DEF  = +define+DUT_$(shell echo $(MODULE) | tr 'a-z' 'A-Z')

# ==============================================================
# 编译
# ==============================================================
compile:
ifeq ($(MODULE),)
	$(error "Please specify MODULE=<name>. Usage: make compile MODULE=cmu")
endif
ifeq ($(MODULE),chip)
	@echo "================================================"
	@echo "Compiling CHIP-LEVEL UVM (flist: $(CHIP_RTL_F))"
	@echo "================================================"
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) \
		-f $(ENV_FLIST) -f $(CHIP_RTL_F) $(TB_SRC) \
		-o $(SIMV) -l compile.log
	@echo $(MODULE) > .last_module
else
	@echo "================================================"
	@echo "Compiling UVM for: $(MODULE)"
	@echo "================================================"
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) $(MODULE_DEF) \
		-f $(ENV_FLIST) -f $(MODULE_FLIST) -f $(MODULE_RTL_F) \
		$(MODULE_RTL_INCDIR) $(TB_SRC) \
		-o $(SIMV) -l compile.log
	@echo $(MODULE) > .last_module
endif

# ==============================================================
# 运行仿真
# ==============================================================

run:
	@echo "Running test: $(TEST)"
	timeout 60 $(SIMV) +UVM_TESTNAME=$(TEST) +UVM_MAX_QUIT_COUNT=10 -l simv.log ; vcd2fsdb module_tb.vcd -o module_tb.fsdb

# ==============================================================
# 编译+运行
# ==============================================================
all: compile run

# ==============================================================
# 覆盖率
# ==============================================================
cov_report:
	urg -dir coverage/$(MODULE).vdb -report coverage/$(MODULE)_report -format both

cov_view:
	dve -cov -covdir coverage/$(MODULE).vdb &

# ==============================================================
# Verdi 一键波形查看 (无需参数)
# ==============================================================
verdi:
	@LAST=$$(cat .last_module 2>/dev/null || echo ""); \
	DUT_MACRO=$$(echo $$LAST | tr 'a-z' 'A-Z'); \
	echo "Opening Verdi (top=module_tb, module=$$LAST)..."; \
	verdi -sv -ntb_opts uvm-1.2 -top module_tb \
		+define+DUT_$$DUT_MACRO \
		-ssf module_tb.fsdb \
		-f $(ENV_FLIST) \
		-f $(VERIF_DIR)/harness/BT/$$LAST/$${LAST}_filelist.f \
		-f ../../design/rtl/$$LAST/$$LAST.f \
		+incdir+../../design/rtl/$$LAST \
		$(TB_SRC) &

# ==============================================================
# 清理
# ==============================================================
clean:
	rm -rf simv* csrc* *.log *.daidir *.vpd *.vcd *.fsdb ucli.key \
		vc_hdrs.h DVEfiles urgReport coverage .last_module novas*

# ==============================================================
# 帮助
# ==============================================================
help:
	@echo "Chip Verification Platform - VCS UVM Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make compile MODULE=<name>   - Compile verification"
	@echo "  make run                      - Run simulation"
	@echo "  make all MODULE=<name>       - Compile + Run"
	@echo "  make verdi                    - Open Verdi (code + waves)"
	@echo "  make cov_report MODULE=<name>- Generate coverage report"
	@echo "  make clean                    - Clean"
	@echo ""
	@echo "Modules: cmu, rmu, dsp, sys_tc, sram_ecc, uart, ahb_matrix, chip"

.PHONY: compile run all cov_report cov_view verdi clean help
