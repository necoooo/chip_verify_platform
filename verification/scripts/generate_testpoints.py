#!/usr/bin/env python3
"""
验证测试点 Excel 生成器
用法: python3 generate_testpoints.py <module_name>

数据格式 (_data.py):
  MODULE     - 模块名
  SOURCE     - 设计文档路径 (如 'design/docs/cmu_design.md')
  TESTPOINTS - [(src,func,main,sub,desc,type,covd,cova), ...] 8元组
               src/func/main为None表示与上行合并
  FUNCTIONS  - [name, ...] 输入组合分析功能列表
  CROSS_DATA - {(i,j): (desc, is_valid)} 交叉项描述,bool
"""
import sys, os
for p in ['/tmp/XlsxWriter-RELEASE_3.2.0']:
    if os.path.isdir(p): sys.path.insert(0, p)
import xlsxwriter

def _fmt(wb):
    return {
        'hdr':  wb.add_format({'bold':True,'bg_color':'#D9E1F2','border':1,'text_wrap':True,'valign':'vcenter','align':'center'}),
        'cell': wb.add_format({'border':1,'text_wrap':True,'valign':'vcenter'}),
        'cc':   wb.add_format({'border':1,'text_wrap':True,'valign':'vcenter','align':'center'}),
        'mrg':  wb.add_format({'bold':True,'border':1,'text_wrap':True,'valign':'vcenter','align':'center','bg_color':'#E2EFDA'}),
        'mhdr': wb.add_format({'bold':True,'border':1,'bg_color':'#D9E1F2','text_wrap':True,'valign':'vcenter','align':'center','font_size':9}),
        'diag': wb.add_format({'border':1,'bg_color':'#D9D9D9','align':'center','font_size':9}),
        'valid': wb.add_format({'border':1,'bg_color':'#C6EFCE','text_wrap':True,'valign':'vcenter','align':'center','font_size':9}),
        'invalid': wb.add_format({'border':1,'bg_color':'#D9D9D9','text_wrap':True,'valign':'vcenter','align':'center','font_size':9}),
    }

HEADERS = ['测试点来源','功能点','主测试点','子测试点','描述','类型',
           '覆盖率描述','覆盖率分析','覆盖率完成情况','验证结果']

def build_sheet1(wb, ws, testpoints, source):
    """测试点列表 (10列, 无输入组合分析列)"""
    F = _fmt(wb)
    ws.set_column(0,0,28); ws.set_column(1,1,10); ws.set_column(2,2,18)
    ws.set_column(3,3,18); ws.set_column(4,4,42); ws.set_column(5,5,8)
    ws.set_column(6,6,25); ws.set_column(7,7,35)
    ws.set_column(8,8,14); ws.set_column(9,9,10)
    for c,h in enumerate(HEADERS): ws.write(0,c,h,F['hdr'])

    ROW = 1
    disp = [source, '', '']  # col0=source, col1=func, col2=main
    for i,tp in enumerate(testpoints):
        r = ROW + i
        src, func, main, sub, desc, ttype, covd, cova = tp
        if func is not None: disp[1] = func
        if main is not None: disp[2] = main
        ws.write(r,0, disp[0], F['cell'])
        ws.write(r,1, disp[1], F['cell'])
        ws.write(r,2, disp[2], F['cell'])
        ws.write(r,3, sub, F['cell'])
        ws.write(r,4, desc, F['cell'])
        ws.write(r,5, ttype, F['cc'])
        ws.write(r,6, covd, F['cell'])
        ws.write(r,7, cova, F['cell'])
        ws.write(r,8, '', F['cell'])
        ws.write(r,9, '', F['cell'])

    LAST = ROW + len(testpoints) - 1
    # Col 0: merge all rows (single source document)
    ws.merge_range(ROW, 0, LAST, 0, source, F['mrg'])

    # Cols 1,2: merge consecutive same-value rows
    for col in [1,2]:
        i = 0
        while i < len(testpoints):
            val = _prev_val(testpoints, i, col)
            j = i + 1
            while j < len(testpoints) and _prev_val(testpoints, j, col) == val:
                j += 1
            if j - i > 1:
                ws.merge_range(ROW + i, col, ROW + j - 1, col, val, F['cell'])
            i = j

def _prev_val(tp, idx, col):
    """Find the last non-None value in column col at or before idx"""
    for j in range(idx, -1, -1):
        v = tp[j][col]
        if v is not None: return v
    return ''

def build_sheet2(wb, ws, functions, cross_data):
    """输入组合分析矩阵"""
    F = _fmt(wb)
    n = len(functions)
    ws.set_column(0,0,22)
    for i in range(1, n+1): ws.set_column(i, i, 18)
    ws.write(0,0,'交叉功能',F['mhdr'])
    for i,f in enumerate(functions):
        ws.write(0,i+1, f'{i+1}.{f[:14]}', F['mhdr'])
        ws.write(i+1,0, f'{i+1}.{f[:20]}', F['mhdr'])
    for i in range(n):
        ws.write(i+1,i+1,'—',F['diag'])
        for j in range(n):
            if i == j: continue
            k = (min(i,j), max(i,j))
            if k in cross_data:
                d,v = cross_data[k]
                ws.write(i+1,j+1, d, F['valid'] if v else F['invalid'])
            else:
                ws.write(i+1,j+1,'未定义',F['invalid'])

def generate(module, source, testpoints, functions, cross_data, outdir):
    wb = xlsxwriter.Workbook(f'{outdir}/{module}_testpoints.xlsx')
    build_sheet1(wb, wb.add_worksheet('测试点'), testpoints, source)
    build_sheet2(wb, wb.add_worksheet('输入组合分析'), functions, cross_data)
    wb.close()
    print(f"Generated: {module}_testpoints.xlsx ({len(testpoints)} TPs, {len(functions)}x{len(functions)} matrix)")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 generate_testpoints.py <module_name>")
        sys.exit(1)
    mod = sys.argv[1]
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, script_dir)
    data = __import__(f'{mod}_data')
    outdir = os.path.join(os.path.dirname(script_dir), 'docs', 'testpoints')
    generate(data.MODULE, data.SOURCE, data.TESTPOINTS, data.FUNCTIONS, data.CROSS_DATA, outdir)
