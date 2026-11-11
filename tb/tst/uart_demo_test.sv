class uart_demo_test extends uvm_test;

    `uvm_component_utils(uart_demo_test);

    uart_env env;
    uart_cfg cfg;

    function new(string name="uart_demo_test", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = uart_cfg::type_id::create("cfg");
        cfg.num_frames = 32;
        cfg.clks_per_bit = 87;

        uvm_config_db#(uart_cfg)::set(this, "*", "cfg", cfg);

        env = uart_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
        uart_demo_seq seq;
        seq = uart_demo_seq::type_id::create("seq");

        uvm_top.set_timeout(10ms, 0);

        phase.raise_objection(this);

        #1000;

        `uvm_info("TEST", "Starting sequence...", UVM_NONE)
        seq.start(env.master.sequencer);
        `uvm_info("TEST", "Sequence finished sending all frames.", UVM_NONE)

        wait (env.scoreboard.compared == cfg.num_frames);

        #10000;

        phase.drop_objection(this);
        `uvm_info("TEST", "Test finished successfully.", UVM_NONE)
    endtask

endclass