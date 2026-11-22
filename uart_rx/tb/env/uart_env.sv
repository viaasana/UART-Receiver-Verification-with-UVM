class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent master;
    uart_slave_agent slave;
    sb scoreboard;

    function new(string name="uart_env", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        master = uart_agent::type_id::create("master", this);
        slave = uart_slave_agent::type_id::create("slave", this);
        scoreboard = sb::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        master.driver.ap.connect(scoreboard.expected_fifo.analysis_export);

        slave.monitor.ap.connect(scoreboard.actual_fifo.analysis_export);
    endfunction


endclass