package mbox;

import ccore_types    :: *;
`include "Logger.bsv"

import int_multiplier_pipelined_4stages :: *;  // NEW IMPORT
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
(*synthesize,gate_all_clocks*)
`else
(*synthesize*)
`endif
`endif
module mkmbox#(parameter Bit#(`xlen) hartid) (Ifc_mbox);
  String mbox = "";

  Ifc_int_multiplier mul_ <- mk_int_multiplier;  // CHANGED: Replaced combo_mul
  Ifc_restoring_div div_ <- mkrestoring_div(hartid);

  FIFOF#(Bool) ff_ordering <- mkUGSizedFIFOF(max(`MULSTAGES_TOTAL,2));
  TX#(Bit#(`xlen)) tx_mbox_out <- mkTX;
  `ifdef arith_trap
    TX#(Tuple2#(Bool, Bit#(`causesize))) tx_arith_trap_out <- mkTX;
  `endif

  rule rl_fifo_full(!tx_mbox_out.u.notFull());
    `logLevel( mbox, 0, $format("[%2d]MBOX: Buffer is FULL",hartid))
    dynamicAssert(!ff_ordering.first && !div_.mv_output_valid,
                "MUL/DIV provided result when O/P FIFO is full");
  endrule

  rule rl_capture_output(ff_ordering.notEmpty);
    if (ff_ordering.first) begin // mul operation
      match {.valid, ._x} = mul_.receive();  // CHANGED: New multiplier interface
      if (valid == 1) begin
        tx_mbox_out.u.enq(_x);
        `ifdef arith_trap
          tx_arith_trap_out.u.enq(unpack(0));
        `endif
        ff_ordering.deq;
        `logLevel( mbox, 0, $format("MBOX: Collecting MUL o/p"))
      end
      else
        `logLevel( mbox, 0, $format("MBOX: Waiting for Mul o/p"))
    end
    else begin // div operation
      if (div_.mv_output_valid) begin
        let _x <- div_.mv_output;
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
  endrule

        method Action ma_inputs(MBoxIn inputs);
  `ifdef ASSERT
    dynamicAssert(ff_ordering.notFull(), "Enquing MBOX inputs to full fifo");
  `endif
    if( inputs.funct3[2] == 0 ) begin // Multiplication ops
      `logLevel( mbox, 0, $format("MBOX: To MUL. Op1:%h Op2:%h ", inputs.in1, inputs.in2 ))
      mul_.send(inputs.in1, inputs.in2, inputs.funct3 `ifdef RV64 ,inputs.wordop `endif );  // CHANGED: New interface
      ff_ordering.enq(True);
    end
    else begin // Division ops
      ff_ordering.enq(False);
      `logLevel( mbox, 0, $format("MBOX: To DIV. Op1:%h Op2:%h sign:%b", inputs.in1, inputs.in2, inputs.in1[valueOf(`xlen)-1] ))
      div_.ma_inputs( inputs.in1, inputs.in2, inputs.funct3 `ifdef RV64 ,inputs.wordop `endif );
    end
  endmethod

  method mv_ready = MBoxRdy{
    mul: ff_ordering.notFull,  // CHANGED: New multiplier is always ready
    div: div_.mv_ready && ff_ordering.notFull()
  };

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
