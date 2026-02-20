
// UVM Regression Test
// Runs all sequences: Base -> Stress -> Coverage
// Use this for full regression testing.

class alu_regression_test extends uvm_test;
    `uvm_component_utils(alu_regression_test)

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
        alu_regression_sequence seq;

        phase.raise_objection(this);

        `uvm_info("REG_TEST", "", UVM_LOW)
        `uvm_info("REG_TEST", "################################################################", UVM_LOW)
        `uvm_info("REG_TEST", "##                                                            ##", UVM_LOW)
        `uvm_info("REG_TEST", "##              ALU FULL REGRESSION TEST                      ##", UVM_LOW)
        `uvm_info("REG_TEST", "##                                                            ##", UVM_LOW)
        `uvm_info("REG_TEST", "##  Phase 1: Base Sequence      (50 transactions)             ##", UVM_LOW)
        `uvm_info("REG_TEST", "##  Phase 2: Stress Sequence    (200+ transactions)           ##", UVM_LOW)
        `uvm_info("REG_TEST", "##  Phase 3: Coverage Sequence  (1000+ transactions)          ##", UVM_LOW)
        `uvm_info("REG_TEST", "##                                                            ##", UVM_LOW)
        `uvm_info("REG_TEST", "################################################################", UVM_LOW)
        `uvm_info("REG_TEST", "", UVM_LOW)

        seq = alu_regression_sequence::type_id::create("reg_seq");
        
        // Configure which phases to run (all enabled by default)
        seq.run_base     = 1;
        seq.run_stress   = 1;
        seq.run_coverage = 1;

        seq.start(env.agent.sequencer);

        `uvm_info("REG_TEST", "", UVM_LOW)
        `uvm_info("REG_TEST", "################################################################", UVM_LOW)
        `uvm_info("REG_TEST", "##              REGRESSION TEST COMPLETE                      ##", UVM_LOW)
        `uvm_info("REG_TEST", "################################################################", UVM_LOW)
        `uvm_info("REG_TEST", "", UVM_LOW)

        // Extended drain time for all pending responses
        #1000ns;

        phase.drop_objection(this);
    endtask

endclass
