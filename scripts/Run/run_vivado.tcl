# Vivado Tcl Script for UVM ALU Simulation
# Usage: vivado -mode batch -source run_vivado.tcl

# 1. Create Project
set project_name "cpm_uvm_proj"
set project_dir "vivado_proj"
create_project -force $project_name $project_dir -part xc7a35tcpg236-1

# 2. Add Sources
# Note: Paths are relative to where you run the script (scripts/Run)
add_files -norecurse {
    ../../interface/alu_if.sv
    ../../dut/dut.sv
    ../../alu_pkg.sv
    ../../tb_top.sv
}

# 3. Add Include Directories (for UVM macros and package includes)
set_property include_dirs {
    ../../ 
    ../../agent 
    ../../env 
    ../../sequences 
    ../../scoreboard 
    ../../test
} [get_filesets sources_1]

# 4. Configure Simulation
set_property top tb_top [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {10us} -objects [get_filesets sim_1]

# Enable UVM (Vivado has pre-compiled UVM 1.2)
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]

# 5. Run Simulation
launch_simulation
run all
