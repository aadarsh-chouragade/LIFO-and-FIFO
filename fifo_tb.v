`timescale 1ns / 1ps
`include "fifo.v"
module fifo_tb;

    // Parameters
    parameter DEPTH = 8; // Depth of the FIFO

    // Inputs
    reg clk;
    reg reset;
    reg enq;
    reg deq;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;
    wire full;
    wire empty;

    // Instantiate FIFO module
    fifo fifo_inst (
        .clk(clk),
        .reset(reset),
        .enq(enq),
        .deq(deq),
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
        enq = 0;
        deq = 0;
        data_in = 8'h00;
        #20;
        reset = 0;
        #20;

        // Enqueue data into FIFO
        enq = 1;
        data_in = 8'h11;
        #10;
        enq = 0;
        #10;
        data_in = 8'h22;
        #10;
        data_in = 8'h33;
        #10;

        // Dequeue data from FIFO
        enq = 0;
        deq = 1;
        #10;
        deq = 0;
        #10;
        deq = 1;
        #10;
        deq = 0;
        #10;
        deq = 1;
        #10;
        deq = 0;
        #10;
    end

endmodule
