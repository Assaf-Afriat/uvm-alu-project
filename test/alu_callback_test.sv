
// UVM Callback Demo Test
// Demonstrates how to use callbacks for logging, statistics, dropping, and tracking.

class alu_callback_test extends uvm_test;
    `uvm_component_utils(alu_callback_test)

    alu_env env;
    
    // Callback instances
    alu_driver_log_cb    drv_log_cb;
    alu_drop_tx_cb       drop_cb;
    alu_stats_cb         stats_cb;
    alu_op_tracker_cb    op_tracker_cb;
    alu_compare_log_cb   compare_log_cb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = alu_env::type_id::create("env", this);
        
        // Create callback instances
        drv_log_cb     = alu_driver_log_cb::type_id::create("drv_log_cb");
        drop_cb        = alu_drop_tx_cb::type_id::create("drop_cb");
        stats_cb       = alu_stats_cb::type_id::create("stats_cb");
        op_tracker_cb  = alu_op_tracker_cb::type_id::create("op_tracker_cb");
        compare_log_cb = alu_compare_log_cb::type_id::create("compare_log_cb");
        
        // Configure drop callback - 10% drop rate for demo
        drop_cb.drop_rate = 10;
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Register callbacks with components
        // Driver callbacks
        uvm_callbacks#(alu_driver, alu_callback_base)::add(env.agent.driver, drv_log_cb);
        uvm_callbacks#(alu_driver, alu_callback_base)::add(env.agent.driver, drop_cb);
        
        // Monitor callbacks
        uvm_callbacks#(alu_monitor, alu_callback_base)::add(env.agent.monitor, stats_cb);
        
        // Scoreboard callbacks
        uvm_callbacks#(alu_scoreboard, alu_callback_base)::add(env.scoreboard, op_tracker_cb);
        uvm_callbacks#(alu_scoreboard, alu_callback_base)::add(env.scoreboard, compare_log_cb);
        
        `uvm_info("CB_TEST", "All callbacks registered successfully", UVM_LOW)
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        alu_basesequence seq;

        phase.raise_objection(this);

        $display("");
        $display("########################################################");
        $display("              CALLBACK DEMO TEST                        ");
        $display("########################################################");
        $display("  Active Callbacks:");
        $display("    Driver:");
        $display("      - alu_driver_log_cb  : Logs all transactions");
        $display("      - alu_drop_tx_cb     : Drops %0d%% of transactions", drop_cb.drop_rate);
        $display("    Monitor:");
        $display("      - alu_stats_cb       : Tracks operation statistics");
        $display("    Scoreboard:");
        $display("      - alu_op_tracker_cb  : Tracks pass/fail per operation");
        $display("      - alu_compare_log_cb : Logs comparison results");
        $display("########################################################");
        $display("");

        seq = alu_basesequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        // Drain time
        #500ns;

        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        // Print callback statistics
        $display("");
        $display("########################################################");
        $display("              CALLBACK STATISTICS                       ");
        $display("########################################################");
        $display("");
        $display("  DROP CALLBACK:");
        $display("    Total Transactions : %0d", drop_cb.total);
        $display("    Dropped            : %0d", drop_cb.dropped);
        $display("    Drop Rate          : %.1f%%", 
            drop_cb.total > 0 ? real'(drop_cb.dropped)/real'(drop_cb.total)*100 : 0);
        $display("");
        
        stats_cb.print_stats();
        op_tracker_cb.print_stats();
        compare_log_cb.print_summary();
    endfunction

endclass
