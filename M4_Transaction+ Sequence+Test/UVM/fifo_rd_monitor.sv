// ============================================================
// fifo_rd_monitor.sv  –  Read-Domain UVM Monitor
// ============================================================
// Passively observes r_valid / r_ready / r_data.
// Publishes accepted read transactions on rd_ap.
// ============================================================

class fifo_rd_monitor extends uvm_monitor;

    	`uvm_component_utils(fifo_rd_monitor)

    	// Analysis port – broadcasts fifo_rd_item to subscribers
    	uvm_analysis_port #(fifo_rd_item) rd_ap;

    	virtual fifo_if vif;

    	int unsigned observed_count;
    	int unsigned empty_stall_count;   // r_ready=1 but r_valid=0

    	function new(string name = "fifo_rd_monitor", uvm_component parent = null);
        	super.new(name, parent);
        	observed_count    = 0;
        	empty_stall_count = 0;
    	endfunction

    	// ----------------------------------------------------------
    	// build_phase
    	// ----------------------------------------------------------
    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);
        	rd_ap = new("rd_ap", this);

        	if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif)) begin
            		`uvm_fatal("CFG_ERR","fifo_rd_monitor: cannot get fifo_vif from config_db")
        	end
        	`uvm_info(get_type_name(), "build_phase complete", UVM_HIGH)
    	endfunction

    	// ----------------------------------------------------------
    	// run_phase
    	// ----------------------------------------------------------
    	task run_phase(uvm_phase phase);
        	`uvm_info(get_type_name(), "Read monitor running", UVM_MEDIUM)

        	forever begin
            	@(vif.rd_mon_cb);

            	if (vif.rd_mon_cb.rrst) continue;

            	// Stall detection
            	if (vif.rd_mon_cb.r_ready && !vif.rd_mon_cb.r_valid) begin
                	empty_stall_count++;
                	`uvm_info("RD_MON",$sformatf("[%0t] Read stall (FIFO empty). empty_stall_count=%0d",$time, empty_stall_count),UVM_HIGH)
            	end

            	// Accepted transfer
            	if (vif.rd_mon_cb.r_valid && vif.rd_mon_cb.r_ready) begin
                	fifo_rd_item tr;
                	tr = fifo_rd_item::type_id::create("rd_mon_item");
               		tr.r_valid = vif.rd_mon_cb.r_valid;
                	tr.r_data  = vif.rd_mon_cb.r_data;

                	rd_ap.write(tr);
                	observed_count++;

                	`uvm_info("RD_MON",$sformatf("[%0t] Captured: %s  [obs#%0d]",$time, tr.convert2string(), observed_count),UVM_MEDIUM)
            	end
        	end
    	endtask

    	// ----------------------------------------------------------
    	// report_phase
    	// ----------------------------------------------------------
    	function void report_phase(uvm_phase phase);
        	`uvm_info(get_type_name(),$sformatf("Read monitor summary: observed=%0d  empty_stalls=%0d",observed_count, empty_stall_count),UVM_LOW)
    	endfunction

endclass 
