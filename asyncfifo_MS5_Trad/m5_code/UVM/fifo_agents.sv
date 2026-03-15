// ============================================================
// fifo_wr_agent.sv  –  Write-Domain UVM Agent
// ============================================================
// Encapsulates: fifo_wr_driver, uvm_sequencer#(fifo_wr_item),
//               fifo_wr_monitor
// Active mode  : driver + sequencer + monitor
// Passive mode : monitor only (set is_active=UVM_PASSIVE)
// ============================================================

class fifo_wr_agent extends uvm_agent;

    	`uvm_component_utils(fifo_wr_agent)

    	// Sub-components
    	fifo_wr_driver                      wr_drv;
    	uvm_sequencer #(fifo_wr_item)       wr_seqr;
    	fifo_wr_monitor                     wr_mon;

    	// Expose monitor analysis port upward to the env
    	uvm_analysis_port #(fifo_wr_item)   wr_ap;

    	function new(string name = "fifo_wr_agent", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction
    	
    	virtual function uvm_active_passive_enum get_is_active();
        	return UVM_ACTIVE;
    	endfunction

    	// ----------------------------------------------------------
    	// build_phase
    	// ----------------------------------------------------------
    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);

        	wr_mon  = fifo_wr_monitor::type_id::create("wr_mon",  this);
        	wr_ap   = new("wr_ap", this);
        	wr_seqr = uvm_sequencer #(fifo_wr_item)::type_id::create("wr_seqr", this);
        	wr_drv  = fifo_wr_driver::type_id::create("wr_drv",  this);
        	`uvm_info(get_type_name(), "ACTIVE write agent created", UVM_MEDIUM)
        	
    endfunction

    // ----------------------------------------------------------
    // connect_phase
    // ----------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        	// Forward monitor analysis port
        	wr_mon.wr_ap.connect(wr_ap);

        	if (get_is_active() == UVM_ACTIVE) begin
            	wr_drv.seq_item_port.connect(wr_seqr.seq_item_export);
        	end
    endfunction

    // ----------------------------------------------------------
    // report_phase
    // ----------------------------------------------------------
    function void report_phase(uvm_phase phase);
        	`uvm_info(get_type_name(),
            $sformatf("Write agent done. Active=%0s",(get_is_active() == UVM_ACTIVE) ? "YES" : "NO"),UVM_LOW)
    endfunction

endclass : fifo_wr_agent


// ============================================================
// fifo_rd_agent.sv  –  Read-Domain UVM Agent
// ============================================================

class fifo_rd_agent extends uvm_agent;

    	`uvm_component_utils(fifo_rd_agent)

    	fifo_rd_driver                      rd_drv;
    	uvm_sequencer #(fifo_rd_item)       rd_seqr;
    	fifo_rd_monitor                     rd_mon;

    	uvm_analysis_port #(fifo_rd_item)   rd_ap;

    	function new(string name = "fifo_rd_agent", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

	virtual function uvm_active_passive_enum get_is_active();
        	return UVM_ACTIVE;
    	endfunction

    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);

        	rd_mon = fifo_rd_monitor::type_id::create("rd_mon", this);
        	rd_ap  = new("rd_ap", this);

   
		rd_seqr = uvm_sequencer #(fifo_rd_item)::type_id::create("rd_seqr", this);
		rd_drv  = fifo_rd_driver::type_id::create("rd_drv",  this);
		`uvm_info(get_type_name(), "ACTIVE read agent created", UVM_MEDIUM)
		`uvm_info(get_type_name(), "PASSIVE read agent created (monitor only)", UVM_MEDIUM)
        	
    	endfunction

    	function void connect_phase(uvm_phase phase);
        	rd_mon.rd_ap.connect(rd_ap);

        	if (get_is_active() == UVM_ACTIVE) begin
            		rd_drv.seq_item_port.connect(rd_seqr.seq_item_export);
        	end
    	endfunction

    	function void report_phase(uvm_phase phase);
        	`uvm_info(get_type_name(),
            	$sformatf("Read agent done. Active=%0s",(get_is_active() == UVM_ACTIVE) ? "YES" : "NO"),UVM_LOW)
    endfunction

endclass
