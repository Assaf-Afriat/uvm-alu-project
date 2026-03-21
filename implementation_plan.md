# Verification approach — 8-bit ALU (UVM)

This document describes **how we thought about** verifying the ALU DUT: constraints of the design, layering of the testbench, and why each piece exists. The work described here is **complete**.

---

## 1. What we set out to prove

We needed confidence that an **8-bit ALU** with:

- separate **request** and **response** valid/ready channels,
- **operation-dependent latency**,
- a **small output FIFO** and realistic **backpressure**,

behaves like a reference model across stimulus, corner cases, and protocol stress. The interesting part is not the arithmetic alone—it is **ordering**, **stalls**, **latency under load**, and **FIFO boundaries**.

---

## 2. DUT contract (reference)

Understanding the interface first drove every checker and sequence.

### Interface signals

| Signal        | Direction | Width | Role |
| ------------- | --------- | ----- | ---- |
| `clk`         | Input     | 1     | System clock |
| `rst_n`       | Input     | 1     | Active-low async reset |
| `req_valid`   | Input     | 1     | Request beat valid |
| `req_ready`   | Output    | 1     | DUT can accept request |
| `req_op`      | Input     | 3     | Opcode |
| `req_op1`     | Input     | 8     | Operand A |
| `req_op2`     | Input     | 8     | Operand B |
| `resp_valid`  | Output    | 1     | Response beat valid |
| `resp_ready`  | Input     | 1     | TB can accept response |
| `resp_result` | Output    | 16  | Result (wider for multiply) |

Canonical RTL: `dut/dut.sv`. Virtual interface: `interface/alu_if.sv`.

### Opcodes and nominal latency

| `req_op` | Op  | Latency (cycles) |
| -------- | --- | ------------------ |
| `000`    | ADD | 2 |
| `001`    | SUB | 2 |
| `010`    | MUL | 4 |
| `011`    | AND | 2 |
| `100`    | XOR | 2 |
| `101`    | SLL | 2 |
| `110`    | SRL | 2 |
| `111`    | DIV | 8 (divide-by-zero defined in DUT as `16'hFFFF`) |

### Handshake intuition

- **Request**: transfer when `req_valid && req_ready` on a clock edge; operands and opcode must be stable while `req_valid` is asserted and until the transfer (same discipline we assert in SVA).
- **Response**: DUT presents results in order through the output path; `resp_ready` low creates **backpressure**, which can eventually stall **new** requests via `req_ready`. That coupling is why we did not verify “math only” in isolation—we had to stress **FIFO + backpressure** together.
- **Observed latency** can exceed the table above if the response side is slow; the scoreboard and reference path were written to track **per-transaction** timing and ordering, not a fixed delay from request to response in all conditions.

### Scenarios we cared about

- Single and burst requests with mixed opcodes.
- Pipeline/FIFO fill and drain.
- Aggressive or random **backpressure** on `resp_ready` (`scripts/Run/run.py` exposes this).
- Reset dropped mid-traffic and clean recovery.

---

## 3. How we layered the testbench

We separated concerns deliberately:

| Concern | Mechanism | Rationale |
| ------- | --------- | --------- |
| Stimulus | UVM sequences + driver | Reusable scenarios; constrained random and directed stress |
| Functional correctness | Scoreboard + reference model in lockstep with monitor | End-to-end “what we meant vs what came back,” including latency ordering |
| Functional coverage | Dedicated subscriber + covergroups | Proof we **visited** opcodes, operands, corners, crosses—not only that one random seed passed |
| Protocol / safety | SVA bound to DUT | Independent witnesses for stability, FIFO bounds, deadlock avoidance |
| Observability / hooks | Callbacks on driver, monitor, scoreboard | Statistics, protocol checks, and logging without forking the core components |

Everything UVM-facing is pulled in through **`alu_pkg.sv`**. The top module **`tb_top.sv`** wires the DUT, interface, UVM, and assertion bind.

---

## 4. Component map (repo layout)

This is the structure we converged on—not a checklist, but the mental model:

- **`alu_pkg.sv`** — package; includes agents, env, tests, sequences, coverage, callbacks.
- **`agent/alu_item.sv`** — transaction: opcode, operands, result field as seen on the bus / in analysis.
- **`agent/alu_driver.sv`** — drives the request channel; respects `req_ready` and reset.
- **`agent/alu_monitor.sv`** — passive observation of request and response beats; analysis ports fan out.
- **`agent/alu_sequencer.sv`**, **`agent/alu_agent.sv`** — standard UVM composition.
- **`sequences/`** — `alu_basesequence`, stress, coverage-oriented traffic, and **`alu_regression_sequence`** (virtual composition for longer flows).
- **`env/alu_env.sv`** — `connect_phase` ties monitor ports to **scoreboard** and **coverage** exports/imps.
- **`scoreboard/alu_scoreboard.sv`** — predicts and compares; central “did the DUT lie?” answer.
- **`coverage/alu_coverage.sv`** — eight covergroups (opcodes, operands, corners, shifts, division, result bands, crosses).
- **`sva/alu_assertions.sv`** — properties for stability, reset, latency bound, FIFO, deadlock; bound from `tb_top.sv`.
- **`callbacks/`** — driver / monitor / scoreboard callback families for drops, stats, compare logging, etc.
- **`test/`** — `alu_test`, stress, coverage, regression, callback demo, **`alu_full_regression_test`** (full stack + callback reporting).

We kept **SVA** and **scoreboard** complementary: assertions catch **illegal protocol or structure**; the scoreboard catches **wrong arithmetic or wrong association** between requests and responses.

---

## 5. Verification execution (what we run)

Regression is driven from **`scripts/Run/run.py`** (QuestaSim / ModelSim on `PATH`). Typical invocations:

```bash
cd scripts/Run
python run.py --test alu_full_regression_test
python run.py --test alu_coverage_test --coverage-report
python run.py --backpressure 50
```

Success means a clean simulator exit, no assertion failures, and (for the full regression test) the printed summary showing **no scoreboard mismatches** and **no protocol errors** from the callback path. Exact banner text lives in `test/alu_full_regression_test.sv`.

---

## 6. Summary

We treated this ALU as a **small system**: handshake, variable latency, FIFO, and backpressure. The testbench mirrors that—**sequences** for intent, **scoreboard** for data correctness, **coverage** for thoroughness, **SVA** for invariants, and **callbacks** for visibility. This plan records that reasoning for future you (or a reviewer) without implying open work items.
