module SPI_Wrapper (
    clk,rst_n,MOSI,MISO,SS_n
);

    parameter IDLE = 3'b000;
    parameter CHK_CMD = 3'b001;
    parameter WRITE = 3'b010;
    parameter READ_ADD = 3'b011;
    parameter READ_DATA = 3'b100;

    input clk,rst_n,MOSI,SS_n;
    output MISO;

    wire [9:0] rx_data; // Data sent to RAM
    wire rx_valid;

    wire [7:0] tx_data; // Data received from RAM
    wire tx_valid;

    // SPI Slave instantiation
    SPI_Slave #(.IDLE(IDLE),.CHK_CMD(CHK_CMD),.WRITE(WRITE),.READ_ADD(READ_ADD),.READ_DATA(READ_DATA))
                dut (.clk(clk),.rst_n(rst_n),.MOSI(MOSI),.MISO(MISO),.SS_n(SS_n),.rx_data(rx_data),.rx_valid(rx_valid),.tx_data(tx_data),.tx_valid(tx_valid));

    // RAM instantiation
    RAM my_ram (.din(rx_data),.clk(clk),.rst_n(rst_n),.rx_valid(rx_valid),.dout(tx_data),.tx_valid(tx_valid));

endmodule
