//write items
class fifo_wr_item extends uvm_sequence_item;
	
	rand bit [async_fifo_package::DATA_WIDTH-1:0] data;

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
	bit [async_fifo_package::DATA_WIDTH-1:0] r_data;
	bit r_valid;
	
	`uvm_object_utils_begin(fifo_rd_item)
		`uvm_field_int(r_data,  UVM_ALL_ON)
		`uvm_field_int(r_valid, UVM_ALL_ON)
	`uvm_object_utils_end
	
	function new(string name="fifo_rd_item");
		super.new(name);
	endfunction

	function string convert2string();
		return $sformatf("RD r_valid=%0b r_data=0x%02h (%0d)", r_valid, r_data, r_data);
	endfunction
	
endclass
