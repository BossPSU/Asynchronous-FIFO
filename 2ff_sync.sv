import async_fifo_package::*;
module 2ff_sync(
	input logic clk, rst,
	input logic [WIDTH-1:0] q,
	output logic [WIDTH-1:0] d
	);
	
	logic [WIDTH-1:0] ff1, ff2;
	
	always_ff(@posedge clk or rst)begin
		if(rst)begin
			ff1 <= '0;
			ff2 <= '0;
		end else begin
			ff1 <= d;
			ff2 <= ff1;
		end
	end
	
	assign q = ff2;
	
endmodule	
