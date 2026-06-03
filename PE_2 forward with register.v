module PE #(
    parameter int DATAWIDTH  = 3, 
    
)(
    input  logic                             clk, 
    input  logic                             rst_n, 

    input  logic [DATAWIDTH - 1 : 0]         data_in_A, 
    input  logic [DATAWIDTH - 1 : 0]         data_in_B,

    // ADDED 'logic' keyword here
    input logic [(2 * DATAWIDTH) - 1 : 0]    sum , 
	
	
	output  logic [DATAWIDTH - 1 : 0]         data_out_A, 
    output  logic [DATAWIDTH - 1 : 0]         data_out_B,
	
	
	// Updated partial sum
    output logic [(2 * DATAWIDTH) - 1 : 0]   sum_out
	
); 


/* 

How the Data Flows
In a standard 2D systolic grid built from this module:

Horizontal Flow: data_out_A connects to the data_in_A of the PE to its immediate right.

Vertical Flow: data_out_B connects to the data_in_B of the PE immediately below it.

Summation: sum_out connects to the sum_in of the PE immediately below it (meaning the sum accumulates downwards alongside data_B).

*/ 

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            data_out_A <= '0;			// Good practice: use '0 to fill all bits with zero
			data_out_B <= '0;
		end else begin 
			data_out_A <= data_in_A ; // Pipelined and will be received in next 
			data_out_B <= data_in_B ; // Pipelined and will be received in next 			
            // CHANGED '=' to '<='
            sum_out <= sum in + ( data_in_A * data_in_B) ; 
        end 
    end 

endmodule