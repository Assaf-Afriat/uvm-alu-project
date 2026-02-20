import os
import sys
import argparse
import subprocess
import time
from pathlib import Path

# --- UVM ALU Project - QuestaSim Run Script ---
# Usage: python run.py --test alu_test
# Run from: scripts/Run directory

def run_command(command, step_name, cwd=None, timeout=None):
    """Runs a shell command and exits if it fails."""
    print(f"\n{'='*60}")
    print(f"  {step_name}")
    print(f"{'='*60}")
    print(f"Command: {command}")
    if cwd:
        print(f"Working Dir: {cwd}")
    print()
    
    start_time = time.time()
    
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            timeout=timeout
        )
        elapsed = time.time() - start_time
        
        if result.returncode != 0:
            print(f"\n[ERROR] Step '{step_name}' failed! (RC={result.returncode})")
            sys.exit(1)
        else:
            print(f"\n[OK] {step_name} completed in {elapsed:.2f}s")
            
    except subprocess.TimeoutExpired:
        print(f"\n[TIMEOUT] Step '{step_name}' exceeded {timeout}s timeout!")
        sys.exit(1)
    except KeyboardInterrupt:
        print(f"\n[INTERRUPTED] Step '{step_name}' was cancelled.")
        raise

def main():
    parser = argparse.ArgumentParser(
        description="UVM ALU Verification - QuestaSim Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python run.py --test alu_test              # Run default test
  python run.py --test alu_test --gui        # Run with GUI
  python run.py --compile-only               # Compile only
  python run.py --test alu_test --no-compile # Skip compilation
  python run.py --test alu_test --seed 12345 # Custom seed
  python run.py --clean                      # Clean work library
  python run.py --list                       # List available tests
        """
    )
    
    parser.add_argument('--test', type=str, default='alu_test',
                        help="UVM Test name (default: alu_test)")
    parser.add_argument('--seed', type=int, default=None,
                        help="Random seed (default: random)")
    parser.add_argument('--gui', action='store_true',
                        help="Run with QuestaSim GUI")
    parser.add_argument('--compile-only', action='store_true',
                        help="Only compile, don't run simulation")
    parser.add_argument('--no-compile', action='store_true',
                        help="Skip compilation (use existing work library)")
    parser.add_argument('--clean', action='store_true',
                        help="Clean work library and logs")
    parser.add_argument('--timeout', type=int, default=300,
                        help="Simulation timeout in seconds (default: 300)")
    parser.add_argument('--coverage', action='store_true',
                        help="Enable code coverage collection")
    parser.add_argument('--coverage-report', action='store_true',
                        help="Generate coverage report after simulation")
    parser.add_argument('--list', action='store_true',
                        help="List available tests")
    parser.add_argument('--verbosity', type=str, default='UVM_MEDIUM',
                        choices=['UVM_NONE', 'UVM_LOW', 'UVM_MEDIUM', 'UVM_HIGH', 'UVM_FULL', 'UVM_DEBUG'],
                        help="UVM verbosity level (default: UVM_MEDIUM)")
    parser.add_argument('--backpressure', type=int, default=30, metavar='PCT',
                        help="Backpressure percentage 0-100 (default: 30)")
    parser.add_argument('--no-backpressure', action='store_true',
                        help="Disable random backpressure")
    
    args = parser.parse_args()
    
    # Paths
    run_dir = Path(__file__).parent.resolve()
    project_root = run_dir.parent.parent.resolve()
    sim_dir = project_root / "sim"
    logs_dir = project_root / "logs"
    coverage_dir = project_root / "coverage"
    
    print(f"\n{'#'*60}")
    print(f"  UVM ALU Verification - QuestaSim Runner")
    print(f"{'#'*60}")
    print(f"Project Root: {project_root}")
    print(f"Run Directory: {run_dir}")
    
    # List tests
    if args.list:
        print("\nAvailable Tests:")
        print("  - alu_test                : Basic test with 50 random transactions (default)")
        print("  - alu_stress_test         : Stress test with corner cases, 500+ transactions")
        print("  - alu_coverage_test       : Coverage-driven test targeting all bins")
        print("  - alu_regression_test     : Regression (Base -> Stress -> Coverage)")
        print("  - alu_callback_test       : Demo test with callbacks")
        print("  - alu_full_regression_test: Full regression with all callbacks enabled")
        print("\nUsage: python run.py --test <test_name>")
        return 0
    
    # Clean
    if args.clean:
        print("\n[CLEAN] Removing work library and logs...")
        import shutil
        dirs_to_clean = [sim_dir, logs_dir, coverage_dir]
        for d in dirs_to_clean:
            if d.exists():
                shutil.rmtree(d)
                print(f"  Removed: {d}")
        print("[CLEAN] Done.")
        if not args.test and not args.compile_only:
            return 0
    
    # Create directories
    sim_dir.mkdir(exist_ok=True)
    logs_dir.mkdir(exist_ok=True)
    if args.coverage or args.coverage_report:
        coverage_dir.mkdir(exist_ok=True)
    
    # Change to project root for compilation
    os.chdir(project_root)
    
    # =========================================================================
    # COMPILE
    # =========================================================================
    if not args.no_compile:
        print("\n" + "="*60)
        print("  COMPILATION PHASE")
        print("="*60)
        
        # Create work library
        run_command("vlib sim/work", "Create Work Library", cwd=project_root)
        run_command("vmap work sim/work", "Map Work Library", cwd=project_root)
        
        # Coverage flags
        coverage_flags = "+cover=bcesft" if (args.coverage or args.coverage_report) else ""
        
        # Compile interface
        run_command(
            f"vlog -sv -work work +incdir+interface interface/alu_if.sv",
            "Compile Interface",
            cwd=project_root
        )
        
        # Compile DUT
        run_command(
            f"vlog -sv -work work {coverage_flags} +incdir+dut dut/dut.sv",
            "Compile DUT",
            cwd=project_root
        )
        
        # Compile SVA Assertions
        run_command(
            f"vlog -sv -work work +incdir+sva sva/alu_assertions.sv",
            "Compile SVA Assertions",
            cwd=project_root
        )
        
        # Compile testbench top (includes alu_pkg.sv which includes all UVM components)
        run_command(
            f"vlog -sv -work work +incdir+. +incdir+agent +incdir+env +incdir+scoreboard +incdir+sequences +incdir+test tb_top.sv",
            "Compile Testbench",
            cwd=project_root
        )
        
        print("\n[OK] Compilation successful!")
    
    if args.compile_only:
        print("\n[DONE] Compile-only mode. Exiting.")
        return 0
    
    # =========================================================================
    # ELABORATE
    # =========================================================================
    print("\n" + "="*60)
    print("  ELABORATION PHASE")
    print("="*60)
    
    coverage_opt = "+cover=bcesft" if (args.coverage or args.coverage_report) else ""
    run_command(
        f"vopt +acc=npr {coverage_opt} -o tb_top_opt work.tb_top",
        "Elaborate Design",
        cwd=project_root
    )
    
    # =========================================================================
    # SIMULATE
    # =========================================================================
    print("\n" + "="*60)
    print("  SIMULATION PHASE")
    print("="*60)
    print(f"Test: {args.test}")
    print(f"Verbosity: {args.verbosity}")
    if args.seed:
        print(f"Seed: {args.seed}")
    
    # Backpressure settings
    bp_en = 0 if args.no_backpressure else 1
    bp_pct = args.backpressure
    print(f"Backpressure: {'OFF' if args.no_backpressure else f'{bp_pct}%'}")
    
    # Build simulation command
    log_file = logs_dir / f"{args.test}.log"
    wlf_file = logs_dir / f"{args.test}.wlf"
    ucdb_file = coverage_dir / f"{args.test}.ucdb"
    
    # Seed handling
    seed_arg = f"-sv_seed {args.seed}" if args.seed else "-sv_seed random"
    
    # Backpressure plusargs
    bp_args = f"+BACKPRESSURE_EN={bp_en} +BACKPRESSURE_PCT={bp_pct}"
    
    # Coverage arguments
    coverage_args = ""
    if args.coverage or args.coverage_report:
        coverage_args = f"-coverage -coverstore {coverage_dir}"
    
    # GUI or batch mode
    if args.gui:
        sim_cmd = (
            f"vsim -gui {coverage_args} {seed_arg} "
            f"+UVM_TESTNAME={args.test} "
            f"+UVM_VERBOSITY={args.verbosity} "
            f"{bp_args} "
            f"-wlf {wlf_file} "
            f"-l {log_file} "
            f"tb_top_opt"
        )
    else:
        # Batch mode with auto-exit
        do_commands = "run -all; quit -f"
        if args.coverage or args.coverage_report:
            do_commands = f"coverage save -onexit {ucdb_file}; run -all; quit -f"
        
        sim_cmd = (
            f"vsim -c {coverage_args} {seed_arg} "
            f"+UVM_TESTNAME={args.test} "
            f"+UVM_VERBOSITY={args.verbosity} "
            f"{bp_args} "
            f"-wlf {wlf_file} "
            f"-l {log_file} "
            f"-do \"{do_commands}\" "
            f"tb_top_opt"
        )
    
    run_command(sim_cmd, f"Simulate {args.test}", cwd=project_root, timeout=args.timeout if not args.gui else None)
    
    # =========================================================================
    # COVERAGE REPORT
    # =========================================================================
    if args.coverage_report:
        print("\n" + "="*60)
        print("  COVERAGE REPORT")
        print("="*60)
        
        report_txt = coverage_dir / f"{args.test}_coverage.txt"
        report_html = coverage_dir / "html"
        
        # Generate text report
        run_command(
            f"vcover report -details -output {report_txt} {ucdb_file}",
            "Generate Text Report",
            cwd=project_root
        )
        
        # Generate HTML report
        run_command(
            f"vcover report -html -htmldir {report_html} {ucdb_file}",
            "Generate HTML Report",
            cwd=project_root
        )
        
        print(f"\nCoverage Reports:")
        print(f"  Text: {report_txt}")
        print(f"  HTML: {report_html}/index.html")
    
    # =========================================================================
    # SUMMARY
    # =========================================================================
    print("\n" + "#"*60)
    print("  SIMULATION COMPLETE")
    print("#"*60)
    print(f"Test: {args.test}")
    print(f"Log: {log_file}")
    print(f"Waveform: {wlf_file}")
    if args.coverage or args.coverage_report:
        print(f"Coverage: {ucdb_file}")
    print()
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n[INTERRUPTED] Simulation cancelled by user.")
        sys.exit(130)
    except Exception as e:
        print(f"\n[FATAL] {e}")
        sys.exit(1)
