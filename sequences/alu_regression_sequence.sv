
// UVM Regression Sequence (Virtual Sequence)
// Runs all sequences in order: Base -> Stress -> Coverage -> (Optional) Callback Demo
// Provides comprehensive verification in a single test run.

class alu_regression_sequence extends uvm_sequence #(alu_item);
    `uvm_object_utils(alu_regression_sequence)

    // Sub-sequences
    alu_basesequence      base_seq;
    alu_stress_sequence   stress_seq;
    alu_coverage_sequence cov_seq;

    // Configuration - enable/disable phases
    bit run_base         = 1;
    bit run_stress       = 1;
    bit run_coverage     = 1;
    bit run_callback_demo = 0;  // Extra random phase for callback demo
    
    // Callback demo configuration
    int callback_demo_transactions = 100;

    function new(string name = "alu_regression_sequence");
        super.new(name);
    endfunction

    task body();
        int total_phases = run_base + run_stress + run_coverage + run_callback_demo;
        int current_phase = 0;

        $display("");
        $display("############################################################");
        $display("          STARTING REGRESSION SEQUENCE");
        $display("          Total Phases: %0d", total_phases);
        $display("############################################################");

        // ====================================================================
        // PHASE 1: Base Sequence
        // ====================================================================
        if (run_base) begin
            current_phase++;
            $display("");
            $display("============ PHASE %0d/%0d: BASE SEQUENCE ============", 
                current_phase, total_phases);
            
            base_seq = alu_basesequence::type_id::create("base_seq");
            base_seq.start(m_sequencer, this);
            
            $display("Base Sequence Complete");
        end

        // ====================================================================
        // PHASE 2: Stress Sequence
        // ====================================================================
        if (run_stress) begin
            current_phase++;
            $display("");
            $display("============ PHASE %0d/%0d: STRESS SEQUENCE ============", 
                current_phase, total_phases);
            
            stress_seq = alu_stress_sequence::type_id::create("stress_seq");
            stress_seq.num_transactions = 200;  // Reduced for regression
            stress_seq.start(m_sequencer, this);
            
            $display("Stress Sequence Complete");
        end

        // ====================================================================
        // PHASE 3: Coverage Sequence
        // ====================================================================
        if (run_coverage) begin
            current_phase++;
            $display("");
            $display("============ PHASE %0d/%0d: COVERAGE SEQUENCE ============", 
                current_phase, total_phases);
            
            cov_seq = alu_coverage_sequence::type_id::create("cov_seq");
            cov_seq.start(m_sequencer, this);
            
            $display("Coverage Sequence Complete");
        end

        // ====================================================================
        // PHASE 4: Callback Demo (extra random transactions)
        // ====================================================================
        if (run_callback_demo) begin
            alu_item item;
            current_phase++;
            $display("");
            $display("============ PHASE %0d/%0d: CALLBACK DEMO ============", 
                current_phase, total_phases);
            $display("  Running %0d random transactions for callback demonstration...", 
                callback_demo_transactions);
            
            repeat (callback_demo_transactions) begin
                item = alu_item::type_id::create("item");
                start_item(item);
                if (!item.randomize()) begin
                    `uvm_error("REG_SEQ", "Randomization failed in callback demo phase")
                end
                finish_item(item);
            end
            
            $display("Callback Demo Phase Complete");
        end

        // ====================================================================
        // COMPLETE
        // ====================================================================
        $display("");
        $display("############################################################");
        $display("          REGRESSION SEQUENCE COMPLETE");
        $display("          All %0d phases finished successfully", total_phases);
        $display("############################################################");
        $display("");

    endtask

endclass
