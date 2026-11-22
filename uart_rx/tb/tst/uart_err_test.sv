class uart_err_test extends uvm_test;
  `uvm_component_utils(uart_err_test)
  localparam int CLKS_PER_BIT = 87;
  localparam bit [7:0] PAYLOAD = 8'hA5;
  virtual uart_if vif;
  bit in_stop_window;
  int unsigned valid_cycles;
  function new(string name = "uart_err_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "UART_VIF", vif))
      `uvm_fatal("NO_VIF", "Check the UART interface key in top.sv")
  endfunction
  task drive_bit(bit value, int clocks = CLKS_PER_BIT);
    @(negedge vif.clk);
    vif.rx_data = value;
    repeat (clocks) @(posedge vif.clk);
  endtask
  task check_output();
    forever begin
      @(negedge vif.clk);
      if (vif.o_valid === 1'b1) begin
        if (!in_stop_window)
          `uvm_fatal("UNEXPECTED_VALID", "o_valid asserted outside the recovery frame's stop bit")
        valid_cycles++;
        if (valid_cycles > 1)
          `uvm_fatal("VALID_WIDTH", "Recovery frame produced more than one valid cycle")
        if (vif.o_data !== PAYLOAD)
          `uvm_fatal("DATA", $sformatf("Expected %02h, got %02h", PAYLOAD, vif.o_data))
      end else if (vif.o_valid !== 1'b0) begin
        `uvm_fatal("VALID_X", "o_valid contains X/Z")
      end
    end
  endtask
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    fork
      check_output();
    join_none
    drive_bit(1'b1, CLKS_PER_BIT);
    drive_bit(1'b0, 1);
    drive_bit(1'b1, 10 * CLKS_PER_BIT);
    drive_bit(1'b0);
    for (int i = 0; i < 8; i++)
      drive_bit(PAYLOAD[i], CLKS_PER_BIT);
    in_stop_window = 1;
    drive_bit(1'b1);
    in_stop_window = 0;
    repeat (CLKS_PER_BIT) @(posedge vif.clk);
    if (valid_cycles != 1)
      `uvm_fatal("MISSING_VALID", "No valid pulse for the recovery frame")
    `uvm_info("ERR_PASS", "False start rejected and recovery byte A5 received", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
