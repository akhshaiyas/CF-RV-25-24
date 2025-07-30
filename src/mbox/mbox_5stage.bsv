package mbox;

import ccore_types      :: *;
`include "Logger.bsv"

// Import the new pipelined integer multiplier module
import int_multiplier_pipelined_5stages :: * ; // <--- NEW IMPORT

import restoring_div  :: * ;
`ifdef async_rst
import SpecialFIFOs_Modified :: * ;
`else
import SpecialFIFOs :: * ;
`endif
import FIFOF          :: * ;
import TxRx           :: * ;
import Assert         :: * ;

typedef struct{
`ifdef RV64
  Bool wordop ;
`endif
  Bit#(`xlen) in1;
  Bit#(`xlen) in2;
  Bit#(3) funct3;
}MBoxIn deriving(Bits, FShow, Eq);

typedef struct{
  Bool mul;
  Bool div;
} MBoxRdy deriving(Bits, FShow, Eq);

interface Ifc_mbox;
  method Action ma_inputs(MBoxIn inputs);
  method MBoxRdy mv_ready;
  method TXe#(Bit#(`xlen)) tx_output;
  `ifdef arith_trap
    method Action ma_arith_trap_en(Bit#(1) en);
    method TXe#(Tuple2#(Bool, Bit#(`causesize))) tx_arith_trap_output;
  `endif
endinterface: Ifc_mbox

`ifdef mbox_noinline
`ifdef core_clkgate
(synthesize,gate_all_clocks)
`else
(synthesize)
`endif
`endif
module mkmbox#(parameter Bit#(`xlen) hartid) (Ifc_mbox);
  String mbox = "";

  // Instantiate the new pipelined multiplier
  Ifc_int_multiplier mul_pipe_ <- mk_int_multiplier; // <--- REPLACED Ifc_combo_mul mul_
  Ifc_restoring_div div_ <- mkrestoring_div(hartid);

  // The FIFO depth for ordering should now consider the maximum latency.
  // Assuming MULSTAGES_TOTAL from the old definition was sufficient or 5 stages.
  // Here, we explicitly use 5 for the multiplier latency.
  FIFOF#(Bool) ff_ordering <- mkUGSizedFIFOF(max(5,2)); // <--- Adjusted FIFO depth for multiplier latency
  TX#(Bit#(`xlen)) tx_mbox_out <- mkTX;
  `ifdef arith_trap
    TX#(Tuple2#(Bool, Bit#(`causesize))) tx_arith_trap_out <- mkTX;
  `endif

  /*doc:rule: */
  rule rl_fifo_full(!tx_mbox_out.u.notFull());
    `logLevel( mbox, 0, $format("[%2d]MBOX: Buffer is FULL",hartid))
    // Dynamic asserts should now check the new multiplier's output validity
    // FIXED: Use unpack to convert Bit#(1) to Bool
    dynamicAssert(!unpack(tpl_1(mul_pipe_.receive)) ,"MUL provided result when O/P FIFO is full");
    dynamicAssert(!div_.mv_output_valid ,"DIV provided result when O/P FIFO is full");
  endrule:rl_fifo_full

  /*doc:rule: */
  rule rl_capture_output(ff_ordering.notEmpty);
    if (ff_ordering.first) begin // mul operation
      // Check the valid bit from the new multiplier's receive method
      // FIXED: Use unpack to convert Bit#(1) to Bool for the if condition
      if (unpack(tpl_1(mul_pipe_.receive))) begin
        let x = tpl_2(mul_pipe.receive); // Extract the result from the tuple
        tx_mbox_out.u.enq(_x);
        `ifdef arith_trap
          tx_arith_trap_out.u.enq(unpack(0)); // Multiplier doesn't generate arithmetic traps based on its interface
        `endif
        ff_ordering.deq;
        `logLevel( mbox, 0, $format("MBOX: Collecting MUL o/p"))
      end
      else
        `logLevel( mbox, 0, $format("MBOX: Waiting for Mul o/p"))
    end
    else if (!ff_ordering.first) begin // div operation
      if (div_.mv_output_valid) begin
        let x <- div.mv_output;
        tx_mbox_out.u.enq(_x);
        `ifdef arith_trap
          tx_arith_trap_out.u.enq(div_.mv_arith_trap_out);
        `endif
        ff_ordering.deq;
        `logLevel( mbox, 0, $format("MBOX: Collecting DIV o/p"))
      end
      else
        `logLevel( mbox, 0, $format("MBOX: Waiting for Div o/p"))
    end
  endrule: rl_capture_output

  method Action ma_inputs(MBoxIn inputs);
  `ifdef ASSERT
    dynamicAssert(ff_ordering.notFull(), "Enquing MBOX inputs to full fifo");
  `endif
    if( inputs.funct3[2] == 0 ) begin // Multiplication ops
      `logLevel( mbox, 0, $format("MBOX: To MUL. Op1:%h Op2:%h ", inputs.in1, inputs.in2 ))
      // Use the new multiplier's send method
      mul_pipe_.send(inputs.in1, inputs.in2, inputs.funct3 `ifdef RV64 ,inputs.wordop `endif );
      ff_ordering.enq(True);
    end
    if (inputs.funct3[2] == 1) begin
      ff_ordering.enq(False);
      `logLevel( mbox, 0, $format("MBOX: To DIV. Op1:%h Op2:%h sign:%b", inputs.in1, inputs.in2, inputs.in1[valueOf(`xlen)-1] ))
      div_.ma_inputs( inputs.in1, inputs.in2, inputs.funct3 `ifdef RV64 ,inputs.wordop `endif ) ;
    end
  endmethod

  // The 'ready' signal for the new multiplier isn't explicitly exposed as 'mv_ready'
  // It's an always_ready method. So, the multiplier is always ready to accept input.
  // We only need to check if the ordering FIFO is not full.
  method mv_ready= MBoxRdy{mul: ff_ordering.notFull, div: div_.mv_ready && ff_ordering.notFull()};

  method tx_output = tx_mbox_out.e;
  `ifdef arith_trap
    method Action ma_arith_trap_en(Bit#(1) en);
      `logLevel( mbox, 0, $format("MBOX: arith_en: %h ", en ))
        div_.ma_div_arith_trap_en(en);
    endmethod
    method tx_arith_trap_output = tx_arith_trap_out.e;
  `endif
endmodule
endpackage
