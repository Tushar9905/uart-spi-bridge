# uart-spi-bridge

A UART to SPI bridge in Verilog. Each byte received on the UART is sent to an
SPI slave, and the byte the slave returns is sent back over the UART.

```
PC --UART--> uart_rx --> uart_to_spi_bridge --> spi_master --SPI--> device
PC <-UART--- uart_tx <------------'
```

| Setting | Default |
|---|---|
| Clock | 10 MHz |
| UART | 115200 baud, 8N1 (`CLK_PER_BIT = 87`) |
| SPI | Mode 0, MSB first, SCLK = clk / 8 (`SPI_CLK_DIV = 4`) |

## Files

| File | Description |
|---|---|
| `rtl/uart_spi_bridge_top.v` | Top level |
| `rtl/uart_rx.v` | UART receiver with input synchronizer, glitch filter and framing-error detection |
| `rtl/uart_tx.v` | UART transmitter |
| `rtl/spi_master.v` | SPI master |
| `rtl/uart_to_spi_bridge.v` | Control FSM |
| `tb/spi_slave_model.v` | SPI slave model used by the testbenches |
| `tb/tb_uart.v`, `tb/tb_spi.v`, `tb/tb_bridge.v` | Self-checking testbenches |

## Running the tests

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/).

```sh
./run_tests.sh
```

Each testbench prints `PASS` or `FAIL`. Waveforms are written to `build/*.vcd`
and can be opened with GTKWave.

## Synthesis

```sh
vivado -mode batch -source syn/synth.tcl
```

Results with Vivado 2025.1 on an Artix-7 (`xc7a35tcpg236-1`), placed and routed:

| Clock | Slice LUTs | Flip-flops | WNS |
|---|---|---|---|
| 250 MHz | 103 | 135 | +0.248 ns |

Reports are written to `build/syn/`.
