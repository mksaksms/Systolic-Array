module PE #(
    parameter int DATAWIDTH  = 3, 
    
)(
    input  logic                             clk, 
    input  logic                             rst_n, 

    input  logic [DATAWIDTH - 1 : 0]         data_in_A, 
    input  logic [DATAWIDTH - 1 : 0]         data_in_B,

    // ADDED 'logic' keyword here
    output logic [(2 * DATAWIDTH) - 1 : 0]   data_out 
); 

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            data_out <= '0;  // Good practice: use '0 to fill all bits with zero
        end else begin 
            // CHANGED '=' to '<='
            data_out <= data_in_A * data_in_B; 
        end 
    end 

endmodule