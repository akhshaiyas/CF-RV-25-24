#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64UF
RVTEST_CODE_BEGIN

    li a0, 6
    li a1, 7
    mulh a2, a0, a1    // a2 = mulh(6, 7). Signed 6*7=42. 64-bit product 0x00000000_0000002A.
                       // Upper 32 bits of 0x00000000_0000002A is 0x00000000.
    li t0, 0           // Expected a2 to be 0 for mulh(6,7)
    bne a2, t0, fail   // Now, a2 (0) will match t0 (0), so it will pass

    RVTEST_PASS

fail:
    RVTEST_FAIL

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
result: .space 8
RVTEST_DATA_END
