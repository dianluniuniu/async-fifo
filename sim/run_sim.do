# ==============================================================================
# ModelSim Simulation Script for Async FIFO
# ==============================================================================

# Clean up previous work
if {[file exists work]} {
    vdel -lib work -all
}

# Create work library
vlib work
vmap work work

# Compile RTL files in dependency order
echo "Compiling RTL files..."
vlog -work work -sv +incdir+../rtl ../rtl/fifomem.sv
vlog -work work -sv +incdir+../rtl ../rtl/sync_r2w.sv
vlog -work work -sv +incdir+../rtl ../rtl/sync_w2r.sv
vlog -work work -sv +incdir+../rtl ../rtl/wptr_full.sv
vlog -work work -sv +incdir+../rtl ../rtl/rptr_empty.sv
vlog -work work -sv +incdir+../rtl ../rtl/async_fifo.sv

# Compile testbench
echo "Compiling testbench..."
vlog -work work -sv async_fifo_tb.sv

# Start simulation
echo "Starting simulation..."
vsim -voptargs=+acc work.async_fifo_tb

# Configure waveform window
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Add waves
echo "Adding waves..."

# Add dividers and waves for better organization
add wave -divider "Clock and Reset"
add wave -noupdate -color Yellow /async_fifo_tb/wclk
add wave -noupdate -color Yellow /async_fifo_tb/rclk
add wave -noupdate -color Red /async_fifo_tb/wrst_n
add wave -noupdate -color Red /async_fifo_tb/rrst_n

add wave -divider "Write Interface"
add wave -noupdate /async_fifo_tb/winc
add wave -noupdate -radix hexadecimal /async_fifo_tb/wdata
add wave -noupdate -color Orange /async_fifo_tb/wfull
add wave -noupdate -radix unsigned /async_fifo_tb/waddr

add wave -divider "Read Interface"
add wave -noupdate /async_fifo_tb/rinc
add wave -noupdate -radix hexadecimal /async_fifo_tb/rdata
add wave -noupdate -color Orange /async_fifo_tb/rempty
add wave -noupdate -radix unsigned /async_fifo_tb/raddr

add wave -divider "Internal Pointers (Gray Code)"
add wave -noupdate -radix binary /async_fifo_tb/dut/u_wptr_full/wptr_gray
add wave -noupdate -radix binary /async_fifo_tb/dut/u_rptr_empty/rptr_gray
add wave -noupdate -radix binary /async_fifo_tb/dut/u_wptr_full/rptr_gray_sync
add wave -noupdate -radix binary /async_fifo_tb/dut/u_rptr_empty/wptr_gray_sync

add wave -divider "Internal Pointers (Binary)"
add wave -noupdate -radix unsigned /async_fifo_tb/dut/u_wptr_full/wptr
add wave -noupdate -radix unsigned /async_fifo_tb/dut/u_rptr_empty/rptr

add wave -divider "Memory"
add wave -noupdate -radix hexadecimal /async_fifo_tb/dut/u_fifomem/mem

add wave -divider "Test Status"
add wave -noupdate -radix unsigned /async_fifo_tb/test_num
add wave -noupdate -radix unsigned /async_fifo_tb/error_count
add wave -noupdate -radix unsigned /async_fifo_tb/pass_count

# Set radix for buses
radix -hexadecimal

# Set time unit
property wave -radix unsigned /async_fifo_tb/test_num
property wave -radix unsigned /async_fifo_tb/error_count
property wave -radix unsigned /async_fifo_tb/pass_count

# Run simulation
echo "Running simulation..."
onfinish stop
run -all

# Zoom to fit
wave zoom full

echo ""
echo "===================================================================="
echo "Simulation Complete!"
echo "===================================================================="
echo "Check the transcript for test results."
echo "Use 'wave zoom full' to see the entire waveform."
echo "Use 'run -continue' to continue simulation if needed."
echo "===================================================================="
