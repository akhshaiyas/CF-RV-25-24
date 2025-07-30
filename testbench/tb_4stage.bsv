package tb_new5;

import int_multiplier_pipelined_4stages :: *;
import Randomizable :: *;
`include "Logger.bsv"
`include "mbox_parameters.bsv"

module mk_tb_int_multiplier_pipelined_4stages();

    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bit#(32)) feed  <- mkReg(0);
    Reg#(Bit#(64)) rand1 <- mkReg(0);
    Reg#(Bit#(64)) rand2 <- mkReg(0);

    int_multiplier_pipelined_4stages::Ifc_int_multiplier dut <- int_multiplier_pipelined_4stages::mk_int_multiplier();

    Randomize#(Bit#(64)) rand_in1 <- mkConstrainedRandomizer(64'd0, 64'hffff_ffff_ffff_ffff);
    Randomize#(Bit#(64)) rand_in2 <- mkConstrainedRandomizer(64'd0, 64'hffff_ffff_ffff_ffff);

    rule init(feed == 0);
        rand_in1.cntrl.init();
        rand_in2.cntrl.init();
        feed <= 1;
    endrule

    rule rl_stage1(feed == 1);
        let a <- rand_in1.next();
        let b <- rand_in2.next();
        rand1 <= a;
        rand2 <= b;
        dut.send(a, b, 3'b000
        `ifdef RV64
            , False
        `endif
        );
        feed <= 2;
    endrule

    rule rl_stage2(feed == 2);
        dut.send(rand1, rand2, 3'b001
        `ifdef RV64
            , False
        `endif
        );
        feed <= 3;
    endrule

    rule rl_stage3(feed == 3);
        dut.send(rand1, rand2, 3'b010
        `ifdef RV64
            , False
        `endif
        );
        feed <= 4;
    endrule

    rule rl_stage4(feed == 4);
        dut.send(rand1, rand2, 3'b011
        `ifdef RV64
            , False
        `endif
        );
        feed <= 5;
    endrule

    rule rl_stage5(feed == 5);
        dut.send(rand1, rand2, 3'b000
        `ifdef RV64
            , True
        `endif
        );
        feed <= 1;
    endrule

    rule receive;
        match {.valid, .out} = dut.receive();
        Bit#(3) func =
            (feed == 1) ? 3'b000 :
            (feed == 2) ? 3'b001 :
            (feed == 3) ? 3'b010 :
            (feed == 4) ? 3'b011 : 3'b000;
        $display("Cycle %0d : Valid %0d : funct3 %0b OUT %0h", cycle, valid, func, out);
    endrule

    rule cycling;
        cycle <= cycle + 1;
        if (cycle > 200000)
            $finish(0);
    endrule

endmodule
endpackage
