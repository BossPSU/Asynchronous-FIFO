transcript file sim_transcript.log
transcript on

vlib work
vmap work work

vlog -sv -work work -cover bcsf async_fifo_package.sv sync_2ff.sv dualport_mem.sv async_fifo.sv tb_async_fifo.sv

vsim -c -coverage work.tb_async_fifo

run -all

coverage save coverage/fifo.ucdb

quit -f

