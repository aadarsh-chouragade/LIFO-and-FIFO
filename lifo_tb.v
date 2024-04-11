`timescale 1ns / 1ps

module lifo_tb;

    // Parameters
    parameter DEPTH = 8; // Depth of the LIFO

    // Inputs
    reg clk;
    reg reset;
    reg push;
    reg pop;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;
    wire full;
    wire empty;

    // Instantiate LIFO module
    lifo lifo_inst (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Clock generation
    always begin
        clk = 0;
        #5;
        clk = 1;
        #5;
    end

    // Test sequence
    initial begin
        // Reset
        reset = 1;
        push = 0;
        pop = 0;
        data_in = 8'h00;
        #20;
        reset = 0;
        #20;

        // Push data into LIFO
        push = 1;
        data_in = 8'h11;
        #10;
        push = 1;
        #10;
        data_in = 8'h22;
        #10;
        data_in = 8'h33;
        #10;

        // Pop data from LIFO
        push = 0;
        pop = 1;
        #10;
        pop = 0;
        #10;
        pop = 1;
        #10;
        pop = 0;
        #10;
        pop = 1;
        #10;
        pop = 0;
        #10;
    end

endmodule
