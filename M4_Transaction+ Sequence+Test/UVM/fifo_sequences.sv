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
// fifo_reset_seq
// ─────────────────────────────────────────────────────────────
// Drives wrst and rrst high for rst_cycles write/read clocks,
// then releases both and waits sync_cycles for the gray-code
// synchronizer chains to flush before returning.
//
// The sequence drives reset directly through the virtual
// interface (not through the sequencer item path) because reset
// is an out-of-band control signal, not a data transaction.
//
// Usage: set vif before calling start().  The test is
// responsible for flushing the scoreboard shadow queue between
// assertion and release (call env.sb.flush_reset()).
// ─────────────────────────────────────────────────────────────
class fifo_reset_seq extends uvm_sequence_base;
    `uvm_object_utils(fifo_reset_seq)
 
    // Number of write-clock cycles to hold reset asserted
    int unsigned rst_cycles  = 4;
    // Extra cycles to wait after release for sync chains to settle
    int unsigned sync_cycles = 6;
 
    virtual fifo_if vif;
    // Optional coverage handle – if set, reset assertion/release
    // are sampled so cp_wrst and cp_rrst bins are covered
 
    function new(string name = "fifo_reset_seq");
        super.new(name);
    endfunction
 
    virtual task body();
        if (vif == null)
            `uvm_fatal("RESET_SEQ", "vif not set before starting fifo_reset_seq")
 
        `uvm_info("RESET_SEQ", $sformatf("Asserting reset for %0d wr-clk cycles", rst_cycles), UVM_LOW)
 
        // De-assert valid on both sides so no in-flight transaction
        // is left dangling while reset is asserted
        vif.wr_cb.w_valid <= 1'b0;
        vif.rd_cb.r_ready <= 1'b0;
        @(vif.wr_cb);
 
        // Assert reset synchronously to write clock; assert rrst one
        // read-clock edge later so both domains see clean assertion
        vif.wr_cb.wrst <= 1'b1;
        @(vif.rd_cb);
        vif.rd_cb.rrst <= 1'b1;
 
        // Hold for rst_cycles write-clock cycles
        repeat (rst_cycles) @(vif.wr_cb);
 
        // Release write-domain reset first, then read-domain one
        // read-clock later (matches typical async FIFO release order)
        vif.wr_cb.wrst <= 1'b0;
        @(vif.rd_cb);
        vif.rd_cb.rrst <= 1'b0;
 
        `uvm_info("RESET_SEQ", "Reset released – waiting for sync chains to settle", UVM_LOW)
 
        // Wait for both synchronizer pipelines to flush
        repeat (sync_cycles) @(vif.wr_cb);
 
        `uvm_info("RESET_SEQ", "Reset sequence complete – FIFO ready", UVM_LOW)
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

// ── 8. Reset Test ───────────────────────────────────────────
// Composite sequence that exercises mid-simulation reset:
//   1. Write N items into the FIFO (leaving it partially full)
//   2. Assert reset – FIFO state must be discarded
//   3. Flush scoreboard shadow queue (stale expected data gone)
//   4. Release reset and wait for sync chains
//   5. Smoke check: write M fresh items and read them back,
//      confirming the FIFO behaves as empty after reset
// ─────────────────────────────────────────────────────────────
class fifo_reset_test_seq extends uvm_sequence_base;
    `uvm_object_utils(fifo_reset_test_seq)
 
    // Items written before reset (leaves FIFO partially full)
    int unsigned pre_reset_n  = 8;
    // Items written + read after reset (smoke check)
    int unsigned post_reset_n = 4;
 
    uvm_sequencer #(fifo_wr_item) wr_seqr;
    uvm_sequencer #(fifo_rd_item) rd_seqr;
    virtual fifo_if               vif;
    // Direct handle to scoreboard so we can flush it on reset
    uvm_component              sb;


 
    function new(string name = "fifo_reset_test_seq");
        super.new(name);
    endfunction
 
    virtual task body();
        wr_burst_seq  pre_wr;
        fifo_reset_seq rst;
        fifo_smoke_seq post_smoke;
 
        if (wr_seqr == null)
    		`uvm_fatal("RST_TEST_SEQ", "wr_seqr is null before start")
	if (rd_seqr == null)
    		`uvm_fatal("RST_TEST_SEQ", "rd_seqr is null before start")
	if (vif == null)
    		`uvm_fatal("RST_TEST_SEQ", "vif is null before start")
	if (sb == null)
    		`uvm_fatal("RST_TEST_SEQ", "sb is null before start")
 
        // ── 1. Write pre_reset_n items (FIFO left partially full)
        `uvm_info("RST_TEST_SEQ", $sformatf("Phase 1: writing %0d items pre-reset", pre_reset_n), UVM_LOW)
        pre_wr   = wr_burst_seq::type_id::create("pre_wr");
        pre_wr.n = pre_reset_n;
        pre_wr.start(wr_seqr);
 
        // ── 2. Assert reset (discards FIFO contents)
        `uvm_info("RST_TEST_SEQ", "Phase 2: asserting reset", UVM_LOW)
        rst     = fifo_reset_seq::type_id::create("rst");
        rst.vif = vif;
        rst.start(m_sequencer);
 
        // ── 3. Flush scoreboard – pre-reset writes are now lost
        `uvm_info("RST_TEST_SEQ", "Phase 3: flushing scoreboard", UVM_LOW)
        begin
            fifo_scoreboard sb_typed;
            if (!$cast(sb_typed, sb))
                `uvm_fatal("RST_TEST_SEQ", "sb handle is not a fifo_scoreboard")
            sb_typed.flush_reset();
        end
 
        // ── 4. Post-reset smoke: write M items and read them back.
        //    If the FIFO was truly reset, data comes back in FIFO
        //    order starting from the first post-reset write.
        `uvm_info("RST_TEST_SEQ", $sformatf("Phase 4: post-reset smoke (%0d items)", post_reset_n), UVM_LOW)
        post_smoke         = fifo_smoke_seq::type_id::create("post_smoke");
        post_smoke.n       = post_reset_n;
        post_smoke.wr_seqr = wr_seqr;
        post_smoke.rd_seqr = rd_seqr;
        post_smoke.start(m_sequencer);
 
        `uvm_info("RST_TEST_SEQ", "Reset test sequence complete", UVM_LOW)
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
//   8. fifo_reset_test_seq - reset FIFO after N randomized writes
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
    	virtual fifo_if  vif;
    	uvm_component    sb;

    	function new(string name = "fifo_full_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_smoke_seq      smoke;
        	fifo_fill_drain_seq fill_drain;
        	fifo_overflow_seq   overflow;
        	fifo_underflow_seq  underflow;
        	fifo_rand_seq       rand_s;
        	fifo_concurrent_seq concurrent;
        	fifo_corner_data_seq corner_data;
        	fifo_reset_test_seq reset;

        	if (wr_seqr == null || rd_seqr == null)
            		`uvm_fatal("FULL_SEQ", "wr_seqr / rd_seqr not set before starting fifo_full_seq")

        	// ── 1. SMOKE ────────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[1/8] Smoke", UVM_LOW)
    		smoke          = fifo_smoke_seq::type_id::create("smoke");
    		smoke.n        = smoke_n;
    		smoke.wr_seqr  = wr_seqr;
    		smoke.rd_seqr  = rd_seqr;
    		smoke.start(m_sequencer);
    		#500;

    		// ── 2. FILL / DRAIN ─────────────────────────────────
    		`uvm_info("FULL_SEQ", "[2/8] Fill/Drain", UVM_LOW)
    		fill_drain          = fifo_fill_drain_seq::type_id::create("fill_drain");
    		fill_drain.wr_seqr  = wr_seqr;
    		fill_drain.rd_seqr  = rd_seqr;
    		fill_drain.start(m_sequencer);
    		#500;

    		// ── 3. OVERFLOW ─────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[3/8] Overflow", UVM_LOW)
    		overflow            = fifo_overflow_seq::type_id::create("overflow");
    		overflow.overflow_n = overflow_n;
    		overflow.wr_seqr    = wr_seqr;
    		overflow.rd_seqr    = rd_seqr;
    		overflow.start(m_sequencer);
    		#500;

    		// ── 4. UNDERFLOW ────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[4/8] Underflow", UVM_LOW)
    		underflow          = fifo_underflow_seq::type_id::create("underflow");
    		underflow.n        = 4;
    		underflow.wr_seqr  = wr_seqr;
    		underflow.rd_seqr  = rd_seqr;
    		underflow.start(m_sequencer);
    		#500;

    		// ── 5. RANDOM ───────────────────────────────────────
    		`uvm_info("FULL_SEQ", "[5/8] Random", UVM_LOW)
    		rand_s          = fifo_rand_seq::type_id::create("rand_s");
    		rand_s.n        = rand_n;
    		rand_s.wr_seqr  = wr_seqr;
    		rand_s.rd_seqr  = rd_seqr;
    		rand_s.start(m_sequencer);
    		#500;

    		// ── 6. CONCURRENT ───────────────────────────────────
    		`uvm_info("FULL_SEQ", "[6/8] Concurrent", UVM_LOW)
    		concurrent          = fifo_concurrent_seq::type_id::create("concurrent");
    		concurrent.n        = concurrent_n;
    		concurrent.wr_seqr  = wr_seqr;
    		concurrent.rd_seqr  = rd_seqr;
    		concurrent.start(m_sequencer);
    		#500;
		
		// ── 7. CORNER DATA ───────────────────────────────────
        	// Explicitly exercises 0x00/0xFF/0x55/0xAA at empty, partial,
        	// and full fill levels to close the cx_data_x_fill cross bins.
        	`uvm_info("FULL_SEQ", "[7/8] Corner Data", UVM_LOW)
        	corner_data         = fifo_corner_data_seq::type_id::create("corner_data");
        	corner_data.wr_seqr = wr_seqr;
        	corner_data.rd_seqr = rd_seqr;
        	corner_data.start(m_sequencer);
        	#500;

		// ── 6. Reset ───────────────────────────────────
    		`uvm_info("FULL_SEQ", "[8/8] Reset", UVM_LOW)
    		reset          = fifo_reset_test_seq::type_id::create("reset");
    		reset.wr_seqr  = wr_seqr;
    		reset.rd_seqr  = rd_seqr;
    		reset.vif     = vif;
            	reset.sb      = sb;
    		reset.start(m_sequencer);
    		#500;
        	
        	`uvm_info("FULL_SEQ", "fifo_full_seq complete – all 6 scenarios done", UVM_LOW)
    	endtask
endclass
