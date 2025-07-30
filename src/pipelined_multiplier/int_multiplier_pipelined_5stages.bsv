/*
see LICENSE.iitm

Author : Nagakaushik Moturi
Email id : ee17b111@smail.iitm.ac.in
Details : This module implements the multiplier for RISC-V. It expects the operands and funct3
arguments to be provided. It is pipelined version with 5 stages. It takes the multiplier and divides it into
6 bit chunks and obtains partial products of the multiplicand with them, and then adds all partial products.
--------------------------------------------------------------------------------------------------
*/

package int_multiplier_pipelined_5stages;

  import DReg :: *;
  import Vector :: * ;
  `include "Logger.bsv"
  `include "mbox_parameters.bsv"
  
  interface Ifc_int_multiplier;
    (*always_ready*)
	  method Action send(Bit#(`XLEN) in1, Bit#(`XLEN) in2, Bit#(3) funct3
                                                                `ifdef RV64, Bool word32 `endif );
	  method Tuple2#(Bit#(1),Bit#(`XLEN)) receive;
	endinterface

  (*synthesize*)
  module mk_int_multiplier(Ifc_int_multiplier);
  
    Reg#(Bit#(130)) rg_partial_product0 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product1 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product2 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product3 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product4 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product5 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product6 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product7 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product8 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product9 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product10 <- mkReg(0);
    
    Reg#(Bit#(130)) rg_partial_product6_2 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product7_2 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product8_2 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product9_2 <- mkReg(0);
    Reg#(Bit#(130)) rg_partial_product10_2 <- mkReg(0);
    
    Reg#(Bit#(140)) rg_partial_product0_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product1_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product2_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product3_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product4_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product5_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product6_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product7_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product8_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product9_1 <- mkReg(0);
    Reg#(Bit#(140)) rg_partial_product10_1 <- mkReg(0);
    
    Reg#(Bit#(130)) rg_res <- mkReg(0);
    Reg#(Bit#(130)) rg_res1 <- mkReg(0);
    Reg#(Bit#(130)) rg_out <- mkReg(0);
    
    Reg#(Bit#(TAdd#(1, `XLEN))) rg_operands1 <- mkReg(0);
    Reg#(Bit#(TAdd#(1, `XLEN))) rg_operands2 <- mkReg(0);
    
    Reg#(Bit#(3)) rg_funct3_0 <- mkReg(0);
    Reg#(Bit#(3)) rg_funct3_1 <- mkReg(0);
    Reg#(Bit#(3)) rg_funct3_2 <- mkReg(0);
    Reg#(Bit#(3)) rg_funct3_3 <- mkReg(0);
    Reg#(Bit#(3)) rg_fn3 <- mkReg(0);
    
    Reg#(Bool) rg_word <- mkReg(False);
    Reg#(Bool) rg_word_1 <- mkReg(False);
    Reg#(Bool) rg_word_2 <- mkReg(False);
    Reg#(Bool) rg_word_3 <- mkReg(False);
    Reg#(Bool) rg_word_4 <- mkReg(False);
    
    Reg#(Bit#(1)) rg_valid <- mkReg(0);
    Reg#(Bit#(1)) rg_valid_1 <- mkReg(0);
    Reg#(Bit#(1)) rg_valid_2 <- mkReg(0);
    Reg#(Bit#(1)) rg_valid_3 <- mkReg(0);
    Reg#(Bit#(1)) rg_valid_4 <- mkReg(0);
    
    Reg#(Bit#(1)) rg_sign <- mkReg(0);
    Reg#(Bit#(1)) rg_sign_1 <- mkReg(0);
    Reg#(Bit#(1)) rg_sign_2 <- mkReg(0);
    Reg#(Bit#(1)) rg_sign_3 <- mkReg(0);
    Reg#(Bit#(1)) rg_sign_4 <- mkReg(0);

 	  function Bit#(140) fn_gen_pp(Bit#(65) m,Bit#(6) b);                   //generates the partial products for multiplication

      Bit#(70) a=zeroExtend(m);
      Bit#(70) res1=0;
      Bit#(70) res2=0;
      Bit#(70) res3=0;
      Bit#(70) res4=0;
      Bit#(70) res5=0;
      Bit#(70) res6=0;
      
      Bit#(70) o1=0;
      Bit#(70) o2=0;
      Bit#(140) o=0;
      
      //shifts the required no.of bits according to the position for 6 bits of the multiplier
      res1 = (b[0]==1'b1)?(a):70'd0;
      res2 = (b[1]==1'b1)?(a<<1):70'd0;
      res3 = (b[2]==1'b1)?(a<<2):70'd0;
      res4 = (b[3]==1'b1)?(a<<3):70'd0;
      res5 = (b[4]==1'b1)?(a<<4):70'd0;
      res6 = (b[5]==1'b1)?(a<<5):70'd0;
      
      //produces the result in 2 halves so that the addition is faster
      o1 =  res1+res2+res3;
      o2 =  res4+res5+res6;
      
      //produces the output by concatenating both halves
      o= {o1,o2};
      return o;        
    endfunction
    
    // evaluating partial products(in 2 halves) using the fn_gen_pp function, stage 1
 	  rule rl_partial_product_1_stage1;                                           
      
      //taking 6 bits at a time from the multiplier and producing partial products with the multiplicand seperately for all 6 bit chunks
      rg_partial_product0_1<=fn_gen_pp(rg_operands1,rg_operands2[5:0]);

      rg_partial_product1_1<= fn_gen_pp(rg_operands1,rg_operands2[11:6]);
      
      rg_partial_product2_1<=fn_gen_pp(rg_operands1,rg_operands2[17:12]);
      
      rg_partial_product3_1<=fn_gen_pp(rg_operands1,rg_operands2[23:18]);
      
      rg_partial_product4_1<=fn_gen_pp(rg_operands1,rg_operands2[29:24]);
      
      rg_partial_product5_1<=fn_gen_pp(rg_operands1,rg_operands2[35:30]);
      
      rg_partial_product6_1<=fn_gen_pp(rg_operands1,rg_operands2[41:36]);
      
      rg_partial_product7_1<=fn_gen_pp(rg_operands1,rg_operands2[47:42]);

      rg_partial_product8_1<=fn_gen_pp(rg_operands1,rg_operands2[53:48]);
      
      rg_partial_product9_1<=fn_gen_pp(rg_operands1,rg_operands2[59:54]);
      
      rg_partial_product10_1<=fn_gen_pp(rg_operands1,{1'b0,rg_operands2[64:60]});
      
      //passing the values on to the next stage
      rg_funct3_1 <= rg_funct3_0 ;
      rg_word_1 <= rg_word ;
      rg_valid_1 <= rg_valid ;
      rg_sign_1 <= rg_sign;

    endrule
    
    //adding the 2 halves produced in the previous stage to form the partial product, stage 2
    rule rl_partial_product_stage_2;
      
      //padding them with required no.of zeros according to the 6bit-chunk's position taken from the multiplier(shifting the required amount)
      rg_partial_product0 <= {60'd0,(rg_partial_product0_1[69:0]+rg_partial_product0_1[139:70])};
      rg_partial_product1 <= {54'd0,(rg_partial_product1_1[69:0]+rg_partial_product1_1[139:70]),6'd0};
      rg_partial_product2 <= {48'd0,(rg_partial_product2_1[69:0]+rg_partial_product2_1[139:70]),12'd0};
      rg_partial_product3 <= {42'd0,(rg_partial_product3_1[69:0]+rg_partial_product3_1[139:70]),18'd0};
      rg_partial_product4 <= {36'd0,(rg_partial_product4_1[69:0]+rg_partial_product4_1[139:70]),24'd0};
      rg_partial_product5 <= {30'd0,(rg_partial_product5_1[69:0]+rg_partial_product5_1[139:70]),30'd0};
      rg_partial_product6 <= {24'd0,(rg_partial_product6_1[69:0]+rg_partial_product6_1[139:70]),36'd0};
      rg_partial_product7 <= {18'd0,(rg_partial_product7_1[69:0]+rg_partial_product7_1[139:70]),42'd0};
      rg_partial_product8 <= {12'd0,(rg_partial_product8_1[69:0]+rg_partial_product8_1[139:70]),48'd0};
      rg_partial_product9 <= {6'd0,(rg_partial_product9_1[69:0]+rg_partial_product9_1[139:70]),54'd0};
      rg_partial_product10 <= {(rg_partial_product10_1[69:0]+rg_partial_product10_1[139:70]),60'd0};
      
      //passing the values on to the next stage
      rg_funct3_2 <= rg_funct3_1 ;
      rg_word_2 <= rg_word_1 ;
      rg_valid_2 <= rg_valid_1 ;
      rg_sign_2 <= rg_sign_1;
    endrule
    
    //addition of half of the partial products, stage 3
    rule rl_partial_product_add_stage3;            //3rd stage  
      Bit#(130) v1 =0;
      Bit#(130) v2 =0;
      Bit#(130) v3 =0;
      Bit#(130) v4 =0;
      Bit#(130) v5 =0;
      Bit#(130) v6 =0;

      v1 = pack(rg_partial_product0);
      v2 = pack(rg_partial_product1);
      v3 = pack(rg_partial_product2);
      v4 = pack(rg_partial_product3);
      v5 = pack(rg_partial_product4);
      v6 = pack(rg_partial_product5);


      rg_res<= v1+v2+v3+v4+v5+v6;                     //addition of 6 partial products to get intermediate product
      
      rg_partial_product6_2 <= pack(rg_partial_product6);
      rg_partial_product7_2 <= pack(rg_partial_product7);
      rg_partial_product8_2 <= pack(rg_partial_product8);
      rg_partial_product9_2 <= pack(rg_partial_product9);
      rg_partial_product10_2 <= pack(rg_partial_product10);
     
      //passing the values on to the next stage
      rg_funct3_3 <= rg_funct3_2 ;
      rg_word_3 <= rg_word_2 ;
      rg_valid_3 <= rg_valid_2 ;
      rg_sign_3 <= rg_sign_2;
    endrule
    
    //addition of rest of the partial products with the sum generated in previous stage, stage 4
    rule rl_add_intermediate_products_stage4;
    
      Bit#(130) v1 =0;
      Bit#(130) v2 =0;
      Bit#(130) v3 =0;
      Bit#(130) v4 =0;
      Bit#(130) v5 =0;
      Bit#(130) v6 =0;

      v1 = pack(rg_partial_product6_2);
      v2 = pack(rg_partial_product7_2);
      v3 = pack(rg_partial_product8_2);
      v4 = pack(rg_partial_product9_2);
      v5 = pack(rg_partial_product10_2);
      v6 = pack(rg_res);
    
      rg_out <= v1+v2+v3+v4+v5+v6;                      //final addition of all partial products
      
      //passing the values on to the next stage
      rg_fn3 <= rg_funct3_3 ;
      rg_word_4 <= rg_word_3 ;
      rg_valid_4 <= rg_valid_3 ;
      rg_sign_4 <= rg_sign_3;
    endrule
    
    //sending operands after converting them to positive operands, sending opcode
    method Action send(Bit#(`XLEN) in1, Bit#(`XLEN) in2, Bit#(3) funct3
                                                              `ifdef RV64, Bool word32 `endif );
      Bit#(1) sign1 = funct3[1]^funct3[0];
      Bit#(1) sign2 = pack(funct3[1 : 0] == 1);
      let op1 = unpack({sign1 & in1[valueOf(`XLEN) - 1], in1});
      let op2 = unpack({sign2 & in2[valueOf(`XLEN) - 1], in2});
      
      Bit#(65) opp1 =0;
      Bit#(65) opp2 =0;
      
      //sending the positive version of operands (making them positive if they are negative)
      if ((sign1 & in1[valueOf(`XLEN) - 1])==0) begin opp1 = op1; end
      else begin opp1 = (~op1)+65'd1; end
      if ((sign2 & in2[valueOf(`XLEN) - 1])==0) begin opp2 = op2; end
      else begin opp2 = (~op2)+65'd1; end
      rg_operands1 <= opp1;
      rg_operands2 <= opp2;
      
      rg_funct3_0 <= funct3;
      
      //determining the sign of the final product to correct it in the final stage
      rg_sign <= (sign2 & in2[valueOf(`XLEN) - 1])^(sign1 & in1[valueOf(`XLEN) - 1]);
    `ifdef RV64
      rg_word <= word32;
    `endif
     rg_valid<=1;
    
    endmethod
    
    //Giving appropriate sign to the product, method for receiving the output and valid bit
    method Tuple2#(Bit#(1),Bit#(`XLEN)) receive;
      
      Bool lv_upperbits = unpack(|rg_fn3[1:0]);   //determining whether the upper XLEN bits or lower XLEN bits to send according to the funct3
      
      //making the output correctly signed according to the sign determined in the send stage
      Bit#(130) out=0;
      if (rg_sign_4==1)
        out =~(rg_out)+130'd1;
      else
        out = rg_out;
      
      Bit#(`XLEN) default_out;
      
      if (lv_upperbits) begin
        default_out = out[valueOf(TMul#(2, `XLEN)) - 1 : valueOf(`XLEN)];
        out=0;
        end
      else
        default_out = out[valueOf(`XLEN) - 1:0];

      `ifdef RV64    //implementing RV64 MULW
        if(rg_word_4)
          default_out = signExtend(default_out[31 : 0]);
      `endif
      return tuple2(rg_valid_4,default_out);
    endmethod

  endmodule
endpackage
