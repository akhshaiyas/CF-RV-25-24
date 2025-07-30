#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64UF
RVTEST_CODE_BEGIN

    li a0, 6
    li a1, 7
    mul a2, a0, a1    # a2 = 6 * 7 = 42
    li t0, 42
    bne a2, t0, fail

    RVTEST_PASS

fail:
    RVTEST_FAIL

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
result: .space 8
RVTEST_DATA_END
