
// UVM Stress Test
// Runs stress sequence for high-volume testing.

class alu_stress_test extends uvm_test;
    `uvm_component_utils(alu_stress_test)

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
        alu_stress_sequence seq;

        phase.raise_objection(this);

        seq = alu_stress_sequence::type_id::create("stress_seq");
        seq.num_transactions = 500;

        `uvm_info("STRESS_TEST", "========================================", UVM_LOW)
        `uvm_info("STRESS_TEST", "       STARTING STRESS TEST             ", UVM_LOW)
        `uvm_info("STRESS_TEST", "========================================", UVM_LOW)

        seq.start(env.agent.sequencer);

        `uvm_info("STRESS_TEST", "========================================", UVM_LOW)
        `uvm_info("STRESS_TEST", "       STRESS TEST COMPLETE             ", UVM_LOW)
        `uvm_info("STRESS_TEST", "========================================", UVM_LOW)

        // Extended drain time for stress test
        #500ns;

        phase.drop_objection(this);
    endtask

endclass
