transcript file sim_transcript.log
transcript on

vdel -all -lib work
vlib work
vmap work work

# ── RTL ──────────────────────────────────────────────────────
vlog -sv -work work \
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

# ── Run all tests ─────────────────────────────────────────────
foreach test {
    fifo_smoke_test
    fifo_fill_drain_test
    fifo_overflow_test
    fifo_underflow_test
    fifo_rand_test
    fifo_concurrent_test
} {
    echo "========================================"
    echo "RUNNING: $test"
    echo "========================================"

    vsim -c -voptargs=+acc -onfinish stop work.fifo_tb_top \
        +UVM_TESTNAME=$test \
        +UVM_VERBOSITY=UVM_MEDIUM \
        -l logs/${test}.log

    run -all
    quit -sim
}

quit -f
