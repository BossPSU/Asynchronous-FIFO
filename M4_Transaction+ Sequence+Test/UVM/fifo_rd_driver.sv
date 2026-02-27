// ============================================================
// fifo_rd_driver.sv  –  Read-Domain UVM Driver
// ============================================================
// Drives r_ready on the read clock domain.
// For every fifo_rd_item received, asserts r_ready for one
// cycle to pop a word from the FIFO (if r_valid is high).
// ============================================================

class fifo_rd_driver extends uvm_driver #(fifo_rd_item);

    	`uvm_component_utils(fifo_rd_driver)

    	virtual fifo_if vif;

    	int unsigned txn_count;

    	function new(string name = "fifo_rd_driver", uvm_component parent = null);
        	super.new(name, parent);
        	txn_count = 0;
    	endfunction

    	// ----------------------------------------------------------
    	// build_phase
    	// ----------------------------------------------------------
    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);
        	if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif)) begin
            		`uvm_fatal("CFG_ERR","fifo_rd_driver: cannot get fifo_vif from config_db")
        	end
        	`uvm_info(get_type_name(), "build_phase complete", UVM_HIGH)
    	endfunction

    	// ----------------------------------------------------------
    	// run_phase
    	// ----------------------------------------------------------
    	task run_phase(uvm_phase phase);
        	vif.rd_cb.r_ready <= 1'b0;

        	// Wait for read-domain reset
        	wait (vif.rrst === 1'b0);
        	@(vif.rd_cb);

        	`uvm_info(get_type_name(), "Read driver: reset released, starting", UVM_MEDIUM)

        	forever begin
            		fifo_rd_item tr;
            		seq_item_port.get_next_item(tr);

            		drive_item(tr);

            		seq_item_port.item_done();
            		txn_count++;

           		 `uvm_info("RD_DRV",$sformatf("[%0t] Read request sent  total_txn=%0d", $time, txn_count),UVM_MEDIUM)
        	end
    	endtask

    	// ----------------------------------------------------------
    	// drive_item: wait for valid then pulse r_ready
    	// ----------------------------------------------------------
    	task drive_item(fifo_rd_item tr);
        	// Wait until FIFO has data
        	forever begin
            		@(vif.rd_cb);
            		if (vif.rd_cb.r_valid) break;
            		`uvm_info("RD_DRV",$sformatf("[%0t] Stall – FIFO empty, waiting...", $time),UVM_HIGH)
        	end

        	// Pulse ready
        	vif.rd_cb.r_ready <= 1'b1;
        	@(vif.rd_cb);
        	vif.rd_cb.r_ready <= 1'b0;
    	endtask

    	// ----------------------------------------------------------
    	// report_phase
    	// ----------------------------------------------------------
    	function void report_phase(uvm_phase phase);
        	`uvm_info(get_type_name(),$sformatf("Read driver finished – transactions driven: %0d", txn_count),UVM_LOW)
    	endfunction

endclass 
