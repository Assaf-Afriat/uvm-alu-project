# QuestaSim Elaborate Script for UVM ALU Verification
# Usage: vsim -c -do elaborate.do
# Note: Run this script from the scripts/Run directory

# Set working directory to project root
cd ../..

# Elaborate the top module with CODE COVERAGE enabled
# +cover=bcesft enables: branch, condition, expression, statement, fsm, toggle
vopt +acc=npr +cover=bcesft -o tb_top_opt work.tb_top

quit -force
