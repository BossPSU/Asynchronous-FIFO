transcript file sim_transcript.log
transcript on

vlib work
vmap work work

# compile RTL
vlog -sv -work work \
	async_fifo_package.sv \
	sync_2ff.sv \
	dualport_mem.sv \
	async_fifo.sv

#compile UVM(Part A)
vlog -sv -work work +define+UVM_NO_DEPRECATED \
	fifo_uvm_package.sv

#PartC(compile + run UVM top tb)
#vlog -sv -work work +define+UVM_NO_DEPRECATED \
#	tb_async_fifo_uvm.sv

#vsim -c -voptargs=+acc work.tb_async_fifo_uvm
#run -all
#quit -f

quit -f

