import async_fifo_package::*;

module sync_2ff#(  //A module name like 2ff_sync is illegal in SystemVerilog (identifiers cannot start with a digit).
	parameter int WIDTH = 1
)(
	input logic clk,
	input logic rst,
	input logic [WIDTH-1:0] d,
	output logic [WIDTH-1:0] q
	);
	
	logic [WIDTH-1:0] ff1, ff2;
	
	always_ff@ (posedge clk or posedge rst) begin
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


//In digital design, a D flip-flop has:
//D = data input (the value you want to capture)
//Q = output (the stored/captured value)
