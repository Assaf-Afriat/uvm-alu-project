import os
import sys
import argparse
import time
from pathlib import Path

# --- Constants ---
# Assuming the user has UVM_HOME set, or we can try to find it.
# If iverilog is installed, UVM might not be bundled.
# Usage: python run.py --test alu_test

def run_command(command, step_name, cwd=None):
    """Runs a shell command and exits if it fails."""
    print(f"\n--- INFO: Starting Step: {step_name} ---")
    print(f"Executing: {command}")
    
    if cwd:
        print(f"Working directory: {cwd}")
        
    start_time = time.time()
    return_code = os.system(command)
    elapsed = time.time() - start_time
    
    if return_code != 0:
        print(f"\n--- ERROR: Step '{step_name}' failed! (RC={return_code}) ---")
        sys.exit(1)
    else:
        print(f"--- Step '{step_name}' completed in {elapsed:.2f}s ---")

try:
    parser = argparse.ArgumentParser(description="Run Icarus Verilog Simulation for UVM ALU")
    parser.add_argument('--test', type=str, default='alu_test', help="UVM Test name")
    parser.add_argument('--clean', action='store_true', help="Clean previous run")
    parser.add_argument('--gui', action='store_true', help="Open waves (GTKWave) after run")
    parser.add_argument('--seed', type=int, default=1, help="Random seed")
    
    args = parser.parse_args()

    # Paths
    run_dir = Path(__file__).parent.resolve()
    project_root = run_dir.parent.parent.resolve()
    
    # Change to Run directory
    os.chdir(run_dir)

    # 1. Clean
    if args.clean:
        print("Cleaning...")
        if os.name == 'nt':
            os.system('del /f /q alu_tb.vvp dump.vcd 2>nul')
        else:
            os.system('rm -f alu_tb.vvp dump.vcd')

    # 2. Compile (iverilog)
    # Files: Interface -> DUT -> Top (which includes pkg)
    # Includes: Root directory (for pkg), and UVM (needs -I to UVM src)
    
    # Note: Using a fixed relative path to files from scripts/Run/
    # Project Root is ../../
    
    # We need to find UVM for Icarus. 
    # Check if UVM_HOME is set
    uvm_home = os.environ.get('UVM_HOME')
    uvm_flags = ""
    # Try to guess UVM location if not set
    # 1. Local scripts/uvm-1.2 (downloaded by get_uvm.py)
    local_uvm = (run_dir.parent / "uvm-1.2").resolve()
    print(f"DEBUG: Checking for UVM at: {local_uvm}")
    print(f"DEBUG: Exists? {local_uvm.exists()}")
    
    if not uvm_home and local_uvm.exists():
        uvm_home = str(local_uvm)
        print(f"Using local UVM: {uvm_home}")
        
    # 2. Common Windows path
    elif not uvm_home and os.path.exists("C:/iverilog/vlib/uvm-1.2"):
        uvm_home = "C:/iverilog/vlib/uvm-1.2"
        
    if uvm_home:
        # Standard UVM inclusion for Icarus
        uvm_flags = f"-I \"{uvm_home}/src\" \"{uvm_home}/src/uvm_pkg.sv\""
    else:
        print("WARNING: UVM_HOME not set. Compilation will likely fail if UVM is not built-in.")

    # Source Files
    src_files = [
        "../../interface/alu_if.sv",
        "../../dut/dut.sv",
        "../../tb_top.sv" 
    ]
    
    # Include Directories (Project Root is critical for alu_pkg.sv internal includes)
    inc_dirs = [
        "-I ../../" 
    ]
    
    cmd_compile = (
        f"iverilog -g2012 "
        f"{' '.join(inc_dirs)} "
        f"{uvm_flags} "
        f"-D UVM_NO_DPI " # Common fix for lightweight Icarus UVM usage
        f"-s tb_top "
        f"-o alu_tb.vvp "
        f"{' '.join(src_files)}"
    )
    
    run_command(cmd_compile, "Compile (iverilog)")

    # 3. Simulate (vvp)
    # Pass Testname via plusargs
    cmd_sim = (
        f"vvp -n alu_tb.vvp "
        f"+UVM_TESTNAME={args.test} "
        f"+ntb_random_seed={args.seed}"
    )
    
    run_command(cmd_sim, "Simulate (vvp)")
    
    # 4. GUI
    if args.gui:
        if os.path.exists("dump.vcd"):
            print("Opening GTKWave...")
            os.system("gtkwave dump.vcd")
        else:
            print("No dump.vcd found to view.")

except KeyboardInterrupt:
    print("\nInterrupted.")
    sys.exit(0)
except Exception as e:
    print(f"\nFATAL: {e}")
    sys.exit(1)
