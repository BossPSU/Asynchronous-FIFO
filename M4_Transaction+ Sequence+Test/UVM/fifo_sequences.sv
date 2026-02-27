//library of reusable seuquences

//single read/write request
//burst read/write requests
//write fill / read drain (fill/drain FIFO)
//fully randomized write stream

class wr_single_seq extends uvm_sequence #(fifo_wr_item);
    	`uvm_object_utils(wr_single_seq)

    	rand bit [DATA_WIDTH-1:0] data;

    	function new(string name = "wr_single_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_wr_item tr = fifo_wr_item::type_id::create("tr");
        	start_item(tr);
        	tr.data = data;
        	finish_item(tr);
        	`uvm_info("SEQ_WR_S", $sformatf("Single write: %s", tr.convert2string()), UVM_MEDIUM)
    	endtask
endclass

class wr_burst_seq extends uvm_sequence #(fifo_wr_item);
	int unsigned n =50;
	
	`uvm_object_utils(wr_burst_seq)

	function new(string name = "wr_burst_seq");
		super.new(name);
	endfunction

	virtual task body();
		fifo_wr_item tr;
		`uvm_info("SEQ_WR_B", $sformatf("Starting write burst of %0d items", n), UVM_LOW)
		
		for (int i =0; i < n; i++) begin
			tr = fifo_wr_item::type_id::create("tr");
			tr.data = i[DATA_WIDTH-1:0];  // directed: 0..n-1
			start_item(tr);
			finish_item(tr);

			`uvm_info("SEQ_WR_B", tr.convert2string(), UVM_HIGH)
		end
		
		`uvm_info("SEQ_WR_B", $sformatf("Write burst of %0d items complete", n), UVM_LOW)
            
	endtask
endclass

class wr_fill_seq extends uvm_sequence #(fifo_wr_item);

    	`uvm_object_utils(wr_fill_seq)

    	function new(string name = "wr_fill_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_wr_item tr;
        	`uvm_info("SEQ_FILL", $sformatf("Filling FIFO with %0d items", DEPTH), UVM_LOW)

        	for (int i = 0; i < DEPTH; i++) begin
            		tr = fifo_wr_item::type_id::create("tr");
            		tr.data = i[DATA_WIDTH-1:0];
            		start_item(tr);
            		finish_item(tr);
        	end

        	`uvm_info("SEQ_FILL", "Fill sequence complete", UVM_LOW)
    	endtask
endclass 

class wr_rand_seq extends uvm_sequence #(fifo_wr_item);

    	int unsigned n = 20;

    	`uvm_object_utils(wr_rand_seq)

    	function new(string name = "wr_rand_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_wr_item tr;
        	`uvm_info("SEQ_RAND_WR", $sformatf("Starting %0d random writes", n), UVM_LOW)

        	repeat (n) begin
            		tr = fifo_wr_item::type_id::create("tr");
            		start_item(tr);
            		if (!tr.randomize()) begin
                		`uvm_error("SEQ_RAND_WR", "Randomization failed for wr item")
            		end
           		finish_item(tr);
            		`uvm_info("SEQ_RAND_WR", tr.convert2string(), UVM_HIGH)
        	end

        	`uvm_info("SEQ_RAND_WR",$sformatf("%0d random writes complete", n), UVM_LOW)
    	endtask
endclass

class rd_single_seq extends uvm_sequence #(fifo_rd_item);
    	`uvm_object_utils(rd_single_seq)

    	function new(string name = "rd_single_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_rd_item tr = fifo_rd_item::type_id::create("tr");
        	start_item(tr);
        	finish_item(tr);
        	`uvm_info("SEQ_RD_S", "Single read issued", UVM_MEDIUM)
    	endtask
endclass

class rd_burst_seq extends uvm_sequence #(fifo_rd_item);
	int unsigned n =50;
	
	`uvm_object_utils(rd_burst_seq)

	function new(string name = "rd_burst_seq");
		super.new(name);
	endfunction

	virtual task body();
		fifo_rd_item tr;
		for (int i =0; i < n; i++) begin
			tr = fifo_rd_item::type_id::create("tr");
			
			start_item(tr);
			finish_item(tr);

			`uvm_info("SEQ_RD", tr.convert2string(), UVM_LOW)
		end
	endtask
endclass


class rd_drain_seq extends uvm_sequence #(fifo_rd_item);

    	`uvm_object_utils(rd_drain_seq)

    	function new(string name = "rd_drain_seq");
        	super.new(name);
    	endfunction

    	virtual task body();
        	fifo_rd_item tr;
        	`uvm_info("SEQ_DRAIN", $sformatf("Draining FIFO – %0d reads", DEPTH), UVM_LOW)

        	for (int i = 0; i < DEPTH; i++) begin
            		tr = fifo_rd_item::type_id::create("tr");
            		start_item(tr);
            		finish_item(tr);
        	end

        	`uvm_info("SEQ_DRAIN", "Drain sequence complete", UVM_LOW)
    	endtask
endclass
