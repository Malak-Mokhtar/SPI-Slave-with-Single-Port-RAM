module Master_tb ();

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

    // Used to randomize operation order
    reg order;
    reg read_or_write;

    integer i = 0;

    // DUT instantiation
    SPI_Slave #(.IDLE(IDLE),.CHK_CMD(CHK_CMD),.WRITE(WRITE),.READ_ADD(READ_ADD),.READ_DATA(READ_DATA))
                dut (.clk(clk),.rst_n(rst_n),.MOSI(MOSI),.MISO(MISO_dut),.SS_n(SS_n),.rx_data(),.rx_valid(),.tx_data(),.tx_valid());

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end
    

    initial begin
        rst_n = 0; // active low
        //MOSI = 0;
        //SS_n = 1;
        #50;
        rst_n = 1;
        #100;

        // -------------------------------------------------- Write Operations -------------------------------------------------- //
        // ------------------------- Initially Write Address ------------------------- //
        // ----- Test: Write Address -----
        // SS_n = 0 to tell the SPI Slave that the master will begin communication
        @(negedge clk) SS_n = 0;
        // 0: write operation, 00: write address
        repeat(3) begin
            @(negedge clk);
            MOSI = 0;
        end
        // write address (8 bits)
        repeat(8) @(negedge clk) MOSI = $random;
        // SS_n = 1 to end communication from master side
        @(negedge clk) SS_n = 1;

        // ----------------- Now randomize order of Writing data or Writing Addresses (using variable "order") ----------------- //
        for (i = 0; i<3000 ; i=i+1 ) begin

            // SS_n = 0 to tell the SPI Slave that the master will begin communication (common between both operations)
            @(negedge clk) SS_n = 0;

            // 0: write operation, 00: write address   OR   0: write operation, 01: write data
            // 0: write operation, 0: 1st bit of write operation type
            repeat(2) begin
                    @(negedge clk);
                    MOSI = 0;
                end

            // randomize variable "order"
            order = $random; // 1: Write data, 0: Write Address
            // 2nd bit of write operation type:
            if (order) begin
                // ----- Test: Write Data -----
                @(negedge clk) MOSI = 1;
            end
            else begin
                // ----- Test: Write Address -----
                @(negedge clk) MOSI = 0;
            end

            // write address/data (8 bits) (common between both operations)
            repeat(8) @(negedge clk) MOSI = $random;

            // SS_n = 1 to end communication from master side (common between both operations)
            @(negedge clk) SS_n = 1;
        end


        // -------------------------------------------------- Read Operations -------------------------------------------------- //
        // ------------------------- Initially Read Address ------------------------- //
        // ----- Test: Read Address -----
        // SS_n = 0 to tell the SPI Slave that the master will begin communication
        @(negedge clk) SS_n = 0;
        // 1: read operation, 10: read address
        repeat(2) begin
            @(negedge clk);
            MOSI = 1;
        end
        @(negedge clk) MOSI = 0;
        // read address (8 bits)
        repeat(8) @(negedge clk) MOSI = $random;
        // SS_n = 1 to end communication from master side
        @(negedge clk) SS_n = 1;

        // ----------------- Now randomize order of Reading data or Read Addresses (using variable "order") ----------------- //
        for (i = 0; i<3000 ; i=i+1 ) begin

            // SS_n = 0 to tell the SPI Slave that the master will begin communication (common between both operations)
            @(negedge clk) SS_n = 0;

            // 1: read operation, 10: read address   OR   1: read operation, 11: read data
            // 1: read operation, 1: 1st bit of read operation type
            repeat(2) begin
                    @(negedge clk);
                    MOSI = 1;
                end

            // randomize variable "order"
            order = $random; // 1: Read data, 0: Read Address
            // 2nd bit of read operation type:
            if (order) begin
                // ----- Test: Read Data -----
                // 1: read operation, 11: read data
                @(negedge clk) MOSI = 1;
                // ----- Need 8 extra cycles for dummy data + 1 cycle for memory retrieval -----
                repeat(9) @(negedge clk) MOSI = $random;
            end
            else begin
                // ----- Test: Read Address -----
                // 1: read operation, 10: read address
                @(negedge clk) MOSI = 0;
            end

            // read address or dummy data (8 bits) (common between both operations)
            repeat(8) @(negedge clk) MOSI = $random;

            // SS_n = 1 to end communication from master side (common between both operations)
            @(negedge clk) SS_n = 1;
        end

        // -------------------------------------------------- Random Operations -------------------------------------------------- //
        for (i = 0; i<3000 ; i=i+1 ) begin

            // SS_n = 0 to tell the SPI Slave that the master will begin communication (common between all operations)
            @(negedge clk) SS_n = 0;
            read_or_write = $random; // 0: write, 1: read

            if (read_or_write) begin // Read operations
                // 1: read operation, 10: read address   OR   1: read operation, 11: read data
                // 1: read operation, 1: 1st bit of read operation type
                repeat(2) begin
                        @(negedge clk);
                        MOSI = 1;
                    end

                // randomize variable "order"
                order = $random; // 1: Read data, 0: Read Address
                // 2nd bit of read operation type:
                if (order) begin
                    // ----- Test: Read Data -----
                    // 1: read operation, 11: read data
                    @(negedge clk) MOSI = 1;
                    // ----- Need 8 extra cycles for dummy data + 1 cycle for memory retrieval -----
                    repeat(9) @(negedge clk) MOSI = $random;
                end
                else begin
                    // ----- Test: Read Address -----
                    // 1: read operation, 10: read address
                    @(negedge clk) MOSI = 0;
                end

            end
            else begin // Write operations
                // 0: write operation, 00: write address   OR   0: write operation, 01: write data
                // 0: write operation, 0: 1st bit of write operation type
                repeat(2) begin
                        @(negedge clk);
                        MOSI = 0;
                    end

                // randomize variable "order"
                order = $random; // 1: Write data, 0: Write Address
                // 2nd bit of write operation type:
                if (order) begin
                    // ----- Test: Write Data -----
                    @(negedge clk) MOSI = 1;
                end
                else begin
                    // ----- Test: Write Address -----
                    @(negedge clk) MOSI = 0;
                end
            end

            // read address or dummy data or write address/data (8 bits) (common between all operations)
            repeat(8) @(negedge clk) MOSI = $random;

            // SS_n = 1 to end communication from master side (common between all operations)
            @(negedge clk) SS_n = 1;
        end

        #2 $stop;
    end

endmodule
