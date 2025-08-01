<img width="1476" height="394" alt="image" src="https://github.com/user-attachments/assets/77892a5f-b629-46db-9ad4-b17e9a3f7e36" />
code: 
from https://gitlab.com/shaktiproject/cores/riscv-tests/-/blob/master/isa/rv64um/mul.S?ref_type=heads
# See LICENSE for license details.

#*****************************************************************************
# mul.S
#-----------------------------------------------------------------------------
#
# Test mul instruction.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Arithmetic tests
  #-------------------------------------------------------------

  TEST_RR_OP(32,  mul, 0x0000000000001200, 0x0000000000007e00, 0x6db6db6db6db6db7 );
  TEST_RR_OP(33,  mul, 0x0000000000001240, 0x0000000000007fc0, 0x6db6db6db6db6db7 );

  TEST_RR_OP( 2,  mul, 0x00000000, 0x00000000, 0x00000000 );
  TEST_RR_OP( 3,  mul, 0x00000001, 0x00000001, 0x00000001 );
  TEST_RR_OP( 4,  mul, 0x00000015, 0x00000003, 0x00000007 );

  TEST_RR_OP( 5,  mul, 0x0000000000000000, 0x0000000000000000, 0xffffffffffff8000 );
  TEST_RR_OP( 6,  mul, 0x0000000000000000, 0xffffffff80000000, 0x00000000 );
  TEST_RR_OP( 7,  mul, 0x0000400000000000, 0xffffffff80000000, 0xffffffffffff8000 );

  TEST_RR_OP(30,  mul, 0x000000000000ff7f, 0xaaaaaaaaaaaaaaab, 0x000000000002fe7d );
  TEST_RR_OP(31,  mul, 0x000000000000ff7f, 0x000000000002fe7d, 0xaaaaaaaaaaaaaaab );

  #-------------------------------------------------------------
  # Source/Destination tests
  #-------------------------------------------------------------

  TEST_RR_SRC1_EQ_DEST( 8, mul, 143, 13, 11 );
  TEST_RR_SRC2_EQ_DEST( 9, mul, 154, 14, 11 );
  TEST_RR_SRC12_EQ_DEST( 10, mul, 169, 13 );

  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  TEST_RR_DEST_BYPASS( 11, 0, mul, 143, 13, 11 );
  TEST_RR_DEST_BYPASS( 12, 1, mul, 154, 14, 11 );
  TEST_RR_DEST_BYPASS( 13, 2, mul, 165, 15, 11 );

  TEST_RR_SRC12_BYPASS( 14, 0, 0, mul, 143, 13, 11 );
  TEST_RR_SRC12_BYPASS( 15, 0, 1, mul, 154, 14, 11 );
  TEST_RR_SRC12_BYPASS( 16, 0, 2, mul, 165, 15, 11 );
  TEST_RR_SRC12_BYPASS( 17, 1, 0, mul, 143, 13, 11 );
  TEST_RR_SRC12_BYPASS( 18, 1, 1, mul, 154, 14, 11 );
  TEST_RR_SRC12_BYPASS( 19, 2, 0, mul, 165, 15, 11 );

  TEST_RR_SRC21_BYPASS( 20, 0, 0, mul, 143, 13, 11 );
  TEST_RR_SRC21_BYPASS( 21, 0, 1, mul, 154, 14, 11 );
  TEST_RR_SRC21_BYPASS( 22, 0, 2, mul, 165, 15, 11 );
  TEST_RR_SRC21_BYPASS( 23, 1, 0, mul, 143, 13, 11 );
  TEST_RR_SRC21_BYPASS( 24, 1, 1, mul, 154, 14, 11 );
  TEST_RR_SRC21_BYPASS( 25, 2, 0, mul, 165, 15, 11 );

  TEST_RR_ZEROSRC1( 26, mul, 0, 31 );
  TEST_RR_ZEROSRC2( 27, mul, 0, 32 );
  TEST_RR_ZEROSRC12( 28, mul, 0 );
  TEST_RR_ZERODEST( 29, mul, 33, 34 );

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END

verifying by running on spike:
<img width="1475" height="755" alt="image" src="https://github.com/user-attachments/assets/ab2243a5-c8c2-4acd-bd2a-284e44c59374" />
