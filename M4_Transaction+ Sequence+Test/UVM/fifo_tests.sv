class fifo_base_test extends uvm_test;
	`uvm_component_utils(fifo_base_test)
	
	fifo_env env;
	
	function new(string name="fifo_base_test", uvm_component parent=null);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		env = fifo_env::type_id::create("env", this);

  		set_report_verbosity_level_hier(UVM_MEDIUM); //keep it low
	
		set_report_default_file_hier($fopen("uvm_sim.log", "w"));
        	set_report_severity_action_hier(UVM_INFO,    UVM_LOG | UVM_DISPLAY);
        	set_report_severity_action_hier(UVM_WARNING, UVM_LOG | UVM_DISPLAY | UVM_COUNT);
        	set_report_severity_action_hier(UVM_ERROR,   UVM_LOG | UVM_DISPLAY | UVM_COUNT);
        	set_report_severity_action_hier(UVM_FATAL,   UVM_LOG | UVM_DISPLAY | UVM_EXIT);

        	`uvm_info(get_type_name(), "Base test build_phase done", UVM_MEDIUM)
	endfunction

	// Helper: wire sequencer handles into any sub-sequence then start it
	protected task run_vseq(uvm_sequence_base seq);
		fifo_smoke_seq      s0;
		fifo_fill_drain_seq s1;
		fifo_overflow_seq   s2;
		fifo_underflow_seq  s3;
		fifo_rand_seq       s4;
		fifo_concurrent_seq s5;
		fifo_full_seq       sf;

		if ($cast(s0, seq)) begin s0.wr_seqr = env.wr_agent.wr_seqr; s0.rd_seqr = env.rd_agent.rd_seqr; end
		else if ($cast(s1, seq)) begin s1.wr_seqr = env.wr_agent.wr_seqr; s1.rd_seqr = env.rd_agent.rd_seqr; end
		else if ($cast(s2, seq)) begin s2.wr_seqr = env.wr_agent.wr_seqr; s2.rd_seqr = env.rd_agent.rd_seqr; end
		else if ($cast(s3, seq)) begin s3.wr_seqr = env.wr_agent.wr_seqr; s3.rd_seqr = env.rd_agent.rd_seqr; end
		else if ($cast(s4, seq)) begin s4.wr_seqr = env.wr_agent.wr_seqr; s4.rd_seqr = env.rd_agent.rd_seqr; end
		else if ($cast(s5, seq)) begin s5.wr_seqr = env.wr_agent.wr_seqr; s5.rd_seqr = env.rd_agent.rd_seqr; end
		else if ($cast(sf, seq)) begin 
			virtual fifo_if vif_tmp;
        		sf.wr_seqr = env.wr_agent.wr_seqr;
        		sf.rd_seqr = env.rd_agent.rd_seqr;
        		if (uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif_tmp))
            			sf.vif = vif_tmp;
        		sf.sb = env.sb;
    		end

		begin
			fifo_reset_test_seq sr;
			if ($cast(sr, seq)) begin
        			virtual fifo_if vif_tmp;
        			sr.wr_seqr = env.wr_agent.wr_seqr;
        			sr.rd_seqr = env.rd_agent.rd_seqr;
        			sr.sb      = env.sb;
        			if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif_tmp))
            				`uvm_fatal("CFG_ERR", "run_vseq: cannot get fifo_vif for fifo_reset_test_seq")
        			sr.vif = vif_tmp;
			end
		end

		seq.start(env.vseqr);
	endtask
	
endclass

// ─────────────────────────────────────────────────────────────
// Individual tests – each instantiates its own named
// sub-sequence and delegates all stimulus to it, mirroring
// how mtx_corner_test delegates to mtx_corner_seq and
// mtx_rand_test delegates to mtx_rand_seq.
// ─────────────────────────────────────────────────────────────

//smoke_test
//write N then read N
class fifo_smoke_test extends fifo_base_test;
	`uvm_component_utils(fifo_smoke_test)

	int unsigned n = 10;

	function new(string name="fifo_smoke_test", uvm_component parent=null);
		super.new(name, parent);
	endfunction

	virtual task run_phase(uvm_phase phase);
		fifo_smoke_seq seq;

		phase.raise_objection(this, "smoke test started");

		seq   = fifo_smoke_seq::type_id::create("seq");
		seq.n = n;

		`uvm_info("SMOKE", $sformatf("wr %0d then rd %0d", n, n), UVM_LOW)
		run_vseq(seq);
		`uvm_info("SMOKE", "Smoke test complete", UVM_LOW)

		phase.drop_objection(this, "smoke test done");
	endtask
endclass

//fill+drain test
//fill FIFO, verify full, drain
class fifo_fill_drain_test extends fifo_base_test;

    	`uvm_component_utils(fifo_fill_drain_test)

    	function new(string name = "fifo_fill_drain_test", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

    	virtual task run_phase(uvm_phase phase);
        	fifo_fill_drain_seq seq;

        	phase.raise_objection(this, "fill_drain started");

        	seq = fifo_fill_drain_seq::type_id::create("seq");

        	`uvm_info("FILL_DRAIN", $sformatf("Filling FIFO (DEPTH=%0d) then draining", DEPTH), UVM_LOW)
        	run_vseq(seq);
        	`uvm_info("FILL_DRAIN", "Fill/drain test complete", UVM_LOW)

        	phase.drop_objection(this, "fill_drain done");
    	endtask

endclass

//overflow test
//fill to depth and attempt extra writes
//verify no data loss
class fifo_overflow_test extends fifo_base_test;

    	`uvm_component_utils(fifo_overflow_test)

    	int unsigned overflow_n = 4;   // extra writes beyond DEPTH

    	function new(string name = "fifo_overflow_test", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

    	virtual task run_phase(uvm_phase phase);
        	fifo_overflow_seq seq;

        	phase.raise_objection(this, "overflow test started");

        	seq             = fifo_overflow_seq::type_id::create("seq");
        	seq.overflow_n  = overflow_n;

        	`uvm_info("OVERFLOW", "Filling FIFO then attempting overflow", UVM_LOW)
        	run_vseq(seq);
        	`uvm_info("OVERFLOW", "Overflow test complete", UVM_LOW)

        	phase.drop_objection(this, "overflow done");
    	endtask

endclass

//underflow test
//test reading from empty FIFO
//verify driver stalls when FIFO empty
class fifo_underflow_test extends fifo_base_test;

    	`uvm_component_utils(fifo_underflow_test)

    	int unsigned n = 4;

    	function new(string name = "fifo_underflow_test", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

    	virtual task run_phase(uvm_phase phase);
        	fifo_underflow_seq seq;

        	phase.raise_objection(this, "underflow test started");

        	seq   = fifo_underflow_seq::type_id::create("seq");
        	seq.n = n;

        	`uvm_info("UFLOW", "Attempting reads from initially empty FIFO", UVM_LOW)
        	run_vseq(seq);
        	`uvm_info("UFLOW", "Underflow test complete", UVM_LOW)

        	phase.drop_objection(this, "underflow done");
    	endtask

endclass

class fifo_rand_test extends fifo_base_test;

    	`uvm_component_utils(fifo_rand_test)

    	int unsigned n = 30;

    	function new(string name = "fifo_rand_test", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

    	virtual task run_phase(uvm_phase phase);
        	fifo_rand_seq seq;

       		phase.raise_objection(this, "rand test started");

        	seq   = fifo_rand_seq::type_id::create("seq");
        	seq.n = n;

        	`uvm_info("RAND_TEST",$sformatf("Random write/read test: %0d transactions", n), UVM_LOW)
        	run_vseq(seq);
        	`uvm_info("RAND_TEST", "Random test complete", UVM_LOW)

        	phase.drop_objection(this, "rand test done");
    	endtask

endclass

class fifo_concurrent_test extends fifo_base_test;

    	`uvm_component_utils(fifo_concurrent_test)

    	int unsigned n = 20;

    	function new(string name = "fifo_concurrent_test", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

    	virtual task run_phase(uvm_phase phase);
        	fifo_concurrent_seq seq;

        	phase.raise_objection(this, "concurrent test started");

        	seq   = fifo_concurrent_seq::type_id::create("seq");
        	seq.n = n;

        	`uvm_info("CONC_TEST",$sformatf("Concurrent RW test: %0d transactions", n), UVM_LOW)
        	run_vseq(seq);
        	`uvm_info("CONC_TEST", "Concurrent test complete", UVM_LOW)

        	phase.drop_objection(this, "concurrent done");
    	endtask

endclass

class fifo_reset_test extends fifo_base_test;
    `uvm_component_utils(fifo_reset_test)
 
    function new(string name = "fifo_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
 
    virtual task run_phase(uvm_phase phase);
        fifo_reset_test_seq seq;
        virtual fifo_if vif;
 
        phase.raise_objection(this, "reset test started");
 
        // Retrieve the virtual interface so we can pass it to the sequence
        if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif))
            `uvm_fatal("CFG_ERR", "fifo_reset_test: cannot get fifo_vif from config_db")
 
        seq              = fifo_reset_test_seq::type_id::create("seq");
        seq.wr_seqr      = env.wr_agent.wr_seqr;
        seq.rd_seqr      = env.rd_agent.rd_seqr;
        seq.vif          = vif;
        seq.sb           = env.sb;
        seq.pre_reset_n  = 8;
        seq.post_reset_n = 4;
 
        `uvm_info("RESET_TEST", "Starting reset test", UVM_LOW)
        env.cov.sample_reset(1'b0, 1'b0);  // deasserted baseline
        env.cov.sample_reset(1'b1, 1'b1);  // asserted (seq will drive this)
        seq.start(env.vseqr);
        env.cov.sample_reset(1'b0, 1'b0);  // deasserted after seq completes
        `uvm_info("RESET_TEST", "Reset test complete", UVM_LOW)
 
        phase.drop_objection(this, "reset test done");
    endtask
endclass

// ─────────────────────────────────────────────────────────────
// fifo_full_test: composes all eight sub-sequences via
// fifo_full_seq, exactly as mtx_full_test composes
// mtx_corner_seq + mtx_rand_seq via mtx_full_seq.
// ─────────────────────────────────────────────────────────────
class fifo_full_test extends fifo_base_test;
    	`uvm_component_utils(fifo_full_test)

    	function new(string name = "fifo_full_test", uvm_component parent = null);
        	super.new(name, parent);
    	endfunction

    	virtual task run_phase(uvm_phase phase);
        	fifo_full_seq full_seq;
    		virtual fifo_if vif;

    		phase.raise_objection(this, "full test started");

    		if (!uvm_config_db #(virtual fifo_if)::get(this, "", "fifo_vif", vif))
        		`uvm_fatal("CFG_ERR", "fifo_full_test: cannot get fifo_vif from config_db")

    		full_seq = fifo_full_seq::type_id::create("full_seq");
    		full_seq.wr_seqr = env.wr_agent.wr_seqr;
    		full_seq.rd_seqr = env.rd_agent.rd_seqr;
    		full_seq.vif     = vif;
    		full_seq.sb      = env.sb;

    		`uvm_info("FULL_TEST", "Starting fifo_full_seq (all 8 scenarios)", UVM_LOW)
    		full_seq.start(env.vseqr);
    		`uvm_info("FULL_TEST", "Full test complete", UVM_LOW)

    		phase.drop_objection(this, "full test done");
    	endtask

endclass
