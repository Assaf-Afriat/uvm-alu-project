
// UVM Package
// Includes all verification components.

package alu_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Transaction Item (must be first)
    `include "agent/alu_item.sv"

    // Callback Base (before components that use it)
    `include "callbacks/alu_callback_base.sv"

    // Agent Components
    `include "agent/alu_sequencer.sv"
    `include "agent/alu_driver.sv"
    `include "agent/alu_monitor.sv"
    `include "agent/alu_agent.sv"

    // Environment Components
    `include "scoreboard/alu_scoreboard.sv"
    `include "coverage/alu_coverage.sv"
    `include "env/alu_env.sv"

    // Callback Implementations (after components)
    `include "callbacks/alu_driver_callbacks.sv"
    `include "callbacks/alu_monitor_callbacks.sv"
    `include "callbacks/alu_scoreboard_callbacks.sv"

    // Sequences
    `include "sequences/alu_basesequence.sv"
    `include "sequences/alu_stress_sequence.sv"
    `include "sequences/alu_coverage_sequence.sv"
    `include "sequences/alu_regression_sequence.sv"

    // Tests
    `include "test/alu_test.sv"
    `include "test/alu_stress_test.sv"
    `include "test/alu_coverage_test.sv"
    `include "test/alu_regression_test.sv"
    `include "test/alu_callback_test.sv"
    `include "test/alu_full_regression_test.sv"

endpackage
