#!/usr/bin/env sh
# Runs all testbenches with Icarus Verilog. Waveforms go to build/*.vcd.

cd "$(dirname "$0")"
mkdir -p build

RTL="rtl/uart_tx.v rtl/uart_rx.v rtl/spi_master.v rtl/uart_to_spi_bridge.v rtl/uart_spi_bridge_top.v"
failed=0

for tb in tb_uart tb_spi tb_bridge; do
    iverilog -o build/$tb.vvp tb/$tb.v tb/spi_slave_model.v $RTL || { failed=1; continue; }
    out=$(cd build && vvp -n $tb.vvp | grep -v "VCD info")
    echo "$out"
    case "$out" in *PASS*) ;; *) failed=1 ;; esac
done

exit $failed
