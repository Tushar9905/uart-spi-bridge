`timescale 1ns/1ps

module tb_spi;

    localparam N = 8;

    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;

    reg        start = 0;
    reg  [7:0] mosi_data = 0;
    reg  [7:0] slave_tx = 0;
    wire [7:0] miso_data, slave_rx;
    wire       done, busy, sclk, mosi, miso, cs_n;

    spi_master #(.CLK_DIV(4)) dut (
        .clk(clk), .rst(rst), .start(start),
        .mosi_data_in(mosi_data), .miso_data_out(miso_data),
        .done(done), .busy(busy),
        .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n)
    );

    spi_slave_model slave (
        .rst(rst), .sclk(sclk), .cs_n(cs_n), .mosi(mosi), .miso(miso),
        .tx_byte(slave_tx), .rx_byte(slave_rx)
    );

    // values that are not bit-palindromes, so bit-order bugs show up
    reg [7:0] master_vec [0:N-1];
    reg [7:0] slave_vec  [0:N-1];
    integer   errors = 0, i;

    initial begin
        master_vec[0] = 8'h12; slave_vec[0] = 8'hC1;
        master_vec[1] = 8'h13; slave_vec[1] = 8'h83;
        master_vec[2] = 8'h80; slave_vec[2] = 8'h01;
        master_vec[3] = 8'h01; slave_vec[3] = 8'h80;
        master_vec[4] = 8'h00; slave_vec[4] = 8'hFF;
        master_vec[5] = 8'hFF; slave_vec[5] = 8'h00;
        master_vec[6] = 8'h6B; slave_vec[6] = 8'hD2;
        master_vec[7] = 8'hE7; slave_vec[7] = 8'h18;

        $dumpfile("tb_spi.vcd");
        $dumpvars(0, tb_spi);

        #50 rst = 0;
        #50;

        for (i = 0; i < N; i = i + 1) begin
            @(negedge clk);
            mosi_data = master_vec[i];
            slave_tx  = slave_vec[i];
            start     = 1;
            @(negedge clk);
            start     = 0;
            @(posedge done);
            @(negedge clk);
            if (miso_data !== slave_vec[i] || slave_rx !== master_vec[i]) begin
                $display("FAIL: xfer %0d: master got %h (exp %h), slave got %h (exp %h)",
                         i, miso_data, slave_vec[i], slave_rx, master_vec[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS: tb_spi");
        else             $display("FAIL: tb_spi, %0d error(s)", errors);
        $finish;
    end

endmodule
