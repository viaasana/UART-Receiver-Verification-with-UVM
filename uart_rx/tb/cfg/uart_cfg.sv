class uart_cfg extends uvm_object;
  int unsigned clks_per_bit = 87;
  int unsigned num_frames = 32;

  `uvm_object_utils(uart_cfg)

  function new(string name = "uart_cfg");
    super.new(name);
  endfunction
endclass