// ============================================================
// fifo_env.sv  –  Top-Level UVM Environment
// ============================================================
// Contains:
//   - fifo_wr_agent  (active)
//   - fifo_rd_agent  (active)
//   - fifo_scoreboard
//
// Connects agent analysis ports to scoreboard analysis imports.
// ============================================================

class fifo_env extends uvm_env;

    	`uvm_component_utils(fifo_env)

    	fifo_wr_agent    wr_agent;
    	fifo_rd_agent    rd_agent;
    	fifo_vseqr_t vseqr;
    	fifo_scoreboard  sb;
    	fifo_coverage 	 cov;

    	function new(string name = "fifo_env", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

    	// ----------------------------------------------------------
    	// build_phase
    	// ----------------------------------------------------------
    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);
       	
        	uvm_config_db #(uvm_active_passive_enum)::set(this, "wr_agent", "is_active", UVM_ACTIVE);
        	uvm_config_db #(uvm_active_passive_enum)::set(this, "rd_agent", "is_active", UVM_ACTIVE);
	
        	wr_agent = fifo_wr_agent::type_id::create("wr_agent", this);
        	rd_agent = fifo_rd_agent::type_id::create("rd_agent", this);
        	vseqr = fifo_vseqr_t::type_id::create("vseqr", this);
        	sb       = fifo_scoreboard::type_id::create("sb",       this);
        	cov = fifo_coverage::type_id::create("cov", this);
	
 
        	`uvm_info(get_type_name(), "fifo_env build_phase complete", UVM_MEDIUM)
    	endfunction

    	// ----------------------------------------------------------
    	// connect_phase: wire analysis ports to scoreboard
    	// ----------------------------------------------------------
    	function void connect_phase(uvm_phase phase);
        	wr_agent.wr_ap.connect(sb.wr_ap);
        	rd_agent.rd_ap.connect(sb.rd_ap);
		wr_agent.wr_ap.connect(cov.analysis_export);  // write transactions
		rd_agent.rd_ap.connect(cov.rd_export);         // read transactions
        	`uvm_info(get_type_name(), "fifo_env connect_phase complete", UVM_MEDIUM)
    	endfunction

    	// ----------------------------------------------------------
    	// end_of_elaboration_phase: print TB topology
    	// ----------------------------------------------------------
    	function void end_of_elaboration_phase(uvm_phase phase);
        	`uvm_info(get_type_name(), "UVM Hierarchy:", UVM_MEDIUM)
        	uvm_top.print_topology();
    	endfunction

endclass
