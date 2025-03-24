if {[catch {

# define run engine funtion
source [file join {/home/seb/lscc/radiant/2024.2} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) "1"
set para(prj_dir) "/home/seb/ecam/robot/project/robot"
if {![file exists {/home/seb/ecam/robot/project/robot/impl_1}]} {
  file mkdir {/home/seb/ecam/robot/project/robot/impl_1}
}
cd {/home/seb/ecam/robot/project/robot/impl_1}
# synthesize IPs
# synthesize VMs
# synthesize top design
file delete -force -- robot_impl_1.vm robot_impl_1.ldc
if {[file normalize "/home/seb/ecam/robot/project/robot/impl_1/robot_impl_1_synplify.tcl"] != [file normalize "./robot_impl_1_synplify.tcl"]} {
  file copy -force "/home/seb/ecam/robot/project/robot/impl_1/robot_impl_1_synplify.tcl" "./robot_impl_1_synplify.tcl"
}
if {[ catch {::radiant::runengine::run_engine synpwrap -prj "robot_impl_1_synplify.tcl" -log "robot_impl_1.srf"} result options ]} {
    file delete -force -- robot_impl_1.vm robot_impl_1.ldc
    return -options $options $result
}
::radiant::runengine::run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o robot_impl_1_syn.udb robot_impl_1.vm] [list robot_impl_1.ldc]

} out]} {
   ::radiant::runengine::runtime_log $out
   exit 1
}
