module Master_self_checking_tb ();
    
    parameter IDLE = 3'b000;
    parameter CHK_CMD = 3'b001;
    parameter WRITE = 3'b010;
    parameter READ_ADD = 3'b011;
    parameter READ_DATA = 3'b100;


    reg clk;
    reg rst_n; // Active low asynchronous reset
    reg SS_n; // Slave Select
    reg MOSI; // Master-Out-Slave-In

    wire MISO_dut; // Master-In-Slave-Out


    integer i = 0;
    integer k = 0;
    reg [7:0] write_address_expected;
    reg [7:0] write_data_expected;

    // DUT instantiation
    SPI_Wrapper #(.IDLE(IDLE),.CHK_CMD(CHK_CMD),.WRITE(WRITE),.READ_ADD(READ_ADD),.READ_DATA(READ_DATA))
                dut (.clk(clk),.rst_n(rst_n),.MOSI(MOSI),.MISO(MISO_dut),.SS_n(SS_n));

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // For self checking read_address would be the same as write_address, and write_data would be saved to compare it with MISO outputs when data is read
    /* Since this testbench only covers a few different orders of the 4 operations,
    I have made another tb that completely randomizes the order of operation and whose validity can be checked in the wave simulation */
    
    initial begin
        // --------------------------------------- Reset -------------------------------------- //
        rst_n = 0; // active low
        #50;
        rst_n = 1;
        #100;

        for (i = 0; i<10000 ; i = i+1) begin
            // -------------------------------- Write Address -------------------------------- //
            // ----- Test: Write Address -----
            // SS_n = 0 to tell the SPI Slave that the master will begin communication
            @(negedge clk) SS_n = 0;
            // 0: write operation, 00: write address
            repeat(3) begin
                @(negedge clk);
                MOSI = 0;
            end
            // write address (8 bits)
            repeat(8) begin
            @(negedge clk)
            MOSI = $random;
                write_address_expected = {write_address_expected,MOSI}; 
            end
            // SS_n = 1 to end communication from master side
            @(negedge clk) SS_n = 1;

            // ---------------------------------- Write Data ---------------------------------- //
            // SS_n = 0 to tell the SPI Slave that the master will begin communication (common between both operations)
            @(negedge clk) SS_n = 0;
            // 0: write operation, 01: write data
            repeat(2) begin
                    @(negedge clk);
                    MOSI = 0;
                end
            @(negedge clk) MOSI = 1;

            // write data (8 bits)
            repeat(8) begin
                @(negedge clk)
                MOSI = $random;
                write_data_expected = {write_data_expected,MOSI};
            end
            // SS_n = 1 to end communication from master side (common between both operations)
            @(negedge clk) SS_n = 1;

            // ---------------------------------- Read Address ---------------------------------- //
            // Read address should be same as write address (so we can do self-checking)
            // SS_n = 0 to tell the SPI Slave that the master will begin communication
            @(negedge clk) SS_n = 0;
            // 1: read operation, 10: read address
            repeat(2) begin
                @(negedge clk);
                MOSI = 1;
            end
            @(negedge clk) MOSI = 0;
            // read address (8 bits)
            k = 0;
            repeat(8) begin
                @(negedge clk) MOSI = write_address_expected[7-k];
                k = k+1;
            end
            // SS_n = 1 to end communication from master side
            @(negedge clk) SS_n = 1;

            
            // ---------------------------------- Read Data ---------------------------------- //
            // SS_n = 0 to tell the SPI Slave that the master will begin communication (common between both operations)
            @(negedge clk) SS_n = 0;
            // 1: read operation, 11: read data
            repeat(3) begin
                    @(negedge clk);
                    MOSI = 1;
                end

            // ----- Need 8 extra cycles for dummy data + 1 cycle for memory retrieval -----
            repeat(9) @(negedge clk) MOSI = $random;
        
            // Self-Checking
            k = 0;
            repeat(8) begin
                @(negedge clk) MOSI = $random;
                if(write_data_expected[8-k] !== MISO_dut) begin
                    $display("Error in SPI");
                    $stop;
                end
                k = k+1;
            end

            // SS_n = 1 to end communication from master side (common between both operations)
            @(negedge clk) SS_n = 1;
        end

        #2 $stop;
        
    end



endmodule
