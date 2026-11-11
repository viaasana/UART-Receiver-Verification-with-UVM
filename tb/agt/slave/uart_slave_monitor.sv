class uart_slave_monitor extends uvm_monitor;
    `uvm_component_utils(uart_slave_monitor)

    virtual uart_if vif;
    uvm_analysis_port #(uart_tlm) ap;

    function new(string name="uart_slave_monitor", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "UART_VIF", vif))
            `uvm_fatal("NO_VIF", "UART_VIF was not configured")
    endfunction

    task run_phase(uvm_phase phase);
        uart_tlm actual;

        forever begin
            @(negedge vif.clk);
            if ($isunknown(vif.o_valid))
                `uvm_error("VALID_X", "o_valid contains X/Z")

            if (vif.o_valid == 1'b1) begin
                if ($isunknown(vif.o_data))
                `uvm_error("DATA_X", "o_data contains X/Z")

                actual = uart_tlm::type_id::create("actual");
                actual.data = vif.o_data;
                ap.write(actual);
            end
        end
    endtask
endclass