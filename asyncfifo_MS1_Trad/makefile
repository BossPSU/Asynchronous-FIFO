
# ===== Questa Makefile =====

TOP = tb_async_fifo
WORK = work

VLIB = vlib
VMAP = vmap
VLOG = vlog
VSIM = vsim

# .sv files 
SRC = async_fifo_package.sv \
      two_ff_sync.sv \
      dualport_mem.sv \
      async_fifo.sv \
      tb_async_fifo.sv

all: run

# Create the work library 
lib:
	$(VLIB) $(WORK)
	$(VMAP) $(WORK) $(WORK)

compile: lib
	$(VLOG) -sv -work $(WORK) $(SRC)

run: compile
	$(VSIM) -c -work $(WORK) $(TOP) -do "run -all; quit -f"

clean:
	rm -rf $(WORK) transcript vsim.wlf *.wlf