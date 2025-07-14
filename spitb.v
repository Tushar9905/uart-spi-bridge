module spi_testbench;
    reg clk = 0;
    reg rst;
    reg start;
    reg [7:0] mosi_data;
    wire [7:0] miso_data;
    wire done;
    wire sclk, mosi, miso, cs;
    wire [7:0] slave_data_out;

    always #5 clk = ~clk;

    spi_master uut_master (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mosi_data_in(mosi_data),
        .miso_data_out(miso_data),
        .done(done),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

    spi_slave uut_slave (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs(cs),
        .data_out(slave_data_out)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, spi_testbench);

        rst = 1;
        start = 0;
        mosi_data = 8'h3C;
        #20 rst = 0;

        #20 start = 1;
        #10 start = 0;

        wait (done);
        #20;

        $display("[Master] Sent: %h", mosi_data);
        $display("[Master] Received: %h", miso_data);
        $display("[Slave] Received: %h", slave_data_out);
        $finish;
    end
endmodule
