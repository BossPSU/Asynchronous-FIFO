package fifo_uvm_package;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//From existing RTL
  	import async_fifo_package::*;
	
	`include "fifo_items.sv"
	`include "fifo_sequences.sv"
	`include "fifo_wr_driver.sv"
	`include "fifo_rd_driver.sv"
	`include "fifo_wr_monitor.sv"
    	`include "fifo_rd_monitor.sv"
    	`include "fifo_agents.sv"
    	`include "fifo_scoreboard.sv"
    	`include "fifo_env.sv"
	`include "fifo_tests.sv"

endpackage
