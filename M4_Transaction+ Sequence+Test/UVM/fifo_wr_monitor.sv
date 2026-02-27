// ============================================================
// fifo_wr_monitor.sv  –  Write-Domain UVM Monitor
// ============================================================
// Passively observes w_valid / w_ready / w_data.
// Publishes accepted write transactions on wr_ap (analysis port)
// for scoreboard and coverage collection.
// ============================================================

class fifo_wr_monitor extends uvm_monitor;

    	`uvm_component_utils(fifo_wr_monitor)

    	// Analysis port – broadcasts fifo_wr_item to subscribers
    	uvm_analysis_port #(fifo_wr_item) wr_ap;

    	virtual fifo_if vif;

    	// Statistics
    	int unsigned observed_count;
    	int unsigned stall_count;      // cycles where w_valid=1 but w_ready=0

    	function new(string name = "fifo_wr_monitor", uvm_component parent = null);
        	super.new(name, parent);
        	observed_count = 0;
        	stall_count    = 0;
    	endfunction

    	// ----------------------------------------------------------
    	// build_phase
    	// ----------------------------------------------------------
    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);
        	wr_ap = new("wr_ap", this);

        	if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif)) begin
            		`uvm_fatal("CFG_ERR","fifo_wr_monitor: cannot get fifo_vif from config_db")
        	end
        	`uvm_info(get_type_name(), "build_phase complete", UVM_HIGH)
    	endfunction

    	// ----------------------------------------------------------
    	// run_phase: sample every write clock edge
    	// ----------------------------------------------------------
    	task run_phase(uvm_phase phase);
        	`uvm_info(get_type_name(), "Write monitor running", UVM_MEDIUM)

        	forever begin
            		@(vif.wr_mon_cb);

            		// Skip while in reset
            		if (vif.wr_mon_cb.wrst) continue;

            		// Detect stall (valid but not ready)
            		if (vif.wr_mon_cb.w_valid && !vif.wr_mon_cb.w_ready) begin
                		stall_count++;
                		`uvm_info("WR_MON",$sformatf("[%0t] Write stall detected (FIFO full). stall_count=%0d",$time, stall_count),UVM_HIGH)
            		end

            		// Accepted transfer: valid AND ready both high
            		if (vif.wr_mon_cb.w_valid && vif.wr_mon_cb.w_ready) begin
                		fifo_wr_item tr;
                		tr = fifo_wr_item::type_id::create("wr_mon_item");
                		tr.data = vif.wr_mon_cb.w_data;

                		wr_ap.write(tr);
                		observed_count++;

                		`uvm_info("WR_MON",$sformatf("[%0t] Captured: %s  [obs#%0d]",$time, tr.convert2string(), observed_count),UVM_MEDIUM)
            		end
        	end
    	endtask

    	// ----------------------------------------------------------
    	// report_phase
    	// ----------------------------------------------------------
    	function void report_phase(uvm_phase phase);
        	`uvm_info(get_type_name(),$sformatf("Write monitor summary: observed=%0d  write_stalls=%0d",observed_count, stall_count),UVM_LOW)
    	endfunction

endclass
