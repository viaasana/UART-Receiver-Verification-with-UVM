class uart_driver extends uvm_driver #(uart_tlm);
  `uvm_component_utils(uart_driver)

  virtual uart_if vif;
  uart_cfg cfg;
  uvm_analysis_port #(uart_tlm) ap;

  function new(string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);

    if (!uvm_config_db#(virtual uart_if)::get(this, "", "UART_VIF", vif))
      `uvm_fatal("NO_VIF", "UART_VIF was not configured")
    
    if (!uvm_config_db#(uart_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("NO_CFG", "uart_cfg was not configured")
  endfunction

  task drive_bit(bit value);
    @(negedge vif.clk);
    vif.rx_data = value;
    repeat (cfg.clks_per_bit) @(posedge vif.clk);
  endtask

  task run_phase(uvm_phase phase);
    uart_tlm expected;

    forever begin
      seq_item_port.get_next_item(req);

      expected = uart_tlm::type_id::create("expected");
      expected.copy(req);
      ap.write(expected);

      drive_bit(1'b0);//start bit
      for (int i = 0; i < 8; i++) begin
        drive_bit(req.data[i]);
      end
      drive_bit(1'b1);//stop bit

      seq_item_port.item_done();
    end
  endtask
endclass