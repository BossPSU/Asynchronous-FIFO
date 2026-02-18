import async_fifo_package::*;

module dualport_mem(
	input logic w_clk,
	input logic w_en,
	input logic [ADDR_WIDTH-1:0] w_addr,
	input logic [DATA_WIDTH-1:0] w_data,
	
	input logic r_clk,
	input logic r_en,
	input logic [ADDR_WIDTH-1:0] r_addr,
	output logic [DATA_WIDTH-1:0] r_data
	);

	//memory array
	logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	//write port wclk
	always_ff @(posedge w_clk) begin
		if (w_en) begin
			mem[w_addr] <= w_data;
		end
	end

	//read port 
	always_ff @(posedge r_clk) begin
		if(r_en) begin
			r_data <= mem[r_addr];
		end
	end
	
endmodule
