// ==============================================================================
// 2. The Systolic Array Core
// ==============================================================================
module systolic_array #(
    parameter int DATAWIDTH = 3,
    parameter int N         = 8    // Grid dimension (e.g., 8x8)
)(
    input  logic                                clk,
    input  logic                                rst_n,

    // Boundary Inputs (driven from data-skewing FIFOs in a wrapper)
    input  logic [DATAWIDTH - 1 : 0]            in_A [0 : N-1], 
    input  logic [DATAWIDTH - 1 : 0]            in_B [0 : N-1], 

    // Boundary Outputs (the final matrix product)
    output logic [(2 * DATAWIDTH) - 1 : 0]      out_sum [0 : N-1] 
);

    /* ==============================================================================
     * SYSTOLIC ARRAY COORDINATE AND MULTIPLICATION MAPPING
     * ==============================================================================
     * The 2D interconnect arrays form a physical mesh network between the PEs.
     * For an N x N grid of PEs, we need (N+1) wires in the direction of data flow 
     * to account for the boundary inputs (index 0) and final outputs (index N).
     *
     * Data Flow & Coordinate System [row][col]:
     * ------------------------------------------------------------------------------
     * - wire_A[r][c]   : Horizontal flow. Enters PE(r,c) from the left. 
     *                    Exits as wire_A[r][c+1] to the right.
     * - wire_B[r][c]   : Vertical flow. Enters PE(r,c) from the top.
     *                    Exits as wire_B[r+1][c] to the bottom.
     * - wire_sum[r][c] : Vertical flow. Enters PE(r,c) from the top.
     *                    Exits as wire_sum[r+1][c] to the bottom.
     *
     * PE(r,c) Boundary Box Visualization:
     * ------------------------------------------------------------------------------
     *                           (From Top PE)
     *                   wire_B[r][c], wire_sum[r][c]
     *                                 |
     *                                 V
     *                  +-----------------------------+
     * (From Left PE)   |          PE(r, c)           |  (To Right PE)
     * wire_A[r][c] --->|                             |---> wire_A[r][c+1]
     *                  | MAC: sum_out = sum_in + A*B |
     *                  +-----------------------------+
     *                                 |
     *                                 V
     *                  wire_B[r+1][c], wire_sum[r+1][c]
     *                           (To Bottom PE)
     *
     * The Multiplication Math at PE(r,c):
     * ------------------------------------------------------------------------------
     * On every clock cycle, PE(r,c) performs the following operation:
     *   1. Multiplies the Matrix A element (flowing right) by the Matrix B 
     *      element (flowing down).
     *   2. Adds this product to the running partial sum from the PE above it.
     *   3. Registers the new sum and the A/B elements, pushing them out to the 
     *      neighboring PEs (r+1 and c+1) on the next clock edge.
     *
     * RTL Equation execution: 
     * wire_sum[r+1][c] <= wire_sum[r][c] + (wire_A[r][c] * wire_B[r][c])
     * ==============================================================================
     */

    // -------------------------------------------------------------------------
    // 1. Interconnect Wires
    // -------------------------------------------------------------------------
    logic [DATAWIDTH - 1 : 0]       wire_A   [0 : N-1][0 : N];   
    logic [DATAWIDTH - 1 : 0]       wire_B   [0 : N][0 : N-1];   
    logic [(2 * DATAWIDTH) - 1 : 0] wire_sum [0 : N][0 : N-1];   

    genvar r, c;
    generate
        // -------------------------------------------------------------------------
        // 2. Drive the boundaries
        // -------------------------------------------------------------------------
        for (r = 0; r < N; r++) begin : edge_assigns
            assign wire_A[r][0]   = in_A[r];  
            assign wire_B[0][r]   = in_B[r];  
            assign wire_sum[0][r] = '0;       
        end

        // -------------------------------------------------------------------------
        // 3. Generate the PE Grid
        // -------------------------------------------------------------------------
        for (r = 0; r < N; r++) begin : row
            for (c = 0; c < N; c++) begin : col
                
                PE #(
                    .DATAWIDTH(DATAWIDTH)
                ) u_PE (
                    .clk       (clk),
                    .rst_n     (rst_n),
                    
                    .data_in_A (wire_A[r][c]),
                    .data_in_B (wire_B[r][c]),
                    .sum_in    (wire_sum[r][c]),
                    
                    .data_out_A(wire_A[r][c+1]),
                    .data_out_B(wire_B[r+1][c]),
                    .sum_out   (wire_sum[r+1][c])
                );
                
            end
        end

        // -------------------------------------------------------------------------
        // 4. Collect outputs
        // -------------------------------------------------------------------------
        for (c = 0; c < N; c++) begin : out_assigns
            assign out_sum[c] = wire_sum[N][c];
        end
    endgenerate

endmodule