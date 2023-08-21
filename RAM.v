module RAM (
    din,clk,rst_n,rx_valid,dout,tx_valid
);
    
    parameter MEM_DEPTH = 256;
    parameter ADDR_SIZE = 8;

    input [9:0] din; // Data Input
    input clk;
    input rst_n; // Active low asynchronous reset
    input rx_valid;

    output reg [7:0] dout; // Data Output
    output reg tx_valid; // Whenever the command is memory read the tx_valid should be HIGH

    reg [ADDR_SIZE-1:0] mem [MEM_DEPTH-1:0];
    reg [ADDR_SIZE-1:0] write_address;
    reg [ADDR_SIZE-1:0] read_address;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
            tx_valid <= 0;
            write_address <= 0;
            read_address <= 0;
        end
        else if (rx_valid) begin
            case (din[9])
                0: // Write commands
                    begin
                        case (din[8])
                            0: // Write address
                                begin
                                    write_address <= din[7:0];
                                    tx_valid <= 0; 
                                end
                            1: // Write data
                                begin
                                    mem[write_address] <= din[7:0];
                                    tx_valid <= 0;
                                end
                        endcase
                    end
                1: // Read commands
                    begin
                        case (din[8])
                            0: // Read address
                                begin
                                   read_address <= din[7:0];
                                   tx_valid <= 0; 
                                end
                            1: // Read Data
                                begin
                                    dout <= mem[read_address];
                                    tx_valid <= 1;
                                end
                        endcase
                    end
            endcase
        end
    end

endmodule

