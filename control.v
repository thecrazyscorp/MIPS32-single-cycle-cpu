// file: control.v


`timescale 1ns/1ns

module Controlunit(input [5:0] Opcode, 
               input [5:0] Func,
               input Zero,
               output reg [1:0] MemtoReg, //extended for JAL
               output reg  MemWrite,
               output reg  ALUSrc,
               output reg  [1:0] RegDst, //extended for JAL
               output reg  RegWrite,
               output reg  Jump,
               output PCSrc,
               output reg  [4:0] ALUControl
               );
               
reg [9:0] temp;
reg Branch,BNE;
always @(*) begin 

    case (Opcode) 
        6'b000000: begin                          // R-type
                    temp <= 10'b1010000000;        

                    case (Func)
		    6'b001000: ALUControl = 5'b1_1111;  // bit4=1 => JR
                    // Normal R-type instructions => top bit=0, bottom bits = ALU op
                6'b100000: ALUControl = 5'b0_0000;  // ADD
                6'b100001: ALUControl = 5'b0_0000;  // ADDU
                6'b100010: ALUControl = 5'b0_0001;  // SUB
                6'b100011: ALUControl = 5'b0_0001;  // SUBU
                6'b100100: ALUControl = 5'b0_0010;  // AND
                6'b100101: ALUControl = 5'b0_0011;  // OR
                6'b100110: ALUControl = 5'b0_0100;  // XOR
                6'b100111: ALUControl = 5'b0_1010;  // NOR
                6'b101010: ALUControl = 5'b0_1000;  // SLT
                6'b101011: ALUControl = 5'b0_1001;  // SLTU
                6'b000000: ALUControl = 5'b0_0101;  // SLL
                6'b000010: ALUControl = 5'b0_0110;  // SRL
                6'b000011: ALUControl = 5'b0_0111;  // SRA
                6'b000100: ALUControl = 5'b0_1011;  // SLLV
                6'b000110: ALUControl = 5'b0_1100;  // SRLV
                6'b000111: ALUControl = 5'b0_1101;  // SRAV
                default:   ALUControl = 5'b0_0000;  // default
                endcase

            end
	
	6'b000011: begin //JAL
			temp <= 10'b1100001010;
			ALUControl  = 5'b0_0010; 
		    end


        6'b100011: begin                          // LW
                        temp <= 10'b1001000100;     
                        ALUControl  = 5'b0_0000;       // ADD for address calc
                    end

        6'b101011: begin                          // SW
                         temp <= 10'b0001010000;      
                         ALUControl  = 5'b0_0000;       // ADD
                    end  

        6'b000100: begin                          // BEQ
                         temp <= 10'b0000100000;      
                         ALUControl  = 5'b0_0001;       // SUB
                    end      

        6'b000101: begin                          // BNE
                        temp <= 10'b0000100001;  
                        ALUControl  = 5'b0_0001;       // SUB
                    end

        6'b001000: begin                          // ADDI
                        temp <= 10'b1001000000;  
                        ALUControl  = 5'b0_0000;       // ADD
                    end  

        6'b001001: begin                          // ADDIU
                        temp <= 10'b1001000000;  
                        ALUControl  = 5'b0_0000;       // ADD
                    end  

        6'b001100: begin                          // ANDI
                        temp <= 10'b1001000000;  
                        ALUControl  = 5'b0_0010;       // AND
                    end 

        6'b001101: begin                          // ORI
                        temp <= 10'b1001000000;  
                         ALUControl  = 5'b0_0011;       // OR
                    end  

        6'b001110: begin                          // XORI
                        temp <= 10'b1001000000;  
                        ALUControl  = 5'b0_0100;       // XOR
                    end       

        6'b001010: begin                          // SLTI
                        temp <= 10'b1001000000;  
                        ALUControl  = 5'b0_1000;       // SLT
                    end 

        6'b001011: begin                          // SLTIU
                        temp <= 10'b1001000000;  
                        ALUControl  = 5'b0_1001;       // SLTU
                    end  

        6'b000010: begin                          // J
                        temp <= 10'b0000000010;  
                         ALUControl  = 5'b0_0010; // doesn't matter
                    end 
                        
        6'b001111:  begin                         // LUI
                        temp <= 10'b1001000000;  
                        ALUControl  = 5'b0_1110; // LUI
                    end          
        default:   temp <= 12'bxxxxxxxxxxxx;      // NOP
    endcase
   

    
    {RegWrite,RegDst[1:0],ALUSrc,Branch,MemWrite,MemtoReg[1:0],Jump,BNE} = temp;

end 

assign PCSrc = Branch & (Zero ^ BNE);
//assign PCSrc = (Branch & Zero) | (BNE & ~Zero);

endmodule