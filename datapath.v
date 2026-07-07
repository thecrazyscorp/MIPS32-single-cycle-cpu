// file: Datapath.v


`include "adder.v"
`include "alu32.v"
`include "flopr_param.v"
`include "mux2.v"
`include "mux4.v"
`include "regfile32.v"
`include "signext.v"
`include "sl2.v"

`timescale 1ns/1ns

module Datapath(input clk,
                input reset,
                input [1:0] RegDst, //extended for JAL
                input RegWrite,
                input ALUSrc,
                input Jump,
                input [1:0] MemtoReg, //extended for JAL
                input PCSrc,
                input [4:0] ALUControl,
                input [31:0] ReadData,
                input [31:0] Instr,
                output [31:0] PC,
                output ZeroFlag,
                output [31:0] datatwo,  //writedata
                output [31:0] ALUResult);


wire [31:0] PCNext, PCplus4, PCbeforeBranch, PCBranch, PCafterJump;
wire [31:0] extendedimm, extendedimmafter, MUXresult, dataone, aluop2;
wire [4:0] writereg;
wire jrBit = ALUControl[4];
wire [3:0] aluOp = ALUControl[3:0];

// PC 
flopr_param #(32) PCregister(clk,reset, PC,PCNext);
  adder #(32) pcadd4(PC, 32'd4 ,PCplus4);
slt2 shifteradd2(extendedimm,extendedimmafter);
//assign extendedimm = { {16{Instr[15]}}, Instr[15:0] };
//assign extendedimmafter = extendedimm << 1;

adder #(32) pcaddsigned(extendedimmafter,PCplus4,PCbeforeBranch);
mux2 #(32) branchmux(PCplus4 , PCbeforeBranch, PCSrc, PCBranch);
mux2 #(32) jumpmux(PCBranch, {PCplus4[31:28],Instr[25:0],2'b00 }, Jump,PCafterJump);
mux2 #(32) jrmux(PCafterJump, dataone, jrBit, PCNext); //added a new mux for JR

// Register File 

registerfile32 RF(clk,RegWrite, reset, Instr[25:21], Instr[20:16], writereg, MUXresult, dataone,datatwo); 
mux4 #(5) writeopmux(Instr[20:16],Instr[15:11], 5'd31, 5'd0, RegDst[1:0], writereg); //extended to mux4 to include $31 as write address
mux4 #(32) resultmux(ALUResult, ReadData, PCplus4, 32'd0, MemtoReg[1:0], MUXresult); //extended to mux4 to include PCplus4 as write data

// ALU

alu32 alucomp(dataone, aluop2, aluOp, Instr[10:6], ALUResult, ZeroFlag);
signext immextention(Instr[15:0],extendedimm);
mux2 #(32) aluop2sel(datatwo,extendedimm, ALUSrc, aluop2);


endmodule