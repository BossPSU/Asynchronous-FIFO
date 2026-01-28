import async_fifo_package::*;
module async_fifo(
	input logic wclk,wrst,w_valid,rclk,rrst,r_ready,
	input logic [DATA_WIDTH-1:0] w_data,
	output logic w_ready,r_valid,
	output logic [DATA_WIDTH-1:0] r_data,
	);
	
	//binary and grey pointers
	logic [ADDR_WIDTH-1:0] wptr_bin, wptr_gray, rptr_bin, wptr_gray;
	logic fifo_empty, fifo_full;
	
	assign w_ready = ~fifo_full;
	
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
	
	2ff_sync wptr_sync(
		.clk(wclk),
		.rst(wrst),
		.d(rptr_gray),
		.q(rptr_gray_wclk)
		);
		
	2ff_sync rptr_sync(
		.clk(rclk),
		.rst(rrst),
		.d(wptr_gray),
		.q(wptr_gray)
		);
		
	assign fifo_empty = (rptr_gray == wptr_gray);
	assign fifo_full = (wptr_gray == {~rptr_gray[ADDR_WIDTH:ADDR_WIDTH-1],rptr_gray[ADDR_WIDTH-2:0]});
endmodule
		


