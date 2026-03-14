// ============================================================
// fifo_tb_top.sv  –  Top-Level Testbench Module
// ============================================================
// Instantiates:
//   - Clock and reset generators for write & read domains
//   - fifo_if interface
//   - DUT: async_fifo
//   - Configures UVM config_db and runs the test
// ============================================================

`timescale 1ns/1ps

// Bring in RTL parameters and UVM package
import async_fifo_package::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
import fifo_uvm_package::*;

module fifo_tb_top;

    	// -------------------------------------------------------
    	// Parameters
    	// -------------------------------------------------------
    	localparam int DW = DATA_WIDTH;   // from async_fifo_package
    	localparam int DP = DEPTH;

    	// -------------------------------------------------------
    	// Clocks
    	//   wclk: 100 MHz  (10 ns period)
    	//   rclk:  75 MHz  (13.33 ns period)  – asynchronous to wclk
    	// -------------------------------------------------------
    	logic wclk = 0;
    	logic rclk = 0;
	
    	always #5.0  wclk = ~wclk;   // 100 MHz
    	always #6.67 rclk = ~rclk;   //  75 MHz
	
    	// -------------------------------------------------------
    	// Interface instantiation
    	// -------------------------------------------------------
    	fifo_if if0 (.wclk(wclk), .rclk(rclk));
	
    	// -------------------------------------------------------
    	// DUT instantiation
    	// -------------------------------------------------------
    	async_fifo dut (
    	    // Write domain
    	    .wclk    (if0.wclk),
    	    .wrst    (if0.wrst),
    	    .w_valid (if0.w_valid),
    	    .w_data  (if0.w_data),
    	    .w_ready (if0.w_ready),
    	    // Read domain
    	    .rclk    (if0.rclk),
    	    .rrst    (if0.rrst),
    	    .r_ready (if0.r_ready),
    	    .r_valid (if0.r_valid),
    	    .r_data  (if0.r_data)
    	);
	
    	// -------------------------------------------------------
    	// Reset generation
    	// -------------------------------------------------------
    	initial begin
    	    if0.wrst    = 1'b1;
    	    if0.rrst    = 1'b1;
    	    if0.w_valid = 1'b0;
    	    if0.w_data  = '0;
    	    if0.r_ready = 1'b0;
	
    	    // Hold reset for 5 write clocks / 5 read clocks
    	    repeat (5) @(posedge wclk);
    	    if0.wrst = 1'b0;
	
    	    repeat (5) @(posedge rclk);
    	    if0.rrst = 1'b0;
	
    	    `uvm_info("TB_TOP", "Reset released on both domains", UVM_LOW)
    	end
	
    	// -------------------------------------------------------
    	// UVM configuration and run
    	// -------------------------------------------------------
    	initial begin
    	    // Publish interface to config_db so all components can get it
    	    uvm_config_db #(virtual fifo_if)::set(null, "uvm_test_top",   "fifo_vif", if0);
	    uvm_config_db #(virtual fifo_if)::set(null, "uvm_test_top.*", "fifo_vif", if0);
	
    	    // Optional: set default test name via plusarg (+UVM_TESTNAME=fifo_smoke_test)
    	    run_test();
    	end
	
    	// -------------------------------------------------------
    	// Simulation timeout watchdog
    	// -------------------------------------------------------
    	initial begin
    	    #100_000_000;
    	    `uvm_fatal("TIMEOUT", "Simulation timeout – check for hung sequences")
    	end
	
    	// -------------------------------------------------------
    	// Waveform dump (comment out for batch regression runs)
    	// -------------------------------------------------------
    	initial begin
    	    $dumpfile("fifo_tb.vcd");
    	    $dumpvars(0, fifo_tb_top);
    	end
	
endmodule
