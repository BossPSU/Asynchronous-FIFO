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

        	// Did we write when FIFO was empty, partially full, full?
        	cp_fill_level: coverpoint fill_level {
            		bins empty       = {0};
            		bins partial     = {[1 : DEPTH-1]};
            		bins full        = {DEPTH};
        	}

        	// Cross: did we write corner data values at corner fill levels?
        	cx_data_x_fill: cross cp_wr_data, cp_fill_level;

    	endgroup

    	// ── Read-side covergroup ─────────────────────────────────
    	covergroup cg_read;

        	cp_rd_data: coverpoint rd_data {
            		bins zero      = {8'h00};
            		bins ones      = {8'hFF};
            		bins low       = {[8'h01 : 8'h7F]};
            		bins high      = {[8'h80 : 8'hFE]};
        	}

        	cp_fill_at_read: coverpoint fill_level {
            		bins empty     = {0};
            		bins partial   = {[1 : DEPTH-1]};
            		bins full      = {DEPTH};
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
        	cx_full_x_empty: cross cp_full, cp_empty;

        	// Back-pressure: write attempted while full
        	cp_wr_stall: coverpoint wr_stall {
           		bins no_stall  = {0};
            		bins stalled   = {1};
        	}

        	// Read stall: read attempted while empty
        	cp_rd_stall: coverpoint rd_stall {
            		bins no_stall  = {0};
            		bins stalled   = {1};
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
        	if (fill_level < DEPTH) fill_level++;
        	dut_full  = (fill_level == DEPTH);
        	wr_stall  = dut_full;
        	cg_write.sample();
        	cg_flags.sample();

        	`uvm_info("COV_WR",$sformatf("Sampled write: data=0x%02h fill=%0d full=%0b",t.data, fill_level, dut_full),UVM_HIGH)
    	endfunction

    	// Called by read monitor
    	function void write_rd(fifo_rd_item t);
        	rd_data   = t.r_data;
        	if (fill_level > 0) fill_level--;
        	dut_empty = (fill_level == 0);
        	rd_stall  = !t.r_valid;
        	cg_read.sample();
        	cg_flags.sample();

        	`uvm_info("COV_RD",$sformatf("Sampled read:  data=0x%02h fill=%0d empty=%0b",t.r_data, fill_level, dut_empty),UVM_HIGH)
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
