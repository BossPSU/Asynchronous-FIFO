package async_fifo_package;

	parameter int DATA_WIDTH = 8;
	parameter int DEPTH = 16;  //2^N
	
	localparam int ADDR_WIDTH = $clog2(DEPTH); // address bits
	localparam int PTR_WIDTH = ADDR_WIDTH +1; //pointer bits (+1 wrap bit) //WIDTH = ADDR_WIDTH - 1
	
endpackage
