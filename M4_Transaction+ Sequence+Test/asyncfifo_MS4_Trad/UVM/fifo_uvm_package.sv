package fifo_uvm_package;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//From existing RTL
  	import async_fifo_package::*;
	
	`include "fifo_items.sv"
	`include "fifo_sequences.sv"
	`include "fifo_tests.sv"

endpackage
