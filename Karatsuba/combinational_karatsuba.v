module binary_adder #(parameter N = 4) (X, Y, Z);
    input [N-1:0] X, Y;
    output [N:0] Z;
    wire [N:0] carry;
    generate
        genvar i;
        assign carry[0]=0;
        for (i = 0; i < N; i = i + 1) begin
            assign Z[i] = X[i] ^ (Y[i]) ^ carry[i];
            assign carry[i+1] = ((X[i] & Y[i])|(X[i] & carry[i])|(Y[i] & carry[i]));
        end
        assign Z[N] = carry[N];
    endgenerate
endmodule

module binary_adder_with_carry #(parameter N = 4) (X, Y, Z, input_carry);
    input [N-1:0] X, Y;
    input input_carry;
    output [N:0] Z;
    wire [N:0] carry;
    generate
        genvar i;
        assign carry[0]=input_carry;
        for (i = 0; i < N; i = i + 1) begin
            assign Z[i] = X[i] ^ (Y[i]) ^ carry[i];
            assign carry[i+1] = ((X[i] & Y[i])|(X[i] & carry[i])|(Y[i] & carry[i]));
        end
        assign Z[N] = carry[N];
    endgenerate
endmodule

module binary_subtractor #(parameter N = 4) (X, Y, Z);
    input [N-1:0] X, Y;
    output [N-1:0] Z;
    wire [N:0] carry;
    generate
        genvar i;
        assign carry[0]=1;
        for (i = 0; i < N; i = i + 1) begin
            assign Z[i] = X[i] ^ ~Y[i] ^ carry[i];
            assign carry[i+1] = (X[i] & ~Y[i])|(X[i] & carry[i])|(~Y[i] & carry[i]);
        end
    endgenerate
endmodule

module karatsuba_2 (X, Y, Z);
    input[1:0] X, Y;
    output[3:0] Z;
    wire P0;
    assign P0=X[1]&Y[1];
    assign Z[0]=X[0]&Y[0];
    assign Z[3]=P0&Z[0];
    assign Z[1]=~Z[3]&((X[1]&Y[0])|(X[0]&Y[1]));  
    assign Z[2]=~Z[3]&P0;
endmodule

module karatsuba_4 (X, Y, Z);
    input [3:0] X, Y;
    output [7:0] Z;
    wire [3:0] P2;
    wire [1:0] P0;
    karatsuba_2 k1 (.X(X[1:0]), .Y(Y[1:0]), .Z({P0, Z[1:0]}));
    karatsuba_2 k2 (.X(X[3:2]), .Y(Y[3:2]), .Z(P2));
    wire [4:0] P0_plus_P2;
    binary_adder #(.N(4)) adder (.X({P0, Z[1:0]}), .Y(P2), .Z(P0_plus_P2));
    wire [2:0] sum1, sum2;    
    binary_adder #(.N(2)) sum1_adder(.X(X[1:0]), .Y(X[3:2]), .Z(sum1));
    binary_adder #(.N(2)) sum2_adder(.X(Y[1:0]), .Y(Y[3:2]), .Z(sum2));
    wire [3:0] P1;
    karatsuba_2 k3 (.X(sum1[1:0]), .Y(sum2[1:0]), .Z(P1[3:0]));
    wire [3:0] to_be_added;
    wire [1:0] enabled_sum1, enabled_sum2;
    assign enabled_sum1[1]=sum2[2]&sum1[1];
    assign enabled_sum1[0]=sum2[2]&sum1[0];
    assign enabled_sum2[1]=sum1[2]&sum2[1];
    assign enabled_sum2[0]=sum1[2]&sum2[0];
    assign to_be_added[0]=enabled_sum1[0]^enabled_sum2[0];
    wire carry;
    assign carry=enabled_sum1[0]&enabled_sum2[0];
    assign to_be_added[1]=enabled_sum1[1]^enabled_sum2[1]^carry;
    wire to_be_added_2_if_no_carry;
    assign to_be_added_2_if_no_carry=(enabled_sum1[1]&enabled_sum2[1])|((enabled_sum1[1]|enabled_sum2[1])&carry);
    assign to_be_added[2]=to_be_added_2_if_no_carry^(sum1[2]&sum2[2]);
    assign to_be_added[3]=to_be_added_2_if_no_carry&(sum1[2]&sum2[2]);
    wire [4:0] P1_before_subtraction;
    binary_adder #(.N(4)) adder2 (.X({1'b0, 1'b0, P1[3:2]}), .Y(to_be_added), .Z(P1_before_subtraction));
    wire [4:0] P1_final;
    binary_subtractor #(.N(5)) subtractor1 (.X({P1_before_subtraction[2:0], P1[1:0]}), .Y(P0_plus_P2), .Z(P1_final));
    wire carry2;
    binary_adder #(.N(2)) adder3 (.X(P1_final[1:0]), .Y(P0), .Z({carry2, Z[3:2]}));
    binary_adder_with_carry #(.N(4)) adder4 (.X(P2), .Y({1'b0, P1_final[4:2]}), .Z(Z[7:4]), .input_carry(carry2));
endmodule

module karatsuba_8 (X, Y, Z);
    input [7:0] X, Y;
    output [15:0] Z;

    wire [7:0] P2;
    wire [3:0] P0;
    karatsuba_4 k1 (.X(X[3:0]), .Y(Y[3:0]), .Z({P0, Z[3:0]}));
    karatsuba_4 k2 (.X(X[7:4]), .Y(Y[7:4]), .Z(P2));
    wire [8:0] P0_plus_P2;
    binary_adder #(.N(8)) adder (.X({P0, Z[3:0]}), .Y(P2), .Z(P0_plus_P2));
    wire [4:0] sum1, sum2;    
    binary_adder #(.N(4)) sum1_adder(.X(X[3:0]), .Y(X[7:4]), .Z(sum1));
    binary_adder #(.N(4)) sum2_adder(.X(Y[3:0]), .Y(Y[7:4]), .Z(sum2));
    wire [7:0] P1;
    karatsuba_4 k3 (.X(sum1[3:0]), .Y(sum2[3:0]), .Z(P1[7:0]));
    wire [5:0] to_be_added;
    wire [3:0] enabled_sum1, enabled_sum2;
    assign enabled_sum1 = {4{sum2[4]}} & sum1[3:0];
    assign enabled_sum2 = {4{sum1[4]}} & sum2[3:0];
    wire carry;
    binary_adder #(.N(4)) adder1 (.X(enabled_sum1), .Y(enabled_sum2), .Z({carry, to_be_added[3:0]}));
    wire without_carry=sum2[4]&sum1[4];
    assign to_be_added[4]=without_carry^carry;
    assign to_be_added[5]=without_carry&carry;
    wire [4:0] P1_before_subtraction; // Can we reduce this to 5 if we reduce the next to 9
    binary_adder #(.N(5)) adder2 (.X({1'b0, P1[7:4]}), .Y(to_be_added[4:0]), .Z(P1_before_subtraction));
    wire [8:0] P1_final; // Can we reduce this to 9?
    binary_subtractor #(.N(9)) subtractor1 (.X({P1_before_subtraction, P1[3:0]}), .Y(P0_plus_P2), .Z(P1_final));
    wire carry2;
    binary_adder #(.N(4)) adder3 (.X(P1_final[3:0]), .Y(P0), .Z({carry2, Z[7:4]}));
    binary_adder_with_carry #(.N(8)) adder4 (.X(P2), .Y({1'b0, 1'b0, 1'b0, P1_final[8:4]}), .Z(Z[15:8]), .input_carry(carry2));
endmodule

module karatsuba_16 (X, Y, Z);
    input [15:0] X, Y;
    output [31:0] Z;

    wire [15:0] P2;
    wire [7:0] P0;
    karatsuba_8 k1 (.X(X[7:0]), .Y(Y[7:0]), .Z({P0, Z[7:0]}));
    karatsuba_8 k2 (.X(X[15:8]), .Y(Y[15:8]), .Z(P2));
    wire [16:0] P0_plus_P2;
    binary_adder #(.N(16)) adder (.X({P0, Z[7:0]}), .Y(P2), .Z(P0_plus_P2));
    wire [8:0] sum1, sum2;
    binary_adder #(.N(8)) sum1_adder(.X(X[7:0]), .Y(X[15:8]), .Z(sum1));
    binary_adder #(.N(8)) sum2_adder(.X(Y[7:0]), .Y(Y[15:8]), .Z(sum2));
    wire [15:0] P1;
    karatsuba_8 k3 (.X(sum1[7:0]), .Y(sum2[7:0]), .Z(P1[15:0]));
    wire [9:0] to_be_added;
    wire [7:0] enabled_sum1, enabled_sum2;
    assign enabled_sum1 = {8{sum2[8]}} & sum1[7:0];
    assign enabled_sum2 = {8{sum1[8]}} & sum2[7:0];
    wire carry;
    binary_adder #(.N(8)) adder1 (.X(enabled_sum1), .Y(enabled_sum2), .Z({carry, to_be_added[7:0]}));
    wire without_carry=sum2[8]&sum1[8];
    assign to_be_added[8]=without_carry^carry;
    assign to_be_added[9]=without_carry&carry;
    wire [8:0] P1_before_subtraction;
    binary_adder #(.N(9)) adder2 (.X({1'b0, P1[15:8]}), .Y(to_be_added[8:0]), .Z(P1_before_subtraction));
    wire [16:0] P1_final; 
    binary_subtractor #(.N(17)) subtractor1 (.X({P1_before_subtraction, P1[7:0]}), .Y(P0_plus_P2), .Z(P1_final));
    wire carry2;
    binary_adder #(.N(8)) adder3 (.X(P1_final[7:0]), .Y(P0), .Z({carry2, Z[15:8]}));
    binary_adder_with_carry #(.N(16)) adder4 (.X(P2), .Y({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, P1_final[16:8]}), .Z(Z[31:16]), .input_carry(carry2));
endmodule