import async_fifo_package::*;

module dualport_mem(
	parameter int DATA_WIDTH = 8,
	parameter int DEPTH = 16   // 2^N
)(
	//write port
	input logic w_clk,
	input logic w_en,
	input  logic [$clog2(DEPTH)-1:0] w_addr,
	input logic [DATA_WIDTH-1:0] w_data,

	//read port(show-head)
	input  logic [$clog2(DEPTH)-1:0] r_addr,
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

  //combinational read
	always_comb begin
		r_data = mem[r_addr];
	end
	
endmodule
