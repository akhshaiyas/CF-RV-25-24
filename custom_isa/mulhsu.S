#include "riscv_test.h"
#include "test_macros.h"

// Using RVTEST_RV64UF for RV64 targets, consistent with your toolchain flags.
// This ensures RVTEST_PASS/FAIL macros are aligned with 64-bit environment.
RVTEST_RV64UF
RVTEST_CODE_BEGIN

    // Test Case for RV64: mulhsu(signed -2, unsigned 3)
    // -2 (signed 64-bit) is 0xFFFFFFFFFFFFFFFE
    // 3 (unsigned 64-bit) is 0x0000000000000003
    //
    // Full 128-bit product (signed -2 * unsigned 3) is -6
    // In 128-bit two's complement, -6 is 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFA
    //
    // The mulhsu instruction returns the upper 64 bits of this 128-bit product.
    // So, the expected result is 0xFFFFFFFFFFFFFFFF.

    li a0, -2               // a0 = -2 (signed 64-bit, 0xFFFFFFFFFFFFFFFE)
    li a1, 3                // a1 = 3 (unsigned 64-bit, 0x0000000000000003)
    mulhsu a2, a0, a1       // a2 = mulhsu(a0, a1)
                            // Expected a2 = 0xFFFFFFFFFFFFFFFF

    li t0, 0xFFFFFFFFFFFFFFFF // Expected high part is all ones
    bne a2, t0, fail        // Branch to 'fail' if a2 does not match expected

RVTEST_PASS // If we reach here, the test passed

fail:
    RVTEST_FAIL // If we reach here, the test failed

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
  // This section typically defines 'tohost' and related symbols or includes macros that do.
  // result: .space 8 // For RV64, result should be 8 bytes
RVTEST_DATA_END
