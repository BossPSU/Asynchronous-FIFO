//library of reusable sequences

//single read/write request
//burst read/write requests
//write fill / read drain (fill/drain FIFO)
//fully randomized write stream

class wr_single_seq extends uvm_sequence #(fifo_wr_item);
    	`uvm_object_utils(wr_single_seq)

    	rand bit [DATA_WIDTH-1:0] data;

    	function new(string name = "wr_single_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_wr_item tr = fifo_wr_item::type_id::create("tr");
        	start_item(tr);
        	tr.data = data;
        	finish_item(tr);
        	`uvm_info("SEQ_WR_S", $sformatf("Single write: %s", tr.convert2string()), UVM_MEDIUM)
    	endtask
endclass

class wr_burst_seq extends uvm_sequence #(fifo_wr_item);
	int unsigned n =50;
	
	`uvm_object_utils(wr_burst_seq)

	function new(string name = "wr_burst_seq");
		super.new(name);
	endfunction

	virtual task body();
		fifo_wr_item tr;
		`uvm_info("SEQ_WR_B", $sformatf("Starting write burst of %0d items", n), UVM_LOW)
		
		for (int i =0; i < n; i++) begin
			tr = fifo_wr_item::type_id::create("tr");
			start_item(tr);
			if (!tr.randomize())
				`uvm_error("SEQ_WR_B", "Randomize failed")
			finish_item(tr);

			`uvm_info("SEQ_WR_B", tr.convert2string(), UVM_HIGH)
		end
		
		`uvm_info("SEQ_WR_B", $sformatf("Write burst of %0d items complete", n), UVM_LOW)
            
	endtask
endclass

class wr_fill_seq extends uvm_sequence #(fifo_wr_item);

    	`uvm_object_utils(wr_fill_seq)

    	function new(string name = "wr_fill_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_wr_item tr;
        	`uvm_info("SEQ_FILL", $sformatf("Filling FIFO with %0d items", DEPTH), UVM_LOW)

        	for (int i = 0; i < DEPTH; i++) begin
            		tr = fifo_wr_item::type_id::create("tr");
            		start_item(tr);
            		if (!tr.randomize())
                		`uvm_error("SEQ_FILL", "Randomize failed")
            		finish_item(tr);
        	end

        	`uvm_info("SEQ_FILL", "Fill sequence complete", UVM_LOW)
    	endtask
endclass 

class wr_rand_seq extends uvm_sequence #(fifo_wr_item);

    	int unsigned n = 20;

    	`uvm_object_utils(wr_rand_seq)

    	function new(string name = "wr_rand_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_wr_item tr;
        	`uvm_info("SEQ_RAND_WR", $sformatf("Starting %0d random writes", n), UVM_LOW)

        	repeat (n) begin
            		tr = fifo_wr_item::type_id::create("tr");
            		start_item(tr);
            		if (!tr.randomize()) begin
                		`uvm_error("SEQ_RAND_WR", "Randomization failed for wr item")
            		end
           		finish_item(tr);
            		`uvm_info("SEQ_RAND_WR", tr.convert2string(), UVM_HIGH)
        	end

        	`uvm_info("SEQ_RAND_WR",$sformatf("%0d random writes complete", n), UVM_LOW)
    	endtask
endclass

class rd_single_seq extends uvm_sequence #(fifo_rd_item);
    	`uvm_object_utils(rd_single_seq)

    	function new(string name = "rd_single_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_rd_item tr = fifo_rd_item::type_id::create("tr");
        	start_item(tr);
        	finish_item(tr);
        	`uvm_info("SEQ_RD_S", "Single read issued", UVM_MEDIUM)
    	endtask
endclass

class rd_burst_seq extends uvm_sequence #(fifo_rd_item);
	int unsigned n =50;
	
	`uvm_object_utils(rd_burst_seq)

	function new(string name = "rd_burst_seq");
		super.new(name);
	endfunction

	virtual task body();
		fifo_rd_item tr;
		for (int i =0; i < n; i++) begin
			tr = fifo_rd_item::type_id::create("tr");
			
			start_item(tr);
			finish_item(tr);

			`uvm_info("SEQ_RD", tr.convert2string(), UVM_LOW)
		end
	endtask
endclass


class rd_drain_seq extends uvm_sequence #(fifo_rd_item);

    	`uvm_object_utils(rd_drain_seq)
    	
    	int unsigned n = DEPTH;

    	function new(string name = "rd_drain_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_rd_item tr;
        	`uvm_info("SEQ_DRAIN", $sformatf("Draining FIFO – %0d reads", DEPTH), UVM_LOW)

        	for (int i = 0; i < n; i++) begin
            		tr = fifo_rd_item::type_id::create("tr");
            		start_item(tr);
            		finish_item(tr);
        	end

        	`uvm_info("SEQ_DRAIN", "Drain sequence complete", UVM_LOW)
    	endtask
endclass

// ─────────────────────────────────────────────────────────────
// Scenario sub-sequences
// Each one mirrors exactly what the corresponding individual
// test does, so fifo_full_seq can simply compose them – the
// same pattern used by mtx_full_seq → mtx_corner_seq +
// mtx_rand_seq.
//
// Every virtual sequence carries its own wr_seqr / rd_seqr
// handles; the parent (fifo_full_seq or the test) must set
// them before calling start().
// ─────────────────────────────────────────────────────────────

// ── 1. SMOKE ─────────────────────────────────────────────────
// Write N directed items then read N back.
class fifo_smoke_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_smoke_seq)

    	int unsigned n = 10;

    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;

    	function new(string name = "fifo_smoke_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	wr_burst_seq wseq;
        	rd_burst_seq rseq;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("SMOKE_SEQ", "wr_seqr / rd_seqr not set before starting fifo_smoke_seq")

        	wseq   = wr_burst_seq::type_id::create("wseq");
        	rseq   = rd_burst_seq::type_id::create("rseq");
        	wseq.n = n;
        	rseq.n = n;

        	`uvm_info("SMOKE_SEQ", $sformatf("wr %0d then rd %0d", n, n), UVM_LOW)
        	wseq.start(wr_seqr);
        	rseq.start(rd_seqr);
        	`uvm_info("SMOKE_SEQ", "Smoke sequence complete", UVM_LOW)
    	endtask
endclass

// ── 2. FILL / DRAIN ──────────────────────────────────────────
// Fill FIFO to DEPTH, let full flag propagate, then drain.
class fifo_fill_drain_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_fill_drain_seq)

    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;

    	function new(string name = "fifo_fill_drain_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	wr_fill_seq  fill;
        	rd_drain_seq drain;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("FILL_DRAIN_SEQ", "wr_seqr / rd_seqr not set before starting fifo_fill_drain_seq")

        	fill  = wr_fill_seq::type_id::create("fill");
        	drain = rd_drain_seq::type_id::create("drain");

        	`uvm_info("FILL_DRAIN_SEQ", $sformatf("Fill/Drain: DEPTH=%0d", DEPTH), UVM_LOW)
        	fill.start(wr_seqr);
        	drain.start(rd_seqr);
        	`uvm_info("FILL_DRAIN_SEQ", "Fill/Drain sequence complete", UVM_LOW)
    	endtask
endclass

// ── 3. OVERFLOW ──────────────────────────────────────────────
// Fill to DEPTH, attempt overflow_n extra writes (driver stalls
// on w_ready=0), then drain.
class fifo_overflow_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_overflow_seq)

    	int unsigned overflow_n = 4;   // extra writes beyond DEPTH

    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;

    	function new(string name = "fifo_overflow_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	wr_fill_seq  fill;
        	wr_burst_seq extra;
        	rd_drain_seq drain;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("OVERFLOW_SEQ", "wr_seqr / rd_seqr not set before starting fifo_overflow_seq")

        	fill  = wr_fill_seq::type_id::create("fill");
        	extra = wr_burst_seq::type_id::create("extra");
        	drain = rd_drain_seq::type_id::create("drain");
        	extra.n = overflow_n;
        	drain.n = DEPTH + overflow_n;

        	`uvm_info("OVERFLOW_SEQ", $sformatf("Overflow: fill + %0d extra writes", overflow_n), UVM_LOW)
        	fill.start(wr_seqr);
        	fork
        		extra.start(wr_seqr);   // driver stalls on w_ready=0
        		drain.start(rd_seqr);
        	join
        	`uvm_info("OVERFLOW_SEQ", "Overflow sequence complete", UVM_LOW)
    	endtask
endclass

// ── 4. UNDERFLOW ─────────────────────────────────────────────
// Issue reads before writes arrive; driver stalls on r_valid=0
// until writes show up 20 time-units later.
class fifo_underflow_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_underflow_seq)

    	int unsigned n = 4;

    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;

    	function new(string name = "fifo_underflow_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	rd_burst_seq rseq;
        	wr_burst_seq wseq;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("UNDERFLOW_SEQ", "wr_seqr / rd_seqr not set before starting fifo_underflow_seq")

        	rseq   = rd_burst_seq::type_id::create("rseq");
        	wseq   = wr_burst_seq::type_id::create("wseq");
        	rseq.n = n;
        	wseq.n = n;

        	`uvm_info("UNDERFLOW_SEQ", "Underflow: reads issued before writes", UVM_LOW)
        	fork
            		rseq.start(rd_seqr);
            		begin #20; wseq.start(wr_seqr); end
        	join
        	`uvm_info("UNDERFLOW_SEQ", "Underflow sequence complete", UVM_LOW)
    	endtask
endclass

// ── 5. RANDOM ────────────────────────────────────────────────
// Fully randomized writes followed by reads.
class fifo_rand_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_rand_seq)

    	int unsigned n = 30;

    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;

    	function new(string name = "fifo_rand_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	wr_rand_seq  wseq;
        	rd_burst_seq rseq;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("RAND_SEQ", "wr_seqr / rd_seqr not set before starting fifo_rand_seq")

        	wseq   = wr_rand_seq::type_id::create("wseq");
        	rseq   = rd_burst_seq::type_id::create("rseq");
        	wseq.n = n;
        	rseq.n = n;

        	`uvm_info("RAND_SEQ", $sformatf("Random: %0d rand writes → reads", n), UVM_LOW)
        	fork
        		wseq.start(wr_seqr);
        		rseq.start(rd_seqr);
        	join
        	`uvm_info("RAND_SEQ", "Random sequence complete", UVM_LOW)
    	endtask
endclass

// ── 6. CONCURRENT ────────────────────────────────────────────
// Randomized writes and reads running in parallel.
class fifo_concurrent_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_concurrent_seq)

    	int unsigned n = 20;

    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;

    	function new(string name = "fifo_concurrent_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	wr_rand_seq  wseq;
        	rd_burst_seq rseq;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("CONC_SEQ", "wr_seqr / rd_seqr not set before starting fifo_concurrent_seq")

        	wseq   = wr_rand_seq::type_id::create("wseq");
        	rseq   = rd_burst_seq::type_id::create("rseq");
        	wseq.n = n;
        	rseq.n = n;

        	`uvm_info("CONC_SEQ", $sformatf("Concurrent: %0d rand wr ‖ rd", n), UVM_LOW)
        	fork
            		wseq.start(wr_seqr);
            		rseq.start(rd_seqr);
        	join
        	`uvm_info("CONC_SEQ", "Concurrent sequence complete", UVM_LOW)
    	endtask
endclass

// ── 7. CORNER DATA ───────────────────────────────────────────
// Explicitly writes the four corner data values that coverage
// tracks as individual bins: 0x00, 0xFF, 0x55, 0xAA.
// These are written at various fill levels to hit the
// cx_data_x_fill cross bins in cg_write.
// Writes all four values twice: once into a nearly-empty FIFO
// and once into a nearly-full FIFO, then drains completely.
class fifo_corner_data_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_corner_data_seq)
 
    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;
 
    	function new(string name = "fifo_corner_data_seq");
        	super.new(name);
    	endfunction
 
    	virtual task body();
        	wr_single_seq  wseq;
        	rd_single_seq  rseq;
        	rd_drain_seq    drain;
        	wr_fill_seq     fill;
        	int unsigned    pad;
        	bit [DATA_WIDTH-1:0] corner_vals[4] = '{8'h00, 8'hFF, 8'h55, 8'hAA};
 
        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("CORNER_DATA_SEQ", "wr_seqr / rd_seqr not set")
 
        	`uvm_info("CORNER_DATA_SEQ", "Writing corner values into empty FIFO", UVM_LOW)
 
        	// ── Phase 1: write corner values into an empty FIFO
        	//    fill_level goes 0→1→2→3→4 hitting 'empty' and 'partial' bins
        	foreach (corner_vals[i]) begin
            		wseq = wr_single_seq::type_id::create($sformatf("wseq_phase1_%0d", i));
            		wseq.data = corner_vals[i];
            		wseq.start(wr_seqr);
        	end

        	// Drain those 4 items
        	repeat (4) begin
            		rseq = rd_single_seq::type_id::create("rseq");
            		rseq.start(rd_seqr);
        	end

        	`uvm_info("CORNER_DATA_SEQ", "Writing corner values into nearly-full FIFO", UVM_LOW)

        	// Fill to DEPTH-4 so the 4 corner writes bring FIFO to full
        	pad = DEPTH - 4;
        	repeat (pad) begin
            		wseq = wr_single_seq::type_id::create("wseq_pad");
            		if (!wseq.randomize())
                		`uvm_error("CORNER_DATA_SEQ", "Randomize failed for pad write")
            		wseq.start(wr_seqr);
        	end

        	// Write corner values at high fill levels
        	foreach (corner_vals[i]) begin
            		wseq = wr_single_seq::type_id::create($sformatf("wseq_phase2_%0d", i));
            		wseq.data = corner_vals[i];
            		wseq.start(wr_seqr);
        	end

        	// Drain everything
        	drain = rd_drain_seq::type_id::create("drain");
        	drain.n = DEPTH;
        	drain.start(rd_seqr);

        	`uvm_info("CORNER_DATA_SEQ", "Corner data sequence complete", UVM_LOW)
    	endtask
endclass

// ─────────────────────────────────────────────────────────────
// fifo_full_seq: composite sequence that exercises every
// scenario in a single, ordered run by delegating to each of
// the six named sub-sequences above.
//
// Mirrors mtx_full_seq → mtx_corner_seq + mtx_rand_seq.
//
// Order of operations:
//   1. fifo_smoke_seq      – write N then read N (directed burst)
//   2. fifo_fill_drain_seq – fill FIFO to DEPTH, drain completely
//   3. fifo_overflow_seq   – re-fill then attempt extra writes
//   4. fifo_underflow_seq  – reads issued before writes arrive
//   5. fifo_rand_seq       – N randomized writes then reads
//   6. fifo_concurrent_seq – N randomized writes forked with N reads
//   7. fifo_corner_data_seq  – explicit corner values at corner fill levels
// ─────────────────────────────────────────────────────────────
class fifo_full_seq extends uvm_sequence_base;
    	`uvm_object_utils(fifo_full_seq)

    	// Configurable counts forwarded to each sub-sequence
    	int unsigned smoke_n      = 10;
    	int unsigned overflow_n   = 4;
    	int unsigned rand_n       = 50;
    	int unsigned concurrent_n = 30;

    	// Sequencer handles – must be set by the test before start()
    	uvm_sequencer #(fifo_wr_item) wr_seqr;
    	uvm_sequencer #(fifo_rd_item) rd_seqr;

    	function new(string name = "fifo_full_seq");
        	super.new(name);
    	endfunction

    	// Propagate sequencer handles down into any sub-sequence
    	local function void wire_seqrs(uvm_sequence_base sub);
        	fifo_smoke_seq      s0;
        	fifo_fill_drain_seq s1;
        	fifo_overflow_seq   s2;
        	fifo_underflow_seq  s3;
        	fifo_rand_seq       s4;
        	fifo_concurrent_seq s5;

        	if ($cast(s0, sub)) begin s0.wr_seqr = wr_seqr; s0.rd_seqr = rd_seqr; return; end
        	if ($cast(s1, sub)) begin s1.wr_seqr = wr_seqr; s1.rd_seqr = rd_seqr; return; end
        	if ($cast(s2, sub)) begin s2.wr_seqr = wr_seqr; s2.rd_seqr = rd_seqr; return; end
        	if ($cast(s3, sub)) begin s3.wr_seqr = wr_seqr; s3.rd_seqr = rd_seqr; return; end
        	if ($cast(s4, sub)) begin s4.wr_seqr = wr_seqr; s4.rd_seqr = rd_seqr; return; end
        	if ($cast(s5, sub)) begin s5.wr_seqr = wr_seqr; s5.rd_seqr = rd_seqr; return; end
    	endfunction

    	virtual task body();
        	fifo_smoke_seq      smoke;
        	fifo_fill_drain_seq fill_drain;
        	fifo_overflow_seq   overflow;
        	fifo_underflow_seq  underflow;
        	fifo_rand_seq       rand_s;
        	fifo_concurrent_seq concurrent;
        	fifo_corner_data_seq corner_data;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("FULL_SEQ", "wr_seqr / rd_seqr not set before starting fifo_full_seq")

        	// ── 1. SMOKE ────────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[1/6] Smoke", UVM_LOW)
    		smoke          = fifo_smoke_seq::type_id::create("smoke");
    		smoke.n        = smoke_n;
    		smoke.wr_seqr  = wr_seqr;
    		smoke.rd_seqr  = rd_seqr;
    		smoke.start(m_sequencer);
    		#500;

    		// ── 2. FILL / DRAIN ─────────────────────────────────
    		`uvm_info("FULL_SEQ", "[2/6] Fill/Drain", UVM_LOW)
    		fill_drain          = fifo_fill_drain_seq::type_id::create("fill_drain");
    		fill_drain.wr_seqr  = wr_seqr;
    		fill_drain.rd_seqr  = rd_seqr;
    		fill_drain.start(m_sequencer);
    		#500;

    		// ── 3. OVERFLOW ─────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[3/6] Overflow", UVM_LOW)
    		overflow            = fifo_overflow_seq::type_id::create("overflow");
    		overflow.overflow_n = overflow_n;
    		overflow.wr_seqr    = wr_seqr;
    		overflow.rd_seqr    = rd_seqr;
    		overflow.start(m_sequencer);
    		#500;

    		// ── 4. UNDERFLOW ────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[4/6] Underflow", UVM_LOW)
    		underflow          = fifo_underflow_seq::type_id::create("underflow");
    		underflow.n        = 4;
    		underflow.wr_seqr  = wr_seqr;
    		underflow.rd_seqr  = rd_seqr;
    		underflow.start(m_sequencer);
    		#500;

    		// ── 5. RANDOM ───────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[5/6] Random", UVM_LOW)
    		rand_s          = fifo_rand_seq::type_id::create("rand_s");
    		rand_s.n        = rand_n;
    		rand_s.wr_seqr  = wr_seqr;
    		rand_s.rd_seqr  = rd_seqr;
    		rand_s.start(m_sequencer);
    		#500;

    		// ── 6. CONCURRENT ───────────────────────────────────
    		`uvm_info("FULL_SEQ", "[6/6] Concurrent", UVM_LOW)
    		concurrent          = fifo_concurrent_seq::type_id::create("concurrent");
    		concurrent.n        = concurrent_n;
    		concurrent.wr_seqr  = wr_seqr;
    		concurrent.rd_seqr  = rd_seqr;
    		concurrent.start(m_sequencer);
    		#500;
		
		// ── 7. CORNER DATA ───────────────────────────────────
        	// Explicitly exercises 0x00/0xFF/0x55/0xAA at empty, partial,
        	// and full fill levels to close the cx_data_x_fill cross bins.
        	`uvm_info("FULL_SEQ", "[7/7] Corner Data", UVM_LOW)
        	corner_data         = fifo_corner_data_seq::type_id::create("corner_data");
        	corner_data.wr_seqr = wr_seqr;
        	corner_data.rd_seqr = rd_seqr;
        	corner_data.start(m_sequencer);
        	#500;
        	
        	`uvm_info("FULL_SEQ", "fifo_full_seq complete – all 6 scenarios done", UVM_LOW)
    	endtask
endclass
