# ALU UVM Verification Project

A complete, production-quality **UVM verification environment** for an 8-bit ALU with variable latency, output FIFO, and backpressure support.

---

## ▶ Live Project Demo

🔗 **Interactive HTML demo:** https://assaf-afriat.github.io/uvm-alu-project/docs/project_demo.html

---

## 🎯 Project Overview

This project demonstrates industry-standard verification methodologies including:

- ✅ **Complete UVM Environment** - Agent, Scoreboard, Coverage, Sequences
- ✅ **11 SVA Assertions** - Protocol, Reset, Latency, FIFO integrity checks
- ✅ **8 Covergroups** - Comprehensive functional coverage with cross coverage
- ✅ **10 Callbacks** - Extensible hooks for Driver, Monitor, Scoreboard
- ✅ **6 Test Types** - Sanity, Stress, Coverage, Regression, Callback demo
- ✅ **Backpressure Testing** - Random flow control stress testing

## 🔧 DUT Specifications

The Design Under Test is an **8-bit ALU** with the following features:

| Feature | Description |
|---------|-------------|
| **Operations** | ADD, SUB, MUL, AND, XOR, SLL, SRL, DIV |
| **Operands** | 8-bit inputs (op1, op2) |
| **Result** | 16-bit output |
| **Interface** | Valid/Ready handshaking |
| **Latency** | Variable (2-8 cycles depending on operation) |
| **Output FIFO** | 4-entry buffer with backpressure support |

### Operation Latencies

| Operation | Opcode | Latency |
|-----------|--------|---------|
| ADD | `000` | 2 cycles |
| SUB | `001` | 2 cycles |
| MUL | `010` | 4 cycles |
| AND | `011` | 2 cycles |
| XOR | `100` | 2 cycles |
| SLL | `101` | 2 cycles |
| SRL | `110` | 2 cycles |
| DIV | `111` | 8 cycles |

## 📁 Project Structure

```
uvm-alu-project/
├── dut/
│   └── dut.sv                      # ALU Design Under Test
├── agent/
│   ├── alu_item.sv                 # Transaction class
│   ├── alu_driver.sv               # Driver with callback hooks
│   ├── alu_monitor.sv              # Monitor with callback hooks
│   ├── alu_sequencer.sv            # Sequencer
│   └── alu_agent.sv                # Agent wrapper
├── scoreboard/
│   └── alu_scoreboard.sv           # Reference model + comparison
├── coverage/
│   └── alu_coverage.sv             # 8 covergroups
├── sequences/
│   ├── alu_basesequence.sv         # Random sequence
│   ├── alu_stress_sequence.sv      # Stress sequence
│   ├── alu_coverage_sequence.sv    # Coverage-driven sequence
│   └── alu_regression_sequence.sv  # Virtual sequence
├── callbacks/
│   ├── alu_callback_base.sv        # Base callback class
│   ├── alu_driver_callbacks.sv     # 4 driver callbacks
│   ├── alu_monitor_callbacks.sv    # 3 monitor callbacks
│   └── alu_scoreboard_callbacks.sv # 4 scoreboard callbacks
├── sva/
│   └── alu_assertions.sv           # 11 SVA assertions
├── env/
│   └── alu_env.sv                  # Environment
├── test/
│   ├── alu_test.sv                 # Basic test
│   ├── alu_stress_test.sv          # Stress test
│   ├── alu_coverage_test.sv        # Coverage test
│   ├── alu_regression_test.sv      # Regression test
│   ├── alu_callback_test.sv        # Callback demo test
│   └── alu_full_regression_test.sv # Full regression
├── scripts/Run/
│   ├── run.py                      # QuestaSim runner
│   ├── compile.do                  # Compile script
│   └── elaborate.do                # Elaborate script
├── alu_if.sv                       # Interface
├── alu_pkg.sv                      # Package
├── tb_top.sv                       # Testbench top
└── docs/
    └── project_demo.html           # Interactive documentation
```

## 🚀 Quick Start

### Prerequisites

- QuestaSim (or ModelSim)
- Python 3.x
- UVM 1.2

### Running Tests

Navigate to the scripts directory:

```bash
cd scripts/Run
```

#### Basic Commands

```bash
# Run default test (alu_test)
python run.py

# Run specific test
python run.py --test alu_stress_test

# Run full regression with all callbacks
python run.py --test alu_full_regression_test

# Run with GUI
python run.py --gui

# Generate coverage report
python run.py --test alu_coverage_test --coverage-report

# Enable backpressure (30%)
python run.py --backpressure 30

# Run with specific seed
python run.py --seed 12345

# List available tests
python run.py --list

# Clean simulation artifacts
python run.py --clean
```

## 🧪 Test Suite

| Test | Description | Transactions |
|------|-------------|--------------|
| `alu_test` | Basic random test | 50 |
| `alu_stress_test` | Corner cases, back-to-back ops | 500+ |
| `alu_coverage_test` | Coverage-driven targeting | 1000+ |
| `alu_regression_test` | Base + Stress + Coverage | 1500+ |
| `alu_callback_test` | Callback demonstration | 50 |
| `alu_full_regression_test` | All sequences + all callbacks | 1500+ |

## ✅ SVA Assertions

| Category | Assertions |
|----------|------------|
| **Protocol** | `p_req_valid_stable`, `p_req_data_stable`, `p_resp_valid_stable`, `p_resp_data_stable` |
| **Reset** | `p_reset_req_ready`, `p_reset_resp_valid` |
| **Latency** | `p_max_latency`, `p_no_req_deadlock`, `p_no_resp_deadlock` |
| **FIFO** | `p_no_overflow`, `p_no_underflow` |

## 📊 Coverage

| Covergroup | Description | Bins |
|------------|-------------|------|
| `cg_opcode` | All 8 ALU operations | 8 |
| `cg_operand_a` | Operand A value ranges | 65+ |
| `cg_operand_b` | Operand B value ranges | 65+ |
| `cg_corner_cases` | Corner values with ops cross | Cross |
| `cg_shift` | Shift amounts (0-7) x SLL/SRL | 16 |
| `cg_division` | Dividend/Divisor combinations | 25 |
| `cg_result` | Result value ranges | 50 |
| `cg_full_cross` | 8 ops x 3 ranges x 3 ranges | 72 |

## 🔗 Callbacks

### Driver Callbacks
- `alu_driver_log_cb` - Transaction logging
- `alu_error_inject_cb` - Data corruption for error testing
- `alu_delay_inject_cb` - Random delay injection
- `alu_drop_tx_cb` - Transaction dropping by percentage

### Monitor Callbacks
- `alu_stats_cb` - Operation statistics tracking
- `alu_protocol_check_cb` - Real-time protocol validation
- `alu_filter_cb` - Operation filtering

### Scoreboard Callbacks
- `alu_compare_log_cb` - Comparison result logging
- `alu_error_detect_cb` - Pattern-based error detection
- `alu_result_modifier_cb` - Expected result modification
- `alu_op_tracker_cb` - Per-operation pass/fail tracking

## 🚦 Backpressure Testing

The testbench supports random backpressure generation on `resp_ready`:

```bash
# Enable 50% backpressure
python run.py --backpressure 50
```

| Percentage | Effect |
|------------|--------|
| 0% | No backpressure (resp_ready always high) |
| 30% | Light backpressure |
| 50% | Medium backpressure |
| 70%+ | Heavy backpressure (stress test) |

## 📈 Expected Results

After running `alu_full_regression_test`:

```
################################################################
##          FULL REGRESSION: *** PASSED ***                   ##
################################################################

UVM_ERROR    : 0
SVA Violations: 0
Mismatches   : 0
```

## 🛠️ Skills Demonstrated

- **UVM Methodology** - Complete verification environment with factory pattern
- **SystemVerilog** - Classes, interfaces, assertions, covergroups
- **Coverage-Driven Verification** - Targeted stimulus generation
- **Constrained Random Testing** - Weighted distributions
- **Protocol Verification** - Valid/Ready handshaking
- **Callback Mechanism** - Extensible verification hooks
- **Virtual Sequences** - Multi-sequence orchestration
- **Regression Testing** - Automated test suite

---

## 👤 Author

**Assaf Afriat**  
February 2026

---

## 📄 License

This project is available for educational and portfolio purposes.
