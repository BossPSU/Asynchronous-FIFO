// ============================================================
// fifo_wr_driver.sv  –  Write-Domain UVM Driver
// ============================================================
// Drives w_valid / w_data on the write clock domain.
// Implements a valid/ready (AXI-style) handshake:
//   - Assert w_valid + w_data
//   - Wait until w_ready (FIFO not full)
//   - Deassert w_valid the cycle after acceptance
// ============================================================

class fifo_wr_driver extends uvm_driver #(fifo_wr_item);

    	`uvm_component_utils(fifo_wr_driver)

    	// Virtual interface handle (write-domain modport)
    	virtual fifo_if vif;

    	// Statistics
    	int unsigned txn_count;

    	function new(string name = "fifo_wr_driver", uvm_component parent = null);
        	super.new(name, parent);
        	txn_count = 0;
    	endfunction

    	// ----------------------------------------------------------
    	// build_phase: retrieve interface from config_db
    	// ----------------------------------------------------------
    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);
        	if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif)) begin
            		`uvm_fatal("CFG_ERR","fifo_wr_driver: cannot get fifo_vif from config_db")
        	end
        	`uvm_info(get_type_name(), "build_phase complete", UVM_HIGH)
    	endfunction

    	// ----------------------------------------------------------
    	// connect_phase: nothing to connect here
    	// ----------------------------------------------------------

    	// ----------------------------------------------------------	
    	// run_phase: get item -> drive -> item_done loop
    	// ----------------------------------------------------------
    	task run_phase(uvm_phase phase);
        	// Idle defaults
       		vif.wr_cb.w_valid <= 1'b0;
        	vif.wr_cb.w_data  <= '0;

        	// Wait for write-domain reset to deassert
        	wait (vif.wrst === 1'b0);
        	@(vif.wr_cb);

        	`uvm_info(get_type_name(), "Write driver: reset released, starting", UVM_MEDIUM)

        	forever begin
            		fifo_wr_item tr;
            		seq_item_port.get_next_item(tr);

           		drive_item(tr);

            		seq_item_port.item_done();
            		txn_count++;

            		`uvm_info("WR_DRV",$sformatf("[%0t] Drove: %s  total_txn=%0d",$time, tr.convert2string(), txn_count),UVM_MEDIUM)
        	end
    	endtask

    	// ----------------------------------------------------------
    	// drive_item: handshake logic
    	// ----------------------------------------------------------
    	task drive_item(fifo_wr_item tr);
    		@(vif.wr_cb);

		vif.wr_cb.w_valid <= 1'b1;
		vif.wr_cb.w_data  <= tr.data;

		do @(vif.wr_cb);
		while (!vif.wr_cb.w_ready);

		vif.wr_cb.w_valid <= 1'b0;
    	endtask

    	// ----------------------------------------------------------
    	// report_phase: log driver statistics
    	// ----------------------------------------------------------
    	function void report_phase(uvm_phase phase);
        	`uvm_info(get_type_name(), $sformatf("Write driver finished – transactions driven: %0d", txn_count),UVM_LOW)
    	endfunction

endclass
