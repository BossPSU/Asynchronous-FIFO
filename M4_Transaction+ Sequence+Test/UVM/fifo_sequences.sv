//generator: write 0..N-1, and read N times
//to write 2 sequences: wr_burst_seq, rd_burst_seq

class wr_burst_seq extends uvm_sequence #(fifo_wr_item);
	int unsigned n =50;
	
	`uvm_object_utils(wr_burst_seq)

	function new(string name = "wr_burst_seq");
		super.new(name);
	endfunction

	virtual task body();
		fifo_wr_item tr;
		for (int i =0; i < n; i++) begin
			tr = fifo_wr_item::type_id::create("tr");
			tr.data = i[DATA_WIDTH-1:0]  // directed: 0..n-1
			start _item(tr);
			finish_item(tr);

			`uvm_info("SEQ_WR", tr.convert2string(), UVM_LOW)
		end
	endtask
endclass

class wr_burst_seq extends uvm_sequence #(fifo_rd_item);
	int unsigned n =50;
	
	`uvm_object_utils(rd_burst_seq)

	function new(string name = "rd_burst_seq");
		super.new(name);
	endfunction

	virtual task body();
		fifo_rd_item tr;
		for (int I =0; i < n; i++) begin
			tr = fifo_rd_item::type_id::create("tr");
			start _item(tr);
			finish_item(tr);

			`uvm_info("SEQ_RD", tr.convert2string(), UVM_LOW)
		end
	endtask
endclass

