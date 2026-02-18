import async_fifo_package::*;

module async_fifo#(
	parameter int DATA_WIDTH = 8,
	parameter int FIFO_DEPTH = 16 //2^N
)(
	//write domain
	input logic wclk, 
	input logic wrst,	// active-high async reset
	input logic w_valid,
	input logic [DATA_WIDTH-1:0] w_data,
	output logic w_ready,

	//read domian
	input logic rclk,
	input logic rrst,
	input logic r_ready,	// active-high async reset
	output logic r_valid,
	output logic [DATA_WIDTH-1:0] r_data,
	);

	//widths
	localparam int ADDR_WIDTH = $clog2(DEPTH);
	localparam int PTR_WIDTH = ADDR_WIDTH + 1;  // extra wrap bit use for empty/full
	
	//binary and grey pointers
	logic [PTR_WIDTH-1:0] wptr_bin, wptr_bin_next;
	logic [PTR_WIDTH-1:0] wptr_gray, wptr_gray_next;
	
	logic [PTR_WIDTH-1:0] rptr_bin,rptr_bin_next;
	logic [PTR_WIDTH-1:0] wptr_gray, rptr_gray_next;

	//synchronized gray pointers 2ff
	//logic [PTR_WIDTH-1:0] rgay_wclk; //rgray synced into wclk domain
	//logic [PTR_WIDTH-1:0] wgay_rclk; //wgray synced into rclk domain

	//synchronized gray pointers
	logic [PTR_WIDTH-1:0] rptr_gray_sync1, rptr_gray_sync;
	logic [PTR_WIDTH-1:0] wptr_gray_sync1, wptr_gray_sync;

	//flag 
	logic full, empty;

	//write/read signal
	assign w_ready = ~full;
	assign r_valid = ~empty;

	wire w_en = w_valid && w_ready;  // real write
	wire r_en  = r_valid && r_ready;  // real read

	//memory
	logic [DATA_WIDTH-1:0] men [0:DEPTH-1];

	// write memory
	always_ff @(posedge wclk) begin	
		if (write_en) begin
    		mem[wptr_bin[ADDR_WIDTH-1:0]] <= w_data;
		end
	end

	//read memory
	assign r_data = mem[rptr_bin[ADDR_WIDTH-1:0]];

	//bin to gray
	function automatic logic [PTR_WIDTH-1:0] bin2gray(input logic [PTR_WIDTH-1:0] b);
		bin2gray = (b >> 1) ^ b;
  	endfunction
	
	//increment write pointer when FIFO recives outside write signal and FIFO is not full
	always_ff @(posedge wclk or wrst) begin
		if (wrst) begin
			wptr_bin <='0;
		end else if (w_valid && w_ready) begin
			wptr_bin <= wptr_bin + 1'b1;
		end
	end

	//convert binary pointer to grey code, changing only 1 bit at a time
	assign wptr_gray = (wptr_bin >> 1) ^ wptr_bin;

	//increment read pointer when data exists and outside module is ready to recieve it
	always_ff @(posedge rclk or rrst begin
  		if (rrst) begin
    			rptr_bin <= '0;
  		end else if (r_valid && r_ready) begin
    			rptr_bin <= rptr_bin + 1'b1
    		end
	end
	
	//convert binary pointer to grey code, changing only 1 bit at a time
	assign rptr_gray = (rptr_bin >> 1) ^ rptr_bin;
	
	dualport_mem mem(
		.w_clk(wclk),
		.r_clk(rclk),
		.w_en(w_valid && w_ready),
		.r_en(r_valid && r_ready),
		.w_addr(wptr_bin[ADDR_WIDTH-1:0]),
		.r_addr(rptr_bin[ADDR_WIDTH-1:0]),
		.w_data(w_data),
		.r_data(r_data)
		);
	
	sync_2ff wptr_sync(
		.clk(wclk),
		.rst(wrst),
		.d(rptr_gray),
		.q(rptr_gray_wclk)
		);
		
	sync_2ff rptr_sync(
		.clk(rclk),
		.rst(rrst),
		.d(wptr_gray),
		.q(wptr_gray)
		);
		
	assign fifo_empty = (rptr_gray == wptr_gray);
	assign fifo_full = (wptr_gray == {~rptr_gray[ADDR_WIDTH:ADDR_WIDTH-1],rptr_gray[ADDR_WIDTH-2:0]});
endmodule
		


