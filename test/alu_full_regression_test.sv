
// UVM Full Regression Test
// Runs all sequences with all callbacks enabled.
// Includes: Base -> Stress -> Coverage sequences
// With: Logging, Statistics, Drop, and Tracking callbacks

class alu_full_regression_test extends uvm_test;
    `uvm_component_utils(alu_full_regression_test)

    alu_env env;
    
    // ========================================================================
    // CALLBACK INSTANCES
    // ========================================================================
    
    // Driver callbacks
    alu_driver_log_cb    drv_log_cb;
    alu_drop_tx_cb       drop_cb;
    
    // Monitor callbacks
    alu_stats_cb         stats_cb;
    alu_protocol_check_cb proto_cb;
    
    // Scoreboard callbacks
    alu_op_tracker_cb    op_tracker_cb;
    alu_compare_log_cb   compare_log_cb;

    // Configuration
    int drop_rate = 0;  // Set > 0 to enable random drops

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = alu_env::type_id::create("env", this);
        
        // Create all callback instances
        drv_log_cb     = alu_driver_log_cb::type_id::create("drv_log_cb");
        drop_cb        = alu_drop_tx_cb::type_id::create("drop_cb");
        stats_cb       = alu_stats_cb::type_id::create("stats_cb");
        proto_cb       = alu_protocol_check_cb::type_id::create("proto_cb");
        op_tracker_cb  = alu_op_tracker_cb::type_id::create("op_tracker_cb");
        compare_log_cb = alu_compare_log_cb::type_id::create("compare_log_cb");
        
        // Configure callbacks
        drop_cb.drop_rate = drop_rate;
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Register all callbacks
        
        // Driver callbacks
        uvm_callbacks#(alu_driver, alu_callback_base)::add(env.agent.driver, drv_log_cb);
        if (drop_rate > 0) begin
            uvm_callbacks#(alu_driver, alu_callback_base)::add(env.agent.driver, drop_cb);
        end
        
        // Monitor callbacks
        uvm_callbacks#(alu_monitor, alu_callback_base)::add(env.agent.monitor, stats_cb);
        uvm_callbacks#(alu_monitor, alu_callback_base)::add(env.agent.monitor, proto_cb);
        
        // Scoreboard callbacks
        uvm_callbacks#(alu_scoreboard, alu_callback_base)::add(env.scoreboard, op_tracker_cb);
        uvm_callbacks#(alu_scoreboard, alu_callback_base)::add(env.scoreboard, compare_log_cb);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        alu_regression_sequence reg_seq;

        phase.raise_objection(this);

        // Print header
        $display("");
        $display("################################################################");
        $display("##                                                            ##");
        $display("##              ALU FULL REGRESSION TEST                      ##");
        $display("##                                                            ##");
        $display("################################################################");
        $display("");
        $display("  PHASES:");
        $display("    1. Base Sequence      (50 transactions)");
        $display("    2. Stress Sequence    (200+ transactions)");
        $display("    3. Coverage Sequence  (1000+ transactions)");
        $display("");
        $display("  ACTIVE CALLBACKS:");
        $display("    Driver:");
        $display("      - alu_driver_log_cb    : Transaction logging");
        if (drop_rate > 0)
            $display("      - alu_drop_tx_cb       : Random drops (%0d%%)", drop_rate);
        $display("    Monitor:");
        $display("      - alu_stats_cb         : Operation statistics");
        $display("      - alu_protocol_check_cb: Protocol checking");
        $display("    Scoreboard:");
        $display("      - alu_op_tracker_cb    : Per-operation tracking");
        $display("      - alu_compare_log_cb   : Comparison logging");
        $display("");
        $display("################################################################");
        $display("");

        // Create and run regression sequence
        reg_seq = alu_regression_sequence::type_id::create("reg_seq");
        reg_seq.run_base     = 1;
        reg_seq.run_stress   = 1;
        reg_seq.run_coverage = 1;

        reg_seq.start(env.agent.sequencer);

        // Extended drain time
        #1000ns;

        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        // Print comprehensive statistics
        $display("");
        $display("################################################################");
        $display("##                                                            ##");
        $display("##              FULL REGRESSION RESULTS                       ##");
        $display("##                                                            ##");
        $display("################################################################");
        $display("");
        
        // Drop statistics
        if (drop_rate > 0) begin
            $display("  DROP CALLBACK STATISTICS:");
            $display("    Total Attempted    : %0d", drop_cb.total);
            $display("    Dropped            : %0d", drop_cb.dropped);
            $display("    Actual Drop Rate   : %.1f%%", 
                drop_cb.total > 0 ? real'(drop_cb.dropped)/real'(drop_cb.total)*100 : 0);
            $display("");
        end
        
        // Protocol errors
        $display("  PROTOCOL CHECKER:");
        $display("    Protocol Errors    : %0d", proto_cb.protocol_errors);
        $display("");
        
        // Print detailed statistics from callbacks
        stats_cb.print_stats();
        op_tracker_cb.print_stats();
        compare_log_cb.print_summary();
        
        // Final verdict
        $display("");
        $display("################################################################");
        if (compare_log_cb.fail_count == 0 && proto_cb.protocol_errors == 0) begin
            $display("##          FULL REGRESSION: *** PASSED ***                  ##");
        end else begin
            $display("##          FULL REGRESSION: *** FAILED ***                  ##");
            $display("##            Mismatches: %0d                                 ", compare_log_cb.fail_count);
            $display("##            Protocol Errors: %0d                            ", proto_cb.protocol_errors);
        end
        $display("################################################################");
        $display("");
    endfunction

endclass
