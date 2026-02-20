
// UVM Coverage Test
// Runs coverage-driven sequence to achieve maximum functional coverage.

class alu_coverage_test extends uvm_test;
    `uvm_component_utils(alu_coverage_test)

    alu_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = alu_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        alu_coverage_sequence seq;

        phase.raise_objection(this);

        seq = alu_coverage_sequence::type_id::create("cov_seq");

        `uvm_info("COV_TEST", "========================================", UVM_LOW)
        `uvm_info("COV_TEST", "    STARTING COVERAGE-DRIVEN TEST      ", UVM_LOW)
        `uvm_info("COV_TEST", "========================================", UVM_LOW)

        seq.start(env.agent.sequencer);

        `uvm_info("COV_TEST", "========================================", UVM_LOW)
        `uvm_info("COV_TEST", "    COVERAGE TEST COMPLETE             ", UVM_LOW)
        `uvm_info("COV_TEST", "========================================", UVM_LOW)

        // Drain time for pending responses
        #500ns;

        phase.drop_objection(this);
    endtask

endclass
