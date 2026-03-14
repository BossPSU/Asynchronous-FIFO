package fifo_uvm_package;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//From existing RTL
  	import async_fifo_package::*;
	
	typedef uvm_sequencer #(uvm_sequence_item) fifo_vseqr_t;
	
	`uvm_analysis_imp_decl(_rd)
  	`uvm_analysis_imp_decl(_wr)
  	
	`include "fifo_items.sv"
	`include "fifo_scoreboard.sv"
	`include "fifo_sequences.sv"
	`include "fifo_wr_driver.sv"
	`include "fifo_rd_driver.sv"
	`include "fifo_wr_monitor.sv"
    	`include "fifo_rd_monitor.sv"
    	`include "fifo_agents.sv"
    	`include "fifo_coverage.sv"
    	`include "fifo_env.sv"
	`include "fifo_tests.sv"

endpackage
