// ── Checker module ────────────────────────────────────────────────────────────
// Instantiated inside async_fifo via bind.
// Ports are connected to DUT internals by name in the bind statement below.
//
module fifo_assertions #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    // Clocks and resets
    input logic rclk,
    input logic rrst,
    input logic wclk,
    input logic wrst,
 
    // Interface-visible signals
    input logic r_valid,
    input logic r_ready,
    input logic w_valid,
    input logic w_ready,
 
    // Internal DUT signals (not visible at fifo_if boundary)
    input logic [$clog2(DEPTH):0] rptr_gray,       // registered read Gray pointer
    input logic [$clog2(DEPTH):0] rptr_gray_next,  // combinational next read Gray pointer
    input logic [$clog2(DEPTH):0] wptr_gray_rclk,  // write Gray pointer synchronized into rclk domain
    input logic                   empty,            // registered empty flag
    input logic                   full              // registered full flag
);

    property p_r_valid_latency;
        @(posedge rclk) disable iff (rrst)
        (rptr_gray_next != wptr_gray_rclk) |-> ##[0:1] r_valid;
    endproperty
 
    assert_r_valid_latency: assert property (p_r_valid_latency)
    else $error(
        "[SVA FAIL] assert_r_valid_latency: r_valid did not assert within 1 rclk cycle. Cause: empty_next uses rptr_gray instead of rptr_gray_next. rptr_gray=0x%0h rptr_gray_next=0x%0h wptr_gray_rclk=0x%0h empty=%0b r_valid=%0b time=%0t",
        rptr_gray, rptr_gray_next, wptr_gray_rclk, empty, r_valid, $time
    );
    
    property p_r_valid_eq_not_empty;
        @(posedge rclk) disable iff (rrst)
        r_valid == ~empty;
    endproperty
 
    assert_r_valid_eq_not_empty: assert property (p_r_valid_eq_not_empty)
    else $error(
        "[SVA FAIL] assert_r_valid_eq_not_empty: r_valid(%0b) != ~empty(%0b) at time %0t",
        r_valid, empty, $time
    );
    
    property p_r_data_stable;
        @(posedge rclk) disable iff (rrst)
        (r_valid && !r_ready) |=> $stable(r_valid);
    endproperty
 
    assert_r_data_stable: assert property (p_r_data_stable)
    else $error(
        "[SVA FAIL] assert_r_data_stable: r_valid deasserted while r_ready was low (handshake violation) at time %0t",
        $time
    );
    
     property p_no_full_and_empty;
        @(posedge rclk) disable iff (rrst)
        !(full && empty);
    endproperty
 
    assert_no_full_and_empty: assert property (p_no_full_and_empty)
    else $error(
        "[SVA FAIL] assert_no_full_and_empty: full and empty both high — impossible for a correct FIFO. time=%0t",
        $time
    );
    
    
    property p_no_write_when_full;
        @(posedge wclk) disable iff (wrst)
        full |-> !w_valid || !w_ready;
    endproperty
 
    assert_no_write_when_full: assert property (p_no_write_when_full)
    else $error(
        "[SVA FAIL] assert_no_write_when_full: accepted write (w_valid && w_ready) while full=1 at time %0t",
        $time
    );
endmodule

// ── Bind statement ────────────────────────────────────────────────────────────
// Attaches fifo_assertions into every instance of async_fifo.
// DUT internal signals are connected by their exact names inside async_fifo.
bind async_fifo fifo_assertions #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH)
) u_fifo_assertions (
    // Clocks / resets
    .rclk           (rclk),
    .rrst           (rrst),
    .wclk           (wclk),
    .wrst           (wrst),
 
    // Interface-visible
    .r_valid        (r_valid),
    .r_ready        (r_ready),
    .w_valid        (w_valid),
    .w_ready        (w_ready),
 
    // Internal DUT signals — this is the power of bind:
    // these are inaccessible from fifo_if but fully visible here
    .rptr_gray      (rptr_gray),
    .rptr_gray_next (rptr_gray_next),
    .wptr_gray_rclk (wptr_gray_rclk),
    .empty          (empty),
    .full           (full)
);
