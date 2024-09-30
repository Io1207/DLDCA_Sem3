/* 32-bit simple karatsuba multiplier */

/*32-bit Karatsuba multipliction using a single 16-bit module*/

module iterative_karatsuba_32_16(clk, rst, enable, A, B, C);
    input clk;
    input rst;
    input [31:0] A;
    input [31:0] B;
    output [63:0] C;
    
    input enable;
    
    
    wire [1:0] sel_x;
    wire [1:0] sel_y;
    
    wire [1:0] sel_z;
    wire [1:0] sel_T;
    
    
    wire done;
    wire en_z;
    wire en_T;
    
    
    wire [32:0] h1;
    wire [32:0] h2;
    wire [63:0] g1;
    wire [63:0] g2;
    
    reg_with_enable #(.N(63)) Z(.clk(clk), .rst(rst), .en(en_z), .X(g1), .O(g2) );  // Fill in the proper size of the register
    reg_with_enable #(.N(32)) T(.clk(clk), .rst(rst), .en(en_T), .X(h1), .O(h2) );  // Fill in the proper size of the register
    
    iterative_karatsuba_datapath dp(.clk(clk), .rst(rst), .X(A), .Y(B), .Z(g2), .T(h2), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done), .W1(g1), .W2(h1));
    iterative_karatsuba_control control(.clk(clk),.rst(rst), .enable(enable), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done));    
    assign C = g1;
endmodule

module iterative_karatsuba_datapath(clk, rst, X, Y, T, Z, sel_x, sel_y, en_z, sel_z, en_T, sel_T, done, W1, W2);
    input clk;
    input rst;
    input [31:0] X;    // input X
    input [31:0] Y;    // Input Y
    input [32:0] T;    // input which sums X_h*Y_h and X_l*Y_l (its also a feedback through the register)
    input [63:0] Z;    // input which calculates the final outcome (its also a feedback through the register)
    output [63:0] W1;  // Signals going to the registers as input
    output [32:0] W2;  // signals hoing to the registers as input
    

    input [1:0] sel_x;  // control signal 
    input [1:0] sel_y;  // control signal 
    
    input en_z;         // control signal 
    input [1:0] sel_z;  // control signal 
    input en_T;         // control signal 
    input [1:0] sel_T;  // control signal 
    
    input done;         // Final done signal
    
    
   

    //-------------------------------------------------------------------------------------------------
    
    // Write your datapath here
    //--------------------------------------------------------
    wire [15:0] operand1_for_multiplication;
    wire [15:0] operand2_for_multiplication;
    wire [31:0] P2;
    wire [15:0] P0;
    wire [31:0] P1;
    wire [32:0] P0_plus_P2;

    assign P0[15:0]=(sel_x==2'b0)?W2[31:16]:P0[15:0];
    assign W1[15:0]=(sel_x==2'b0)?W2[15:0]:W1[15:0];   
    assign P2=(sel_x==2'b01)?W2:P2;
    assign P1=((sel_x==2'b10))?W2:P1;

    adder_Nbit #(.N(32)) adder_P0_P2({P0, W1[15:0]}, P2, 1'b0, P0_plus_P2[31:0], P0_plus_P2[32]);
    wire [16:0] sum1, sum2;
    adder_Nbit #(.N(16)) x_adder_1(X[31:16], X[15:0], 1'b0, sum1[15:0], sum1[16]);
    adder_Nbit #(.N(16)) x_adder_2(Y[31:16], Y[15:0], 1'b0, sum2[15:0], sum2[16]);

    assign operand1_for_multiplication=(sel_x==2'b10)?sum1:(sel_x==2'b00)?{1'b0, X[15:0]}:{1'b0, X[31:16]};
    assign operand2_for_multiplication=(sel_x==2'b10)?sum2:(sel_x==2'b00)?{1'b0, Y[15:0]}:{1'b0, Y[31:16]};

    mult_16 multiply(operand1_for_multiplication, operand2_for_multiplication, W2);

    wire [17:0] to_be_added;
    wire carry;
    adder_Nbit #(.N(16)) adder1({16{sum2[16]}} & sum1[15:0], {16{sum1[16]}} & sum2[15:0], 1'b0, to_be_added[15:0], carry);
    wire without_carry=sum2[16]&sum1[16];
    assign to_be_added[16]=without_carry^carry;
    assign to_be_added[17]=without_carry&carry;
    wire [16:0] P1_before_subtraction;
    wire extra_carry;
    adder_Nbit #(.N(17)) adder2 ({1'b0, P1[31:16]}, to_be_added[16:0], 1'b0, P1_before_subtraction, extra_carry);
    wire [32:0] P1_final;
    wire xor_operator, extra_carry2;
    assign xor_operator=1;
    adder_Nbit #(.N(33)) subtractor1 ({P1_before_subtraction, P1[15:0]}, {33{xor_operator}}^P0_plus_P2, 1'b1, P1_final, extra_carry2);

    wire carry2, extra_carry3;
    adder_Nbit #(.N(16)) adder3 (P1_final[15:0], P0, 1'b0, W1[31:16], carry2);
    adder_Nbit #(.N(32)) adder4 (P2, {15'b0, P1_final[32:16]}, carry2, W1[63:32], extra_carry3);
endmodule


module iterative_karatsuba_control(clk,rst, enable, sel_x, sel_y, sel_z, sel_T, en_z, en_T, done);
    input clk;
    input rst;
    input enable;
    
    output reg [1:0] sel_x;
    output reg [1:0] sel_y;
    
    output reg [1:0] sel_z;
    output reg [1:0] sel_T;    
    
    output reg en_z;
    output reg en_T;
    
    
    output reg done;
    
    reg [5:0] state, nxt_state;
    parameter S0 = 6'b000000, S1=6'b000001, S2=6'b000010, S3=6'b000011;   // initial state
   // <define the rest of the states here>

    always @(posedge clk) begin
        if (rst) begin
            state <= S0;
        end
        else if (enable) begin
            state <= nxt_state;
        end
    end
    

    always@(*) begin
        case(state) 
            S0: 
                begin
					nxt_state=S1;
                end
            S1:
                begin
                    nxt_state=S2;                    
                end
            S2:
                begin
                    nxt_state=S0;
                end
            default: 
                begin
				    nxt_state=S0;
                end            
        endcase
        
    end
    always @(state)
    begin
        sel_x<=state[1:0];
    end
endmodule


module reg_with_enable #(parameter N = 32) (clk, rst, en, X, O );
    input [N:0] X;
    input clk;
    input rst;
    input en;
    output [N:0] O;
    
    reg [N:0] R;
    
    always@(posedge clk) begin
        if (rst) begin
            R <= {N{1'b0}};
        end
        if (en) begin
            R <= X;
        end
    end
    assign O = R;
endmodule


/*-------------------Supporting Modules--------------------*/
/*------------- Iterative Karatsuba: 32-bit Karatsuba using a single 16-bit Module*/

module mult_16(X, Y, Z);
input [15:0] X;
input [15:0] Y;
output [31:0] Z;

assign Z = X*Y;

endmodule


module mult_17(X, Y, Z);
input [16:0] X;
input [16:0] Y;
output [33:0] Z;

assign Z = X*Y;

endmodule

module full_adder(a, b, cin, S, cout);
input a;
input b;
input cin;
output S;
output cout;

assign S = a ^ b ^ cin;
assign cout = (a&b) ^ (b&cin) ^ (a&cin);

endmodule


module check_subtract (A, B, C);
 input [7:0] A;
 input [7:0] B;
 output [8:0] C;
 
 assign C = A - B; 
endmodule



/* N-bit RCA adder (Unsigned) */
module adder_Nbit #(parameter N = 32) (a, b, cin, S, cout);
input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output cout;

wire [N:0] cr;  

assign cr[0] = cin;


generate
    genvar i;
    for (i = 0; i < N; i = i + 1) begin
        full_adder addi (.a(a[i]), .b(b[i]), .cin(cr[i]), .S(S[i]), .cout(cr[i+1]));
    end
endgenerate    


assign cout = cr[N];

endmodule


module Not_Nbit #(parameter N = 32) (a,c);
input [N-1:0] a;
output [N-1:0] c;

generate
genvar i;
for (i = 0; i < N; i = i+1) begin
    assign c[i] = ~a[i];
end
endgenerate 

endmodule


/* 2's Complement (N-bit) */
module Complement2_Nbit #(parameter N = 32) (a, c, cout_comp);

input [N-1:0] a;
output [N-1:0] c;
output cout_comp;

wire [N-1:0] b;
wire ccomp;

Not_Nbit #(.N(N)) compl(.a(a),.c(b));
adder_Nbit #(.N(N)) addc(.a(b), .b({ {N-1{1'b0}} ,1'b1 }), .cin(1'b0), .S(c), .cout(ccomp));

assign cout_comp = ccomp;

endmodule


/* N-bit Subtract (Unsigned) */
module subtract_Nbit #(parameter N = 32) (a, b, cin, S, ov, cout_sub);

input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output ov;
output cout_sub;

wire [N-1:0] minusb;
wire cout;
wire ccomp;

Complement2_Nbit #(.N(N)) compl(.a(b),.c(minusb), .cout_comp(ccomp));
adder_Nbit #(.N(N)) addc(.a(a), .b(minusb), .cin(1'b0), .S(S), .cout(cout));

assign ov = (~(a[N-1] ^ minusb[N-1])) & (a[N-1] ^ S[N-1]);
assign cout_sub = cout | ccomp;

endmodule



/* n-bit Left-shift */

module Left_barrel_Nbit #(parameter N = 32)(a, n, c);

input [N-1:0] a;
input [$clog2(N)-1:0] n;
output [N-1:0] c;


generate
genvar i;
for (i = 0; i < $clog2(N); i = i + 1 ) begin: stage
    localparam integer t = 2**i;
    wire [N-1:0] si;
    if (i == 0) 
    begin 
        assign si = n[i]? {a[N-t:0], {t{1'b0}}} : a;
    end    
    else begin 
        assign si = n[i]? {stage[i-1].si[N-t:0], {t{1'b0}}} : stage[i-1].si;
    end
end
endgenerate

assign c = stage[$clog2(N)-1].si;

endmodule