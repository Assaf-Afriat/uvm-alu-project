# UVM ALU Verification - Common Commands Reference

Quick reference guide for running UVM ALU verification tests. All commands should be run from the `scripts/Run` directory.

## Table of Contents
- [Basic Test Execution](#basic-test-execution)
- [Compilation Commands](#compilation-commands)
- [Test Execution with Options](#test-execution-with-options)
- [Code Coverage](#code-coverage)
- [Troubleshooting](#troubleshooting)

---

## Basic Test Execution

### Run Default Test
```bash
cd scripts/Run
python run.py --test alu_test
```

### Run with GUI (For Debugging)
```bash
cd scripts/Run
python run.py --test alu_test --gui
```

---

## Compilation Commands

### Compile Only (No Test Run)
```bash
cd scripts/Run
python run.py --compile-only
```

### Run Test Without Recompiling (Faster)
```bash
cd scripts/Run
python run.py --test alu_test --no-compile
```

### Clean Work Library
```bash
cd scripts/Run
python run.py --clean
```

### Manual Compilation (Using QuestaSim Directly)
```bash
cd scripts/Run
vsim -c -do "source compile.do; quit -f"
```

---

## Test Execution with Options

### Run with Custom Seed
```bash
cd scripts/Run
python run.py --test alu_test --seed 12345
```

### Run with Timeout
```bash
cd scripts/Run
python run.py --test alu_test --timeout 300
```

### Run with Higher Verbosity
```bash
cd scripts/Run
python run.py --test alu_test --verbosity UVM_HIGH
```

### List Available Tests
```bash
cd scripts/Run
python run.py --list
```

---

## Code Coverage

### Run Test with Coverage Collection
```bash
cd scripts/Run
python run.py --test alu_test --coverage
```

### Run Test with Coverage Report Generation
```bash
cd scripts/Run
python run.py --test alu_test --coverage-report
```

### Output Files
- **UCDB Database**: `coverage/<TestName>.ucdb` - Raw coverage data
- **Text Report**: `coverage/<TestName>_coverage.txt` - Summary
- **HTML Report**: `coverage/html/index.html` - Detailed interactive report

### View Coverage Report in Browser
```powershell
# Windows
start coverage/html/index.html
```

### Coverage Types Collected
| Type | Description | Flag |
|------|-------------|------|
| **Statement** | Lines executed | `s` |
| **Branch** | If/else/case branches taken | `b` |
| **Condition** | Boolean sub-expressions | `c` |
| **Expression** | Complex expressions | `e` |
| **FSM** | State machine transitions | `f` |
| **Toggle** | Signal transitions 0→1, 1→0 | `t` |

---

## Common Workflows

### Quick Verification Workflow
```bash
cd scripts/Run

# 1. Clean and compile
python run.py --clean --compile-only

# 2. Run test
python run.py --test alu_test --no-compile
```

### Debug Workflow (With GUI)
```bash
cd scripts/Run

# Compile
python run.py --compile-only

# Run with GUI for debugging
python run.py --test alu_test --gui --no-compile
```

### Coverage Workflow
```bash
cd scripts/Run

# Run with coverage report
python run.py --test alu_test --coverage-report

# View report
start ../../coverage/html/index.html
```

---

## Quick Copy-Paste Commands

```bash
# Quick test run
cd scripts/Run && python run.py --test alu_test

# Compile only
cd scripts/Run && python run.py --compile-only

# Clean everything
cd scripts/Run && python run.py --clean

# Run with GUI
cd scripts/Run && python run.py --test alu_test --gui

# Run with coverage
cd scripts/Run && python run.py --test alu_test --coverage-report

# List tests
cd scripts/Run && python run.py --list

# Show help
cd scripts/Run && python run.py --help
```

---

## Troubleshooting

### QuestaSim Not Found
Make sure QuestaSim is in your PATH or use full path to `vsim`.

### License Errors
If you see "All Verilog licenses are currently in use":
1. Wait - the request is queued automatically
2. Close other QuestaSim instances
3. Kill stuck processes:
   ```powershell
   Get-Process | Where-Object {$_.ProcessName -like "*vsim*"} | Stop-Process -Force
   ```

### Compilation Errors
Check the log file in `logs/<TestName>.log` for details.

### Clean and Retry
```bash
cd scripts/Run
python run.py --clean
python run.py --test alu_test
```

---

## File Locations

- **Test Runner**: `scripts/Run/run.py`
- **Compile Script**: `scripts/Run/compile.do`
- **Elaborate Script**: `scripts/Run/elaborate.do`
- **Testbench Top**: `tb_top.sv`
- **UVM Package**: `alu_pkg.sv`
- **DUT**: `dut/dut.sv`
- **Interface**: `interface/alu_if.sv`
- **Log Files**: `logs/<TestName>.log`
- **Waveforms**: `logs/<TestName>.wlf`
- **Coverage Data**: `coverage/<TestName>.ucdb`
- **Coverage Report**: `coverage/html/index.html`

---

*UVM ALU Verification Project*
