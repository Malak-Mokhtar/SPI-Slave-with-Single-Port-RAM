module SPI_Slave (
    clk,rst_n,MOSI,MISO,SS_n,rx_data,rx_valid,tx_data,tx_valid
);

    parameter IDLE = 3'b000;
    parameter CHK_CMD = 3'b001;
    parameter WRITE = 3'b010;
    parameter READ_ADD = 3'b011;
    parameter READ_DATA = 3'b100;


    input clk;
    input rst_n; // Active low asynchronous reset

    input MOSI; // Master-Out-Slave-In
    output reg MISO; // Master-In-Slave-Out

    input SS_n; // Slave Select

    output reg [9:0] rx_data; // Data sent to RAM
    output reg rx_valid;

    input [7:0] tx_data; // Data received from RAM
    input tx_valid;

    reg [2:0] cs,ns;

    reg [3:0] counter; // 4-bit counter for serial to parallel and vice versa conversions
    reg [7:0] tmp_reg; // to store data returned from RAM
    reg [1:0] read_operation; // 00: Write      01,11: Read
    reg tx_valid_tmp;
    // Is raised when the master has made the first read address operation. To ensure that we go to IDLE state in case master has NEVER made a Read address operation and wants to do a Read data operation
    reg read_address_provided;

    // RAM instantiation
    RAM my_ram (.din(rx_data),.clk(clk),.rst_n(rst_n),.rx_valid(rx_valid),.dout(tx_data),.tx_valid(tx_valid));


    // State memory
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cs <= IDLE;
            read_address_provided <= 0;
        end
        else
            cs <= ns;
    end

    // Next state logic
    always @(*) begin
        case (cs)
            IDLE:
                case (SS_n)
                    0 : begin
                        ns = CHK_CMD;
                        read_operation = 00;
                    end
                    default: ns = IDLE;
                endcase
            CHK_CMD:
                case ({SS_n,read_operation,MOSI})
                    // For write operation
                    4'b0_00_0: ns = WRITE;
                    // For read operations
                    4'b0_00_1: ns = CHK_CMD;
                    4'b0_01_1: ns = CHK_CMD;
                    4'b0_11_0: ns = READ_ADD;
                    4'b0_11_1: ns = READ_DATA;
                    default: ns = IDLE;
                endcase
            WRITE:
                case (SS_n)
                    0 : ns = WRITE; 
                    default: ns = IDLE;
                endcase
            READ_ADD: begin
                case (SS_n)
                    0 : ns = READ_ADD; 
                    default: ns = IDLE;
                endcase
                read_address_provided <= 1;
            end
            READ_DATA:
                case ({SS_n,read_address_provided}) // if Master had not provided a Read address before, then return to IDLE state
                    2'b01 : ns = READ_DATA; 
                    default: ns = IDLE;
                endcase
            default: ns = IDLE;
        endcase
    end

    // Output logic
    always @(posedge clk) begin
        if (cs == IDLE) begin
            counter <= 0;
            rx_valid <= 0;
            read_operation <= 0;
            tx_valid_tmp <= 0;
        end
        // to raise rx_valid only for 1 clk cycle when it is valid, and to zero the counter in case of READ_DATA after rx_valid has been raised:
        else if (rx_valid && (counter == 10)) begin
            rx_valid <= 0;
            counter <= 0;
        end
        else if (counter == 10)
                rx_valid <= 1;
        // Output on MISO if stored tx_valid is 1 and increment counter (since it has been zeroed) till tx_data is converted into serial out data on MISO port:
        else if (tx_valid_tmp) begin
            MISO <= tmp_reg[7-counter];
            counter <= counter + 1;
        end
        else begin
            counter <= counter + 1;
            // To determine which type of read operation (is checked in next state logic)
            read_operation <= {read_operation[0],MOSI};
        end

        // Shift register for the data to be sent from slave side
        if(SS_n == 0)
            rx_data <= {rx_data[8:0],MOSI};
        
        // Store tx_valid bit and output on MISO the most significant bit of tx_data received from RAM
        if(tx_valid && (cs == READ_DATA) && (counter == 0)) begin
            tmp_reg <= tx_data;
            tx_valid_tmp <= tx_valid;
            MISO <= tx_data[7];
        end

        // Only raise tx_valid_tmp for the 8 cycles that would output on MISO
        if(counter > 7)
            tx_valid_tmp <= 0;

    end

endmodule
