package tb_new_5stage;

import int_multiplier_pipelined_5stages :: *;
import Randomizable :: *;
import StmtFSM :: *;
`include "Logger.bsv"
`include "mbox_parameters.bsv"

(* synthesize *)
module mk_tb_int_multiplier_pipelined_5stages(Empty);

    // Test Infrastructure
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bit#(32)) tests_passed <- mkReg(0);
    Reg#(Bit#(32)) tests_failed <- mkReg(0);

    // DUT Instantiation
    Ifc_int_multiplier dut <- mk_int_multiplier();

    // Test Case Generation
    Randomize#(Bit#(64)) rand_in1 <- mkConstrainedRandomizer(0, '1);
    Randomize#(Bit#(64)) rand_in2 <- mkConstrainedRandomizer(0, '1);

    // Known-value test cases
    Vector#(16, Tuple4#(Bit#(64), Bit#(64), Bit#(3), Bit#(64))) known_tests = vec(
        // Format: {operand1, operand2, funct3, expected_result}
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0001, 64'h0000_0000_0000_0001, 3'b000, 64'h0000_0000_0000_0001),
        tuple4(64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 3'b000, 64'h0000_0000_0000_0001),
        tuple4(64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, 3'b001, 64'h0000_0000_0000_0000),
        tuple4(64'h7FFF_FFFF_FFFF_FFFF, 64'h7FFF_FFFF_FFFF_FFFF, 3'b000, 64'h3FFF_FFFF_FFFF_FFFF_8000_0000_0000_0001),
        `ifdef RV64
        tuple4(64'h0000_0000_FFFF_FFFF, 64'h0000_0000_0000_0002, 3'b100, 64'hFFFF_FFFF_FFFF_FFFE),
        `endif
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000),
        tuple4(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 3'b000, 64'h0000_0000_0000_0000)
    );

    // Helper functions
    function Bit#(128) signedMul(Bit#(64) a, Bit#(64) b);
        Int#(64) sa = unpack(a);
        Int#(64) sb = unpack(b);
        Int#(128) res = extend(sa) * extend(sb);
        return pack(res);
    endfunction

    function Bit#(128) mul(Bit#(64) a, Bit#(64) b);
        return zeroExtend(a) * zeroExtend(b);
    endfunction

    // Main Test Sequence
    Stmt test_seq = seq
        $display("[TB] Starting 5-stage multiplier verification");

        // Initialize randomizers
        rand_in1.cntrl.init();
        rand_in2.cntrl.init();

        // Phase 1: Known-value tests
        $display("[TB] Running known-value tests...");
        for (Integer i = 0; i < 16; i = i + 1) seq
            let {op1, op2, funct3, expected} = known_tests[i];

            // Send operation
            dut.send(op1, op2, funct3
            `ifdef RV64
                , False  // wordop
            `endif
            );

            // Wait 5 cycles for pipeline
            repeat(5) seq
                cycle <= cycle + 1;
            endseq

            // Check result
            action
                let {valid, result} = dut.receive();
                if (!valid) begin
                    $display("[ERROR] Test %0d: No valid output!", i);
                    tests_failed <= tests_failed + 1;
                end
                else if (result != expected) begin
                    $display("[ERROR] Test %0d: Expected %0h, Got %0h",
                            i, expected, result);
                    tests_failed <= tests_failed + 1;
                end
                else begin
                    $display("[PASS] Test %0d: Result matches", i);
                    tests_passed <= tests_passed + 1;
                end
            endaction
        endseq

        // Phase 2: Random tests
        $display("[TB] Running random tests...");
        repeat (1000) seq
            // Get random inputs
            let op1 <- rand_in1.next();
            let op2 <- rand_in2.next();

            // Test all funct3 modes
            for (Bit#(3) funct3 = 0; funct3 < 4; funct3 = funct3 + 1) seq
                // Send operation
                dut.send(op1, op2, funct3
                `ifdef RV64
                    , False  // wordop
                `endif
                );

                // Wait 5 cycles
                repeat(5) seq
                    cycle <= cycle + 1;
                endseq

                // Verify result
                action
                    let {valid, result} = dut.receive();
                    if (!valid) begin
                        $display("[ERROR] Random test failed - no valid output");
                        tests_failed <= tests_failed + 1;
                    end
                    else begin
                        // Compute expected (golden reference)
                        Bit#(128) expected;
                        case (funct3)
                            3'b000: expected = signedMul(op1, op2)[63:0];  // MUL
                            3'b001: expected = signedMul(op1, op2)[127:64]; // MULH
                            3'b010: expected = mul(op1, op2)[127:64];       // MULHSU
                            3'b011: expected = mul(op1, op2)[127:64];      // MULHU
                        endcase

                        if (result != expected[63:0]) begin
                            $display("[ERROR] funct3=%0b: op1=%0h op2=%0h", funct3, op1, op2);
                            $display("        Expected %0h, Got %0h", expected[63:0], result);
                            tests_failed <= tests_failed + 1;
                        end
                        else begin
                            tests_passed <= tests_passed + 1;
                        end
                    end
                endaction
            endseq
        endseq

        // Phase 3: RV64 MULW tests (if applicable)
        `ifdef RV64
        $display("[TB] Running RV64 MULW tests...");
        repeat (100) seq
            let op1 <- rand_in1.next();
            let op2 <- rand_in2.next();

            dut.send(op1, op2, 3'b000, True);  // MULW

            repeat(5) seq
                cycle <= cycle + 1;
            endseq

            action
                let {valid, result} = dut.receive();
                Bit#(32) op1_32 = truncate(op1);
                Bit#(32) op2_32 = truncate(op2);
                Bit#(32) expected = op1_32 * op2_32;

                if (!valid) begin
                    $display("[ERROR] MULW: No valid output");
                    tests_failed <= tests_failed + 1;
                end
                else if (signExtend(result[31:0]) != signExtend(expected)) begin
                    $display("[ERROR] MULW: op1=%0h op2=%0h", op1, op2);
                    $display("        Expected %0h, Got %0h", expected, result[31:0]);
                    tests_failed <= tests_failed + 1;
                end
                else begin
                    tests_passed <= tests_passed + 1;
                end
            endaction
        endseq
        `endif

        // Test Summary
        $display("[TB] ========== TEST SUMMARY ==========");
        $display("[TB] Cycles run    : %0d", cycle);
        $display("[TB] Tests passed  : %0d", tests_passed);
        $display("[TB] Tests failed  : %0d", tests_failed);
        $display("[TB] ==================================");

        if (tests_failed == 0) begin
            $display("[TB] ALL TESTS PASSED!");
            $finish(0);
        end
        else begin
            $display("[TB] TEST FAILURES DETECTED!");
            $finish(1);
        end
    endseq;

    // Debugging Rules
    rule debug_cycle;
        cycle <= cycle + 1;
    endrule

    // Run the test sequence
    mkAutoFSM(test_seq);

endmodule

endpackage
