//write items
class fifo_wr_item extends uvm_sequence_item;
	
	rand bit [DATA_WIDTH-1:0] data;

	`uvm_object_utils_begin(fifo_wr_item)
 		`uvm_field_int(data, UVM_ALL_ON) //take advantage of field macros
	`uvm_object_utils_end

	function new(string name="fifo_wr_item");
		super.new(name);
	endfunction

	function string convert2string();
		return $sformatf("WR data=0x%0h (%0d)", data, data);
	endfunction
endclass

//read items
class fifo_rd_item extends uvm_sequence_item;

	`uvm_object_utils(fifo_rd_item)

	function new(string name="fifo_rd_item");
		super.new(name);
	endfunction

	function string convert2string();
		return "RD";
	endfunction
endclass