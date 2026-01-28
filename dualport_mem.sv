import async_fifo_package::*;
module dualport_mem(
	input logic w_clk,r_clk,w_en,r_en,
	input logic [ADDR_WIDTH-1:0] w_addr,r_addr,
	input logic [DATA_WIDTH-1:0] w_data,
	output logic [DATA_WIDTH-1:0] r_data
	);

	//memory array
	logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];
	
	always_ff(@posedge w_clk) begin
		if (w_en) begin
			if (w_addr < DEPTH)
				mem[w_addr] <= w_data;
		end
	end

	always_ff(@posedge r_clk) begin
		if(r_en) begin
			if (r_addr < DEPTH)
				r_data <= mem[r_addr];
			else
				r_data <= '0;
		end
	end
	
endmodule
