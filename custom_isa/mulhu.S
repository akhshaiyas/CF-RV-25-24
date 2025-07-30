#include "riscv_test.h"
#include "test_macros.h"

// Using RVTEST_RV64UF for RV64 targets.
RVTEST_RV64UF
RVTEST_CODE_BEGIN

    // Test Case: mulhu(2^32, 2^32) on RV64
    // unsigned (1 << 32) * unsigned (1 << 32)
    // 0x0000000100000000 * 0x0000000100000000 (both 64-bit unsigned)
    //
    // Full 128-bit product: 0x00000000_00000001_00000000_00000000 (2^64)
    // The upper 64 bits of this 128-bit product are 0x00000001.

    li a0, 0x100000000      // a0 = 2^32 (unsigned 64-bit)
    li a1, 0x100000000      // a1 = 2^32 (unsigned 64-bit)
    mulhu a2, a0, a1        // a2 = mulhu(a0, a1)
                            // Expected a2 = 0x0000000000000001

    li t0, 0x1              // Expected value for a2 (64-bit 1)
    bne a2, t0, fail        // Branch to 'fail' if a2 does not match expected

RVTEST_PASS // If we reach here, the test passed

fail:
    RVTEST_FAIL // If we reach here, the test failed

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
  // For RV64, result should be 8 bytes
  // result: .space 8
RVTEST_DATA_END
