# ==========================================
# 1. Path Setting (경로 설정)
# ==========================================
# 기존의 slow 라이브러리 경로 유지
set_db init_lib_search_path "/home/s_2025_h007/PROJECT/HDMI_DDR/edu_lib/timing/"
set_db init_hdl_search_path "../sim/" 

# ==========================================
# 2. Read (파일 읽기)
# ==========================================
read_libs "slow_vdd1v0_basicCells.lib"
read_hdl async_fifo.v AXI4_writer.v 

# ==========================================
# 3. Elaborate (구조 정리)
# ==========================================
elaborate AXI4_writer 
set_db / .use_scan_seqs_for_non_dft false
# ==========================================
# 4. Constraints (제약조건)
# ==========================================
# [수정] SDC 파일명 변경
read_sdc ./AXI4_writer.sdc 

# ==========================================
# 5. Synthesis Effort (합성 강도 설정 - 기존 유지)
# ==========================================
set_db syn_generic_effort medium 
set_db syn_map_effort medium
set_db syn_opt_effort medium

# ==========================================
# 6. Run Synthesis (합성 실행)
# ==========================================
syn_generic
syn_map
syn_opt

# ==========================================
# 7. Reports & Outputs (결과 출력)
# ==========================================
# 폴더가 없을 경우 Genus가 에러를 뱉고 멈추므로 폴더 자동 생성 명령어 추가
file mkdir reports
file mkdir outputs

# 리포트 생성
report_timing > reports/test_timing.rpt
report_power > reports/test_power.rpt
report_area > reports/test_area.rpt
report_qor > reports/test_qor.rpt

#  출력 파일명
write_hdl > outputs/AXI4_writer_netlist.v
write_sdc > outputs/AXI4_writer_sdc.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > outputs/AXI4_writer_sdf.sdf
