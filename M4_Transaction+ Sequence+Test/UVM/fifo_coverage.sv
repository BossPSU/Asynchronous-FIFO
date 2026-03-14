// ============================================================
// fifo_coverage.sv  –  Functional Coverage Collector
// ============================================================
// Subscribes to both monitor analysis ports and samples
// covergroups on every observed transaction.
// ============================================================
class fifo_coverage extends uvm_subscriber #(fifo_wr_item);

	`uvm_component_utils(fifo_coverage)
	
    	fifo_wr_item  trans;
    	int unsigned  fill_level;
    	bit [7:0]     rd_data;
    	bit           dut_full;
   	bit           dut_empty;
   	bit           wrst_obs;
    	bit           rrst_obs;
    	bit           wr_stall;
    	bit           rd_stall;

    	// ── Write-side covergroup ────────────────────────────────
    	covergroup cg_write;

        	// Did we write all possible data values?
        	cp_wr_data: coverpoint trans.data {
            		bins zero        = {8'h00};
            		bins ones        = {8'hFF};
            		bins walking_1   = {8'h55};
            		bins walking_0   = {8'hAA};
            		bins low_range   = {[8'h01 : 8'h3F]};
            		bins mid_range   = {[8'h40 : 8'hBF]};
            		bins high_range  = {[8'hC0 : 8'hFE]};
        		}

        	// Did we write when FIFO was empty or partially full?
        	// "full" is structurally uncoverable: the write monitor only fires
        	// on accepted writes (w_ready=1), which requires the FIFO to not
        	// be full. Backpressured writes are never captured by the monitor.
        	cp_fill_level: coverpoint fill_level {
            		bins empty          = {0};
            		bins partial        = {[1 : DEPTH-1]};
            		ignore_bins full    = {DEPTH};
        	}

        	

    	endgroup

    	// ── Read-side covergroup ─────────────────────────────────
    	covergroup cg_read;

        	cp_rd_data: coverpoint rd_data {
            		bins zero      = {8'h00};
            		bins ones      = {8'hFF};
            		bins low       = {[8'h01 : 8'h7F]};
            		bins high      = {[8'h80 : 8'hFE]};
        	}

        	// "empty" is structurally uncoverable: the read monitor only fires
        	// when r_valid=1, meaning data was available. A read from an empty
        	// FIFO stalls until data arrives; by the time the monitor fires,
        	// fill_level is already >= 1.
        	cp_fill_at_read: coverpoint fill_level {
            		ignore_bins empty   = {0};
            		bins partial        = {[1 : DEPTH-1]};
            		bins full           = {DEPTH};
        	}

    	endgroup

    	// ── Handshake / flag covergroup ──────────────────────────
    	covergroup cg_flags;

        	// Was full flag seen?
        	cp_full: coverpoint dut_full {
            		bins not_full  = {0};
            		bins full      = {1};
        	}

        	// Was empty flag seen?
        	cp_empty: coverpoint dut_empty {
            		bins not_empty = {0};
            		bins empty     = {1};
        	}

        	// Were both full and empty seen across the simulation?
        	// Note: full=1 and empty=1 simultaneously is structurally
        	// impossible for a correct FIFO — mark it illegal so it is
        	// excluded from the coverage denominator.
        	cx_full_x_empty: cross cp_full, cp_empty {
            		illegal_bins impossible =
                		binsof(cp_full.full) && binsof(cp_empty.empty);
        	}

        	// Back-pressure: write attempted while full
        	cp_wr_stall: coverpoint wr_stall {
           		bins no_stall  = {0};
            		bins stalled   = {1};
        	}

        	// Read stall: structurally uncoverable via monitor-only architecture.
        	// The read monitor only publishes r_valid=1 transactions; stalled
        	// reads (r_valid=0) are never captured. The inferred rd_stall=1
        	// (fill==0 at read completion) also cannot fire because the read
        	// monitor only fires when data is available (fill >= 1).
        	cp_rd_stall: coverpoint rd_stall {
           		bins no_stall       = {0};
            		ignore_bins stalled = {1};
        	}
        	


    	endgroup

    	// Second analysis imp for read-side
    	uvm_analysis_imp_rd #(fifo_rd_item, fifo_coverage) rd_export;

    	function new(string name = "fifo_coverage", uvm_component parent = null);
        	super.new(name, parent);
        	cg_write = new();
        	cg_read  = new();
        	cg_flags = new();
        	fill_level = 0;
    	endfunction

    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);
        	rd_export = new("rd_export", this);
        	`uvm_info(get_type_name(), "Coverage collector built", UVM_MEDIUM)
    	endfunction

    	// Called by write monitor
    	function void write(fifo_wr_item t);
        	trans = t;

        	// cg_write: sample fill_level PRE-increment.
        	// Captures fill_level=0 (empty) when a write arrives into an empty FIFO,
        	// and fill_level=DEPTH-1 (partial→full transition) for the 16th write,
        	// which the cross bin <*,full> requires via cg_write's own cp_fill_level.
        	// Note: cp_fill_level bin "full" = {DEPTH}. The 16th write arrives when
        	// fill=15 (partial), so <*,full> in cg_write is covered via the
        	// overflow scenario where we write into a full FIFO (fill stays at DEPTH).
        	// That is: after fill_drain, overflow does fill.start() then writes extra
        	// while full — those stalled writes arrive with fill_level=DEPTH still.
        	cg_write.sample();

        	// Increment counter (stalled writes don't increment past DEPTH).
        	if (fill_level < DEPTH) fill_level++;

        	// cg_flags: sample POST-increment so cp_full=1 fires when this
        	// write just made (or kept) the FIFO full, and cp_empty uses the
        	// current dut_empty state (which is only 1 after the last read drains).
        	dut_full  = (fill_level == DEPTH);
        	dut_empty = (fill_level == 0);   // can't be 1 after a write, but kept consistent
        	wr_stall  = dut_full;
        	cg_flags.sample();

        	`uvm_info("COV_WR",$sformatf("Sampled write: data=0x%02h fill_after=%0d full=%0b",t.data, fill_level, dut_full),UVM_HIGH)
    	endfunction

    	// Called by read monitor (only fires when r_valid=1)
    	function void write_rd(fifo_rd_item t);
        	rd_data = t.r_data;

        	// rd_stall inference: if fill_level==0 when a valid read completes,
        	// the driver must have stalled waiting for data (underflow scenario).
        	rd_stall = (fill_level == 0);

        	// cg_read: sample fill_level PRE-decrement.
        	// Captures fill_level=DEPTH (full) when the first read drains a full FIFO.
        	cg_read.sample();

        	// Decrement counter.
        	if (fill_level > 0) fill_level--;

        	// cg_flags: sample POST-decrement so cp_empty=1 fires when this
        	// read just drained the FIFO, and cp_full uses current dut_full
        	// (which is only 1 after the overflow fill, before any reads).
        	dut_empty = (fill_level == 0);
        	dut_full  = (fill_level == DEPTH);  // can't be 1 after a read, but kept consistent
        	cg_flags.sample();

        	`uvm_info("COV_RD",$sformatf("Sampled read:  data=0x%02h fill_after=%0d empty=%0b stall=%0b",t.r_data, fill_level, dut_empty, rd_stall),UVM_HIGH)
    	endfunction

	// Called by the reset test whenever wrst or rrst transitions.
    	// Samples cp_wrst and cp_rrst so both asserted and deasserted
    	// states are recorded in the coverage database.
    	function void sample_reset(bit wrst, bit rrst);
        	wrst_obs = wrst;
        	rrst_obs = rrst;
        	// Reset also clears the fill-level model
        	if (wrst || rrst) fill_level = 0;
        	cg_flags.sample();
        	`uvm_info("COV_RST",$sformatf("Reset sample: wrst=%0b rrst=%0b", wrst, rrst),UVM_HIGH)
    	endfunction

    	// Report coverage at end of simulation
    	function void report_phase(uvm_phase phase);
    		real overall;
        	integer cov_file;
        	
        	overall = (cg_write.get_coverage() +cg_read.get_coverage()  +cg_flags.get_coverage()) / 3.0;
    		cov_file = $fopen("logs/functional_coverage.log", "a");
    		$fdisplay(cov_file, "================================================");
    		$fdisplay(cov_file, "  FUNCTIONAL COVERAGE REPORT");
    		$fdisplay(cov_file, "  %0t", $time);
    		$fdisplay(cov_file, "================================================");
    		$fdisplay(cov_file, "  Write  coverage : %.1f%%", cg_write.get_coverage());
    		$fdisplay(cov_file, "  Read   coverage : %.1f%%", cg_read.get_coverage());
    		$fdisplay(cov_file, "  Flag   coverage : %.1f%%", cg_flags.get_coverage());
    		$fdisplay(cov_file, "------------------------------------------------");
    		$fdisplay(cov_file, "  Overall          : %.1f%%",(cg_write.get_coverage() +cg_read.get_coverage()  +cg_flags.get_coverage()) / 3.0);
    		$fdisplay(cov_file, "================================================");
    		$fclose(cov_file);
        	`uvm_info(get_type_name(),$sformatf("Write  coverage: %.1f%%", cg_write.get_coverage()),UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("Read   coverage: %.1f%%", cg_read.get_coverage()),UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("Flag   coverage: %.1f%%", cg_flags.get_coverage()),UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("Overall coverage: %.1f%%",overall),UVM_LOW)
    	endfunction

endclass
