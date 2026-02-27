package fifo_uvm_package;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

	//From existing RTL
  	import async_fifo_package::*;
	
	`include "fifo_itmes.sv"
	`include "fifo_sequences.sv"
	`incldue "fifo_testes.sv"

endpackage
