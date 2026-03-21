# 8-bit ALU — UVM verification

SystemVerilog **ALU DUT** with valid/ready request and response, **variable execution latency**, a **4-deep output FIFO**, and **backpressure** on the response path. The repo includes a full **UVM** environment (agent, scoreboard reference model, eight covergroups), **SVA** in `sva/alu_assertions.sv`, **callbacks** on driver, monitor, and scoreboard, plus **Python** drivers for QuestaSim under `scripts/Run/`.

**Live overview:** [project demo (HTML)](https://assaf-afriat.github.io/uvm-alu-project/docs/project_demo.html) — or open [`docs/project_demo.html`](docs/project_demo.html) locally.

| | |
|--|--|
| **DUT** | `dut/dut.sv` (`alu_dut` + `fifo_4_deep`) |
| **Verification** | UVM (`alu_env`, sequences, scoreboard, coverage) |
| **Assertions** | SVA (`sva/alu_assertions.sv`) |
| **Simulator** | QuestaSim / ModelSim |
| **Automation** | Python 3 (`scripts/Run/run.py`) |

---

## Design summary

| Item | Detail |
|------|--------|
| **Operations** | ADD, SUB, MUL, AND, XOR, SLL, SRL, DIV (`req_op` 3 bits) |
| **Operands** | `req_op1`, `req_op2` (8 bits) |
| **Result** | `resp_result` (16 bits) on response interface |
| **Handshake** | Request: `req_valid` / `req_ready`; response: `resp_valid` / `resp_ready` |
| **Latency** | 2 cycles (most ops), 4 (MUL), 8 (DIV) — see table below |
| **FIFO** | 4-entry output queue; `resp_ready` can stall (backpressure) |

### Operation latencies

| Op | `req_op` | Latency |
|----|----------|---------|
| ADD | `000` | 2 cycles |
| SUB | `001` | 2 cycles |
| MUL | `010` | 4 cycles |
| AND | `011` | 2 cycles |
| XOR | `100` | 2 cycles |
| SLL | `101` | 2 cycles |
| SRL | `110` | 2 cycles |
| DIV | `111` | 8 cycles (divide-by-zero → `16'hFFFF` in DUT) |

Canonical interface and behavior: **`dut/dut.sv`**, **`interface/alu_if.sv`**.

---

## Verification snapshot

- **UVM** — `alu_agent` (driver, sequencer, monitor), `alu_scoreboard`, `alu_coverage`; monitor **req** and **resp** analysis ports fan out to scoreboard and coverage (`env/alu_env.sv`).
- **SVA** — 11 properties (protocol stability, reset, latency bounds, FIFO no overflow/underflow, deadlock avoidance) — names and groupings in [`docs/project_demo.html`](docs/project_demo.html) / demo **Outcomes** section.
- **Coverage** — 8 covergroups (opcodes, operands, corners, shifts, division, result bands, crosses) — see demo or `coverage/alu_coverage.sv`.
- **Callbacks** — 11 concrete callback classes (4 driver, 3 monitor, 4 scoreboard — see `callbacks/`).
- **Tests** — six test variants (basic, stress, coverage, regression, callback demo, full regression); transaction counts are test-dependent (see table below).

---

## Test suite

| Test | Role | Transactions (typical, from comments/docs) |
|------|------|------------------------------------------|
| `alu_test` | Basic random | 50 |
| `alu_stress_test` | Corners, back-to-back | 500+ |
| `alu_coverage_test` | Coverage-oriented | 1000+ |
| `alu_regression_test` | Base + stress + coverage flow | 1500+ |
| `alu_callback_test` | Callback demo | 50 |
| `alu_full_regression_test` | All sequences + callbacks | 1500+ |

```bash
cd scripts/Run
python run.py --list
python run.py --test alu_full_regression_test
python run.py --test alu_coverage_test --coverage-report
python run.py --backpressure 50
python run.py --clean
```

**Needs:** QuestaSim or ModelSim on `PATH`, Python 3.x. UVM is supplied by the tool flow (see `scripts/Run/compile.do`).

---

## Repository layout

```
uvm-alu-project/
├── dut/dut.sv
├── interface/alu_if.sv
├── alu_pkg.sv
├── tb_top.sv
├── agent/
├── scoreboard/
├── coverage/
├── sequences/
├── callbacks/
├── sva/
├── env/
├── test/
├── scripts/Run/          # run.py, *.do
├── docs/
│   └── project_demo.html
├── implementation_plan.md
└── task_list.md
```

---

## Documentation

| Path | Content |
|------|---------|
| [`docs/project_demo.html`](docs/project_demo.html) | Spec → plan → outcomes demo (light/dark) |
| [`implementation_plan.md`](implementation_plan.md) | Build / verification plan notes |
| [`task_list.md`](task_list.md) | Task tracking |
| [`scripts/commands.md`](scripts/commands.md) | Extra command notes |

---

## Stack

- SystemVerilog (RTL + UVM testbench)
- UVM (tool-provided library)
- SVA
- QuestaSim / ModelSim
- Python 3

---

## Author

Assaf Afriat

---

## License

Educational and portfolio use.
