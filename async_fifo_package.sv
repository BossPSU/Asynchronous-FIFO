package async_fifo_package;

	parameter int DATA_WIDTH = 32;
	parameter int DEPTH = 256;
	parameter int ADDR_WIDTH = $clog2(DEPTH); // address bits
	parameter int PTR_W = ADDR_W +1 //pointer bits (+1 wrap bit) //WIDTH = ADDR_WIDTH - 1
	
endpackage
