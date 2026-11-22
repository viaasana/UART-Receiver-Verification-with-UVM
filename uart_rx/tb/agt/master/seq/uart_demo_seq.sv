class uart_demo_seq extends uvm_sequence #(uart_tlm);
    `uvm_object_utils(uart_demo_seq)

    function new(string name = "uart_demo_seq");
        super.new(name);
    endfunction

    task body();
        uart_tlm req;

        bit [7:0] derected_bytes [] = '{8'h00, 8'hff, 8'h55, 8'haa, 8'h01, 8'h80};

        //send derected byte
        foreach (derected_bytes[i]) begin
            req = uart_tlm::type_id::create("req");
            start_item(req);
            if(!req.randomize())
                `uvm_fatal("RAND", "UART transaction randomization failed")

            req.data = derected_bytes[i];
            finish_item(req);
        end

        //send random byte 26 time, 26 + 6(derected bytes) = 32 frame
        for(int i=0; i<26; i++) begin
            req = uart_tlm::type_id::create("req");
            start_item(req);
            if(!req.randomize())
                `uvm_fatal("RAND", "UART transaction randomization failed")
            finish_item(req);
        end
    endtask

endclass