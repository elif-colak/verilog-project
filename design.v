// Code your design here
module VerySimpleCPU(clk, rst, data_fromRAM, wrEn, addr_toRAM, data_toRAM, interrupt);

  input clk, rst, interrupt;
  output reg wrEn;
  input [31:0] data_fromRAM;
  output reg [31:0] data_toRAM;
  output reg [13:0] addr_toRAM;
  reg [2:0] st, stN;
  reg [13:0] PC, PCN;
  reg [31:0] IW, IWN, A, AN;
  reg 	intr, intrN,isr, isrN;

  
  always @(posedge clk) begin
    	st<=stN;
    	PC<=PCN;
    	A<=AN;
    	IW<= IWN;
    	intr<= intrN;
    	isr <= isrN;
  end

  always @ * begin
	  stN= 3'bxxx;
      addr_toRAM = 14'dX;
      data_toRAM = 32'dx;
      AN = 32'dx;
      PCN = PC;
      wrEn = 1'b0;
      IWN = IW;
      intrN= (interrupt && intr==1'b0)? 1'b1: intr;
	  isrN = isr;

		if (rst) begin
			stN = 3'b000;
			PCN = 14'd0; 
			intrN= 1'b0;
			isrN = 1'b0;
		end
		else begin    
      		case (st)
      		3'b000: begin
          	addr_toRAM = PC; //fetch instruction
          	stN = 3'b001;
        	end
              
        3'b001: begin

          IWN = data_fromRAM;

          if ((data_fromRAM[31:30] == 2'b00) || (data_fromRAM[31:29] == 3'b110))  begin // ADD, ADDi, NAND, NANDi, BZJi, BZJ instruction
            addr_toRAM = data_fromRAM[27:14]; // read opA
            stN = 3'b010; 
          end
          
          if((data_fromRAM[31:30] == 2'b01 || data_fromRAM[31:29] == 3'b111)) begin // SRL, SRLi, LT, LTi, MUL, MULi instruction
            addr_toRAM = data_fromRAM[27:14]; // read opA
            stN = 3'b010;
          end
          
          if((data_fromRAM[31:28] == 4'b1000) || (data_fromRAM[31:28] == 4'b1010)) begin  // CP, CPI instruction
            addr_toRAM = data_fromRAM[13:0]; // read opB
            stN = 3'b010;
          end
          
          if((data_fromRAM[31:28] == 4'b1001)) begin // CPi instruction
            addr_toRAM = data_fromRAM[27:14]; // read opA
            data_toRAM = data_fromRAM[13:0];
            wrEn = 1'b1;
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;
          end
          
          if((data_fromRAM[31:28] == 4'b1011)) begin // CPIi instruction
            addr_toRAM = data_fromRAM[27:14]; // read opA
            stN = 3'b010;
          end        

          
        end
              
        3'b010: begin
          if ( (IW[31:28] == 4'b1100) || (IW[31:28] == 4'b0000) || (IW[31:28] == 4'b0010)) begin // ADD and NAND, BZJ instruction
          		AN = data_fromRAM;
              	addr_toRAM = IW[13:0];
              	stN = 3'b011;
        	end
          if (IW[31:28] == 4'b0001) begin // ADDi instruction
            	data_toRAM = data_fromRAM + IW[13:0]; // *A<-(A) + B
            	addr_toRAM = IW[27:14];
            	wrEn = 1'b1;
                PCN = PC + 14'd1;
            	if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;
              end                 
          if (IW[31:28] == 4'b0011) begin // NANDi instruction
            	data_toRAM = ~(data_fromRAM & IW[13:0]); // *A<-~((A) & B)
            	addr_toRAM = IW[27:14];
            	wrEn = 1'b1;
                PCN = PC + 14'd1;
            	if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;
        	end
          if (IW[31:28] == 4'b1101) begin // BZJi instruction
            	PCN= data_fromRAM[13:0] + IW[13:0]; // PC<-(A) + B
            	if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;
        	end
          
          
          if( IW[31:28] == 4'b0110 || IW[31:28] == 4'b0100 || IW[31:28] == 4'b1110) begin // SRL, LT, MUL instruction
            AN = data_fromRAM;
            addr_toRAM = IW[13:0];
            stN = 3'b011;
          end
          
          
           if(IW[31:28] == 4'b0101) begin // SRLi instruction
            addr_toRAM = IW[27:14];
            data_toRAM = (IW[13:0] < 32) ? ( data_fromRAM >> IW[13:0]) : (data_fromRAM<<(IW[13:0]-32));
            wrEn = 1'b1; // write back the result
             	PCN = PC + 14'd1;
             	if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;     
          end
          
          
          if(IW[31:28] == 4'b0111) begin // LTi instruction
            addr_toRAM = IW[27:14];
            data_toRAM = (data_fromRAM < IW[13:0]) ? 1 : 0;
            wrEn = 1'b1;
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;   
          end
          
                    
          if(IW[31:28] == 4'b1111) begin // MULi instruction
            addr_toRAM = IW[27:14];
            data_toRAM = (data_fromRAM * IW[13:0]);
            wrEn = 1'b1;
            PCN = PC + 14'd1;
             	if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;   
          end
          
          
          if (IW[31:28] == 4'b1000) begin // CP instruction
            addr_toRAM = IW[27:14];
            data_toRAM = data_fromRAM;
            wrEn = 1'b1;  // write back the result
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;     
     		
          end
          
          if(IW[31:28] == 4'b1010) begin // CPI instruction
            addr_toRAM = data_fromRAM;
            stN = 3'b011;
            
          end
          
          if(IW[31:28] == 4'b1011) begin //CPIi instruction
            AN = data_fromRAM;
            addr_toRAM = IW[13:0];
            stN = 3'b011;
          end           
          
    
        end
              
              
        3'b011: begin
          	if (IW[31:28] == 4'b0000) begin // ADD instruction
             	addr_toRAM = IW[27:14]; 
             	data_toRAM = A + data_fromRAM;
             	wrEn = 1'b1; // write back the result
             	PCN = PC + 14'd1;
             	if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;     
     		end
          if (IW[31:28] == 4'b0010) begin // NAND instruction
             	addr_toRAM = IW[27:14]; 
            	data_toRAM = ~(A & data_fromRAM);
             	wrEn = 1'b1; // write back the result
             	PCN = PC + 14'd1;
             	if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;     
     		end
          if (IW[31:28] == 4'b1100) begin // BZJ instruction
           	if (data_fromRAM == 32'd0) 
              PCN = A[13:0];
            else
              PCN = PC +14'd1;           
            if (IW[27:14] == 14'h0015) begin //Return from interrupt
               	    intrN = 1'b0;
             	    isrN = 1'b0;
           	 end             
             if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;     
     		end 
          
          if(IW[31:28] == 4'b0100) begin  // SRL instruction
            addr_toRAM = IW[27:14];
            data_toRAM = (data_fromRAM < 32) ? (A >> data_fromRAM) : (A << (data_fromRAM-32));
            wrEn = 1'b1;
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;	
            else
             		stN = 3'h0;   
            
          end
          
          
          if(IW[31:28] == 4'b1110) begin // MUL instruction
            addr_toRAM = IW[27:14];
            data_toRAM = (data_fromRAM * A );
            wrEn = 1'b1;
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;
               	else
             		stN = 3'h0;     
          end
          
          if(IW[31:28] == 4'b0110) begin  // LT instruction
            addr_toRAM = IW[27:14];
            data_toRAM = (A < data_fromRAM) ? 1 : 0 ;
            wrEn = 1'b1;
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;	
            else
             		stN = 3'h0;   
            
          end
          
          if(IW[31:28] == 4'b1010) begin //CPI instruction
            addr_toRAM = IW[27:14];
            data_toRAM = data_fromRAM;
            wrEn = 1'b1;
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;	
            else
             		stN = 3'h0;   
            
          end
          
          if(IW[31:28] == 4'b1011) begin /// CPIi instruction
            addr_toRAM = A;
            data_toRAM = data_fromRAM;
            wrEn = 1'b1;
            PCN = PC + 14'd1;
            if (intr==1'b1 && isr != 1'b1)  // if there is an interrupt do the ISR
               		stN = 3'h4;	
            else
             		stN = 3'h0;   
          end
          
          
          
      	end
        3'b100: begin // New state to get the ISR address from @20      
              wrEn = 1'b0;
              addr_toRAM = 32'h14; //Get the ISR address
              stN = 3'h5;
              isrN = 1'b1;         
        end
        3'b101: begin // New state to store the next ınstruction address @21   
              wrEn = 1'b1;
              data_toRAM = PC; 
              addr_toRAM = 32'h15; // Store next PC value @21
              PCN = data_fromRAM[13:0];
              stN = 3'h0;         
        end
  	endcase
  end
 end

endmodule



module blram(clk, i_we, i_addr, i_ram_data_in, o_ram_data_out);



parameter SIZE = 14, DEPTH = 2**14;



input clk;

input i_we;

input [SIZE-1:0] i_addr;

input [31:0] i_ram_data_in;

output reg [31:0] o_ram_data_out;



reg [31:0] memory[0:DEPTH-1];



always @(posedge clk) begin

  o_ram_data_out <= #1 memory[i_addr[SIZE-1:0]];

  if (i_we)

		memory[i_addr[SIZE-1:0]] <= #1 i_ram_data_in;

end 
endmodule
	