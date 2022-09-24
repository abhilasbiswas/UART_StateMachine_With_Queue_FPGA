vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm

vlog -work xil_defaultlib -64 -incr -sv "+incdir+../../../../UART_Com.srcs/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../UART_Com.srcs/sources_1/ip/vio_0/hdl" "+incdir+../../../../UART_Com.srcs/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../UART_Com.srcs/sources_1/ip/vio_0/hdl" \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../UART_Com.srcs/sources_1/ip/vio_0/sim/vio_0.vhd" \

vlog -work xil_defaultlib \
"glbl.v"
