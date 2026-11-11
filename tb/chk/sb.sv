class sb extends uvm_scoreboard;
    `uvm_component_utils(sb)

    uvm_tlm_analysis_fifo #(uart_tlm) expected_fifo;
    uvm_tlm_analysis_fifo #(uart_tlm) actual_fifo;

    uart_cfg cfg;

    int unsigned compared;
    int unsigned mismatches;

    function new(string name="sb", uvm_component parent=null);
        super.new(name, parent);
        compared = 0;
        mismatches = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        expected_fifo = new("expected_fifo", this);
        actual_fifo = new("actual_fifo", this);

        if(!uvm_config_db#(uart_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("NO_CFG", "uart_cfg was not configured in scoreboard")
    endfunction

    task run_phase(uvm_phase phase);
        uart_tlm expected;
        uart_tlm actual;

        forever begin
            expected_fifo.get(expected);
            actual_fifo.get(actual);

            compared ++;
            if(actual.data !== expected.data) begin
                mismatches ++;
                `uvm_error("UART_DATA", $sformatf("expected=%02h actual=%02h", expected.data, actual.data))
            end
        end
    endtask

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);

        if(compared !== cfg.num_frames)
            `uvm_error("SB_COUNT", $sformatf("Compared frames (%0d) does not match expected (%0d)", compared, cfg.num_frames))
        if(mismatches !== 0)
            `uvm_error("SB_MISMATCH", $sformatf("Found %0d mismatched frames", mismatches))

        if(!expected_fifo.is_empty())
            `uvm_error("SB_LEFTOVER", "expected_fifo is not empty at end of simulation")
        if(!actual_fifo.is_empty())
            `uvm_error("SB_LEFTOVER", "actual_fifo is not empty at end of simulation")

        if(compared == cfg.num_frames && mismatches == 0)
            `uvm_info("SB_PASS", $sformatf("Successfully compared %0d frames with no errors", compared), UVM_NONE)
    endfunction

endclass