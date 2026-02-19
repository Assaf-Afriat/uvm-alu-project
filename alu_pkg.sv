
// UVM Package
// Includes all verification components.

package alu_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Agent Components
    `include "agent/alu_item.sv"
    `include "agent/alu_sequencer.sv"
    `include "agent/alu_driver.sv"
    `include "agent/alu_monitor.sv"
    `include "agent/alu_agent.sv"

    // Environment Components
    `include "scoreboard/alu_scoreboard.sv"
    `include "env/alu_env.sv"

    // Sequences (User library)
    `include "sequences/alu_basesequence.sv"

    // Test (Optional to include in package, or separate)
    // Often tests are in a separate package or just top level.
    // Let's include it here for simplicity as per user request.
    `include "test/alu_test.sv"

endpackage
