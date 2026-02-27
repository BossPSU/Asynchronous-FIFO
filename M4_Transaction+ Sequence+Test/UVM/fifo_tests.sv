class fifo_base_test extends uvm_test;
	`uvm_component_utils(fifo_base_test)

	function new(string name="fifo_base_test", uvm_component parent=null);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

  	set_report_verbosity_level(UVM_MEDIUM); //keep it low
	
	endfunction
endclass

//smoke_test
//read N first, then write N
class fifo_smoke_test extends fifo_base_test;
	`uvm_component_utils(fifo_smoke_test)

	int unsigned n = 50;

	function new(string name="fifo_smoke_test", uvm_component parent=null);
		super.new(name, parent);
	endfunction

	virtual task run_phase(uvm_phase phase);
 		wr_burst_seq wseq;
		rd_burst_seq rseq;

		phase.raise_objection(this);

		wseq = wr_burst_seq::type_id::create("wseq");
		rseq = rd_burst_seq::type_id::create("rseq");
		
		//SMOKE ->DEPTH
		wseq.n = n;
		rseq.n = n;

		`uvm_info("TEST", $sformatf("SMOKE: wr %0d then rd %0d", n, n), UVM_LOW)

    // Need to wait until partner C give name for sequencer, env/w_agent/r_agent
    // wseq.start(w_seqr);
    // rseq.start(r_seqr);

	phase.drop_objection(this);
	
	endtask
endclass