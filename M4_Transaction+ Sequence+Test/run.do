transcript file sim_transcript.log
transcript on

vdel -all -lib work
vlib work
vmap work work

# ── RTL ──────────────────────────────────────────────────────
vlog -sv -cover bcestf -work work \
    RTL/async_fifo_package.sv \
    RTL/sync_2ff.sv \
    RTL/dualport_mem.sv \
    RTL/async_fifo.sv

# ── UVM Testbench ─────────────────────────────────────────────
vlog -sv -work work \
    +define+UVM_NO_DEPRECATED \
    +incdir+UVM \
    UVM/fifo_if.sv \
    UVM/fifo_uvm_package.sv \
    UVM/fifo_tb_top.sv 

# ── Run tests ─────────────────────────────────────────────
echo "========================================"
echo "RUNNING TESTS"
echo "========================================"

vsim -c -coverage -voptargs=+acc -onfinish stop work.fifo_tb_top \
    +UVM_TESTNAME=fifo_full_test \
    +UVM_VERBOSITY=UVM_MEDIUM \

run -all
coverage report -detail -cvg -directive -comments -output functional_coverage.txt
coverage report -detail -instance=/fifo_tb_top/* -output DUT_code_coverage.txt

pause
