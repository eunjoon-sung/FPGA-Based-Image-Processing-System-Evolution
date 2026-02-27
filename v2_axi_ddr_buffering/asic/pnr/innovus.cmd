#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Sat Feb 28 03:44:54 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v21.16-s078_1 (64bit) 12/07/2022 12:07 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 21.16-s078_1 NR221206-1807/21_16-UB (database version 18.20.600) {superthreading v2.17}
#@(#)CDS: AAE 21.16-s035 (64bit) 12/07/2022 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 21.16-s024_1 () Dec  5 2022 05:41:45 ( )
#@(#)CDS: SYNTECH 21.16-s009_1 () Nov  9 2022 03:47:50 ( )
#@(#)CDS: CPE v21.16-s066
#@(#)CDS: IQuantus/TQuantus 21.1.1-s939 (64bit) Wed Nov 9 09:34:24 PST 2022 (Linux 3.10.0-693.el7.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
win
save_global 20260227.globals
set init_gnd_net VSS
set init_lef_file {../edu_lib/lef/gsclib045_tech.lef ../edu_lib/lef/gsclib045_macro.lef}
set init_verilog ../syn/outputs/AXI4_writer_netlist.v
set init_mmmc_file 20260227.view
set init_pwr_net VDD
init_design

getIoFlowFlag
setIoFlowFlag 0
floorPlan -site CoreSite -r 0.98949398777 0.699999 10.0 10.0 10.0 10.0
uiSetTool select
getIoFlowFlag
fit
setIoFlowFlag 0
floorPlan -site CoreSite -r 0.988966365874 0.699626 10.0 10.07 10.0 10.07
uiSetTool select
getIoFlowFlag
fit
