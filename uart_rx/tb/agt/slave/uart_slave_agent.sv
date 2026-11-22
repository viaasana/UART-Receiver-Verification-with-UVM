class uart_slave_agent extends uvm_agent;
    `uvm_component_utils(uart_slave_agent)

    uart_slave_monitor monitor;

    function new(string name="uart_slave_agent", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = uart_slave_monitor::type_id::create("monitor", this);
    endfunction
endclass