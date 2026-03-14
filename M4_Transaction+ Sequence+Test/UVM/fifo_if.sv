`timescale 1ns/1ps
import async_fifo_package::*;
interface fifo_if (

    	input logic wclk,
    	input logic rclk
);

    	// ---- Write domain ----
    	logic                  wrst;
    	logic                  w_valid;
    	logic [DATA_WIDTH-1:0] w_data;
    	logic                  w_ready;   // DUT output

    	// ---- Read domain ----
    	logic                  rrst;
    	logic                  r_ready;
    	logic                  r_valid;   // DUT output
    	logic [DATA_WIDTH-1:0] r_data;    // DUT output

    	// -------------------------------------------------------
    	// Write-side clocking block (driver perspective)
    	// -------------------------------------------------------
    	clocking wr_cb @(posedge wclk);
        	default input  #1step;
        	default output #1;
        	output wrst;
        	output w_valid;
        	output w_data;
        	input  w_ready;
    	endclocking

    	// -------------------------------------------------------
    	// Read-side clocking block (driver perspective)
    	// -------------------------------------------------------
    	clocking rd_cb @(posedge rclk);
        	default input  #1step;
        	default output #1;
        	output rrst;
        	output r_ready;
        	input  r_valid;
        	input  r_data;
    	endclocking

    	// -------------------------------------------------------
    	// Monitor clocking blocks (purely observational)
    	// -------------------------------------------------------
    	clocking wr_mon_cb @(posedge wclk);
        	default input #1step;
        	input w_valid;
        	input w_data;
        	input w_ready;
        	input wrst;
    	endclocking

    	clocking rd_mon_cb @(posedge rclk);
        	default input #1step;
        	input r_ready;
        	input r_valid;
        	input r_data;
        	input rrst;
    	endclocking

    	// -------------------------------------------------------
    	// Modports
    	// -------------------------------------------------------
    	modport wr_drv_mp  (clocking wr_cb,  input wclk);
    	modport rd_drv_mp  (clocking rd_cb,  input rclk);
    	modport wr_mon_mp  (clocking wr_mon_cb, input wclk);
    	modport rd_mon_mp  (clocking rd_mon_cb, input rclk);

	// ── ia_r_valid_stable_during_stall ───────────────────────
    	// Once r_valid asserts it must not drop until r_ready accepts.
    	property ia_r_valid_stable_during_stall;
    	    @(posedge rclk) disable iff (rrst)
    	    (r_valid && !r_ready) |=> r_valid;
    	endproperty
 
    	assert_r_valid_stable: assert property (ia_r_valid_stable_during_stall)
    	else $error("[IF SVA FAIL] r_valid dropped before r_ready accepted. time=%0t", $time);
 
    	// ── ia_no_r_valid_when_reset ──────────────────────────────
    	property ia_no_r_valid_when_reset;
    	    @(posedge rclk) rrst |-> !r_valid;
    	endproperty
 
    	assert_no_r_valid_in_reset: assert property (ia_no_r_valid_when_reset)
    	else $error("[IF SVA FAIL] r_valid asserted during rrst. time=%0t", $time);
 
    	// ── ia_full_clear_in_reset ────────────────────────────────
    	// full resets to 0, so w_ready (=~full) must be 1 during wrst.
    	property ia_full_clear_in_reset;
    	    @(posedge wclk) wrst |-> w_ready;
    	endproperty
 
    	assert_full_clear_in_reset: assert property (ia_full_clear_in_reset)
    	else $error("[IF SVA FAIL] w_ready=0 (full=1) while wrst active. time=%0t", $time);

endinterface 
