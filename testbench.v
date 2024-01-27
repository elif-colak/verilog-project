// Code your testbench here
// or browse Examples
`timescale 1ns / 1ns

module tb;
parameter SIZE = 14, DEPTH = 2**14;

reg clk;
initial begin
  clk = 1;
  forever
	  #5 clk = ~clk;
end

reg rst;
initial begin
  rst = 1;
  repeat (10) @(posedge clk);
  rst <= #1 0;
  repeat (300) @(posedge clk);
  $finish;
end
  
reg interrupt;
  initial begin
  interrupt = 1'b0;
    repeat (36) @(negedge clk);
  interrupt <=#1 1;
  @ (posedge clk);
   interrupt <=#1 0;
    repeat (36) @(negedge clk);
  interrupt <=#1 1;
  @ (posedge clk);
   interrupt <=#1 0;
   repeat (56) @(negedge clk);
  interrupt <=#1 1;
  @ (posedge clk);
   interrupt <=#1 0;
end
  
wire wrEn;
wire [SIZE-1:0] addr_toRAM;
wire [31:0] data_toRAM, data_fromRAM;

VerySimpleCPU inst_VerySimpleCPU(
  .clk(clk),
  .rst(rst),
  .wrEn(wrEn),
 .data_fromRAM(data_fromRAM),
  .addr_toRAM(addr_toRAM),
  .data_toRAM(data_toRAM),
  .interrupt (interrupt)
  
);

  blram #(SIZE, DEPTH) inst_blram(
  .clk(clk),
  .i_we(wrEn),
  .i_addr(addr_toRAM),
  .i_ram_data_in(data_toRAM),
  .o_ram_data_out(data_fromRAM)
);
	initial begin
      $dumpfile("dump.vcd"); $dumpvars;
		   
	blram.memory[0] = 32'h8003c010;
	blram.memory[1] = 32'h2003c010;
	blram.memory[2] = 32'h1003c001;
    blram.memory[3] = 32'h4400f;
    blram.memory[4] = 32'h80030011;
	blram.memory[5] = 32'h1002c001;
	blram.memory[6] = 32'h60030010;
	blram.memory[7] = 32'hc003400c;
	blram.memory[8] = 32'h1002c000;
	blram.memory[11] = 32'h0;
	blram.memory[12] = 32'h0;
	blram.memory[13] = 32'h0;
	blram.memory[15] = 32'h0;
    blram.memory[16] = 32'h5;
    blram.memory[17] = 32'hb;
	blram.memory[20] = 32'd30; //ISR begin address @30 end address @32
    blram.memory[30] = 32'h2002800a;
    blram.memory[31] = 32'h10028001;
    blram.memory[32] = 32'hc005412c; //BZJ 21,300
    blram.memory[100] = 32'h0;
    blram.memory[300] = 32'h0;

    end
  
endmodule