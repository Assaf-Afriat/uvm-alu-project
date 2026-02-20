# QuestaSim Compile Script for UVM ALU Verification
# Usage: vsim -c -do compile.do
# Note: Run this script from the scripts/Run directory
# It will change to project root (../../) before compiling

# Set working directory to project root
cd ../..

# Create work library in sim/ folder
vlib sim/work
vmap work sim/work

# Compile interface
vlog -sv -work work +incdir+interface interface/alu_if.sv

# Compile DUT with CODE COVERAGE enabled
# +cover=bcesft enables: branch, condition, expression, statement, fsm, toggle
vlog -sv -work work +cover=bcesft +incdir+dut dut/dut.sv

# Compile SVA Assertions
vlog -sv -work work +incdir+sva sva/alu_assertions.sv

# Compile testbench top (includes alu_pkg.sv which includes all UVM components)
vlog -sv -work work +incdir+. +incdir+agent +incdir+env +incdir+scoreboard +incdir+sequences +incdir+test tb_top.sv

quit -force
