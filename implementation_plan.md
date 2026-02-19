# Implementation Plan - Simple ALU UVM Verification

## Goal Description
Create a simple ALU (Arithmetic Logic Unit) DUT with a request/response handshake interface and build a complete UVM verification environment to verify its correctness.

## Proposed Changes

### DUT: Pipelined ALU with Handshake
A pipelined ALU module `alu_dut` that supports arithmetic and logic operations with varying latencies. It uses a Valid/Ready handshake protocol for both input (request) and output (response) interfaces.

#### Interface Signals
| Signal Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | System Clock |
| `rst_n` | Input | 1 | Active-low Asynchronous Reset |
| `req_valid` | Input | 1 | Request Valid: Indicates valid data on inputs. |
| `req_ready` | Output | 1 | Request Ready: DUT is ready to accept new request. |
| `req_op` | Input | 3 | Operation Code (see below). |
| `req_op1` | Input | 8 | Operand 1. |
| `req_op2` | Input | 8 | Operand 2. |
| `resp_valid` | Output | 1 | Response Valid: Indicates valid result on output. |
| `resp_ready` | Input | 1 | Response Ready: Testbench is ready to accept result. |
| `resp_result` | Output | 16 | Result of the operation. |

#### Instruction Set & Latency
| Opcode | Mnemonic | Description | Latency (Cycles) |
| :--- | :--- | :--- | :--- |
| `000` | ADD | A + B | 2 |
| `001` | SUB | A - B | 2 |
| `010` | MUL | A * B | 4 |
| `011` | AND | A & B | 2 |
| `100` | XOR | A ^ B | 2 |
| `101` | SLL | A << B[2:0] | 2 |
| `110` | SRL | A >> B[2:0] | 2 |
| `111` | DIV | A / B | 8 |

#### Handshake Protocol
- **Request Channel**: The master (driver) asserts `req_valid` when data is stable. The slave (DUT) asserts `req_ready` when it can accept data. Transfer occurs on `clk` rising edge when both are high.
- **Response Channel**: The slave (DUT) shifts the result into an output buffer/FIFO. It asserts `resp_valid` when data is available. The master (monitor/driver) asserts `resp_ready` to consume it.
- **Backpressure**:
    - If the internal pipeline stages or output buffer are full, `req_ready` will go low, stalling the input.
    - If the testbench (TB) does not assert `resp_ready`, the DUT holds `resp_valid` and the data until the TB is ready. If the output buffer fills up, backpressure propagates to the input, deasserting `req_ready`.
    - **Note on Latency**: The logical latency is fixed per operation type, but actual observed latency may increase if the output is backpressured.

#### Uses (Scenarios)
- **Normal Operation**: Single beat requests with defined latency.
- **Pipeline Fill**: Burst of requests filling the pipeline.
- **Backpressure Test**: TB stops accepting results (`resp_ready=0`) to force DUT stall.
- **Reset Recovery**: Applying reset during active transactions.


### UVM Architecture

#### [NEW] [alu_pkg.sv](file:///c:/Design/uvm_alu/alu_pkg.sv)
Package containing all UVM classes.

#### [NEW] [alu_item.sv](file:///c:/Design/uvm_alu/alu_item.sv)
Transaction object extending `uvm_sequence_item`.
Fields: `cmd`, `op1`, `op2`, `result`.

#### [NEW] [alu_sequence.sv](file:///c:/Design/uvm_alu/alu_sequence.sv)
Basic sequences: `alu_base_sequence`, `alu_random_sequence`.

#### [NEW] [alu_driver.sv](file:///c:/Design/uvm_alu/alu_driver.sv)
Driving logic:
- Reset handling.
- Drive `req_valid`, `cmd`, `op1`, `op2`.
- Wait for `req_ready`.

#### [NEW] [alu_monitor.sv](file:///c:/Design/uvm_alu/alu_monitor.sv)
Passive monitor:
- Observes the interface.
- Collects requests and responses.
- Broadcasts to analysis port.

#### [NEW] [alu_agent.sv](file:///c:/Design/uvm_alu/alu_agent.sv)
Container for driver, sequencer, and monitor.

#### [NEW] [alu_scoreboard.sv](file:///c:/Design/uvm_alu/alu_scoreboard.sv)
- Compares expected result (computed in TLM) vs observed result from DUT.

#### [NEW] [alu_env.sv](file:///c:/Design/uvm_alu/alu_env.sv)
- Instantiates `alu_agent` and `alu_scoreboard`.

#### [NEW] [alu_test.sv](file:///c:/Design/uvm_alu/alu_test.sv)
- Base test and random test.

#### [NEW] [tb_top.sv](file:///c:/Design/uvm_alu/tb_top.sv)
- Top-level testbench module instantiating DUT and Interface.

## Verification Plan
### Automated Tests
- Run `alu_random_test` which generates 100 random transactions.
- Check log for UVM_ERROR or UVM_FATAL.
- Check scoreboard matches.
