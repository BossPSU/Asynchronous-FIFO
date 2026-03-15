// ============================================================
// fifo_scoreboard.sv  –  UVM Scoreboard
// ============================================================
// Implements two uvm_analysis_imp ports:
//   write_wr_ap  – receives writes observed on the write side
//   write_rd_ap  – receives reads  observed on the read  side
//
// Maintains a shadow queue that mirrors the expected FIFO state.
// On every observed read, pops the shadow queue and compares the
// expected data against the actual r_data from the DUT.
//
// UVM messaging levels:
//   UVM_LOW    – pass/fail results, final summary
//   UVM_MEDIUM – per-transaction comparisons
//   UVM_HIGH   – shadow queue depth updates, debug info
// ============================================================

class fifo_scoreboard extends uvm_scoreboard;

    	`uvm_component_utils(fifo_scoreboard)

    	// Analysis imp ports (one per domain)
    	uvm_analysis_imp_wr #(fifo_wr_item, fifo_scoreboard) wr_ap;
    	uvm_analysis_imp_rd #(fifo_rd_item, fifo_scoreboard) rd_ap;

    	// Shadow FIFO queue (expected data in-order)
    	fifo_wr_item shadow_q[$];

    	// Counters
    	int unsigned wr_count;
    	int unsigned rd_count;
    	int unsigned pass_count;
    	int unsigned fail_count;
    	int unsigned underflow_count;  // read attempted on empty shadow queue

    	function new(string name = "fifo_scoreboard", uvm_component parent = null);
        	super.new(name, parent);
        	wr_count       = 0;
        	rd_count       = 0;
        	pass_count     = 0;
        	fail_count     = 0;
        	underflow_count = 0;
    	endfunction

    	// ----------------------------------------------------------
    	// build_phase
    	// ----------------------------------------------------------
    	function void build_phase(uvm_phase phase);
        	super.build_phase(phase);
        	wr_ap = new("wr_ap", this);
        	rd_ap = new("rd_ap", this);
        	`uvm_info(get_type_name(), "Scoreboard build_phase complete", UVM_MEDIUM)
    	endfunction

    	// ----------------------------------------------------------
    	// write_wr: called by write-side monitor for each accepted write
    	// ----------------------------------------------------------
    	function void write_wr(fifo_wr_item tr);
        	shadow_q.push_back(tr);
        	wr_count++;

        	`uvm_info("SB_WR",$sformatf("[%0t] Shadow push: %s  depth=%0d",$time, tr.convert2string(), shadow_q.size()),UVM_HIGH)
    	endfunction

    	// ----------------------------------------------------------
    	// write_rd: called by read-side monitor for each accepted read
    	// ----------------------------------------------------------
    	function void write_rd(fifo_rd_item rd_tr);
        	fifo_wr_item exp_tr;
        	rd_count++;

        	// Underflow guard
        	if (shadow_q.size() == 0) begin
            		underflow_count++;
            		`uvm_error("SB_UFLOW",$sformatf("[%0t] Read observed but shadow queue is empty! rd#%0d",$time, rd_count))
            		return;
        	end

        	exp_tr = shadow_q.pop_front();

        	// Data comparison
        	if (rd_tr.r_data === exp_tr.data) begin
            		pass_count++;
            		`uvm_info("SB_PASS",$sformatf("[%0t] PASS rd#%0d  exp=0x%02h  got=0x%02h",$time, rd_count, exp_tr.data, rd_tr.r_data),UVM_MEDIUM)
        	end else begin
            		fail_count++;
            		`uvm_error("SB_FAIL",$sformatf("[%0t] FAIL rd#%0d  exp=0x%02h  got=0x%02h  MISMATCH!",$time, rd_count, exp_tr.data, rd_tr.r_data))
        	end

        	`uvm_info("SB_RD",$sformatf("[%0t] Shadow pop: shadow_depth=%0d",$time, shadow_q.size()),UVM_HIGH)
    	endfunction

    	// ----------------------------------------------------------
    	// check_phase: report any leftover items in shadow queue
    	// ----------------------------------------------------------
    	function void check_phase(uvm_phase phase);
        	if (shadow_q.size() != 0) begin
			`uvm_error("SB_LEAK",$sformatf("%0d unread item(s) remain in shadow queue at end of test!",shadow_q.size()))
            		foreach (shadow_q[i]) begin
                		`uvm_info("SB_LEAK",$sformatf("  Leftover[%0d]: %s", i, shadow_q[i].convert2string()),UVM_LOW)
            		end
        	end else begin
            		`uvm_info(get_type_name(),"Shadow queue is empty at end of test – all writes were read back",UVM_LOW)
        	end
    	endfunction

    	// ----------------------------------------------------------
    	// report_phase: final summary
    	// ----------------------------------------------------------
    	function void report_phase(uvm_phase phase);
        	string sep = "============================================================";
        	`uvm_info(get_type_name(), sep, UVM_LOW)
        	`uvm_info(get_type_name(), "  SCOREBOARD SUMMARY", UVM_LOW)
        	`uvm_info(get_type_name(), sep, UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("  Writes observed  : %0d", wr_count),       UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("  Reads  observed  : %0d", rd_count),       UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("  PASSes           : %0d", pass_count),     UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("  FAILs            : %0d", fail_count),     UVM_LOW)
        	`uvm_info(get_type_name(),$sformatf("  Underflows       : %0d", underflow_count),UVM_LOW)
        	`uvm_info(get_type_name(), sep, UVM_LOW)

        	if (fail_count == 0 && underflow_count == 0 && shadow_q.size() == 0)
            		`uvm_info(get_type_name(), "  ** TEST PASSED **", UVM_LOW)
        	else
            		`uvm_error(get_type_name(), "  ** TEST FAILED – see errors above **")

        	`uvm_info(get_type_name(), sep, UVM_LOW)
    	endfunction

endclass 
