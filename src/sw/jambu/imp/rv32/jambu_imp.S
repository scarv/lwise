#include "zbkb.h"
#include "zbkx.h"
#include "ise.h"

// ----------------------------------------------------------------------------
// Register Allocation
// (Use caller-saved registers to save push/pop instructions)  
//
// a2~a5: state
// t0~t4: tmp registers
// a6, a7, t5, t6: key 
// ----------------------------------------------------------------------------

// prologue + epilogue 

.macro JAMBU_PROLOGUE
.endm

.macro JAMBU_EPILOGUE
  ret
.endm


// load state + store state

.macro JAMBU_LDSTATE addr, s0, s1, s2, s3
  lw   \s0,  0(\addr)
  lw   \s1,  4(\addr)
  lw   \s2,  8(\addr)
  lw   \s3, 12(\addr)
.endm

.macro JAMBU_STSTATE s0, s1, s2, s3
  sw   \s0,  0(a0)
  sw   \s1,  4(a0)
  sw   \s2,  8(a0)
  sw   \s3, 12(a0)
.endm


// operations

.macro JAMBU_STATEUPD_STEP0 r0, s0, s1, t0
#if   (JAMBU_RV32_TYPE2)
  jambu.fsri   \r0, \s0, \s1, 15
#elif (JAMBU_RV32_TYPE3)
  jambu.fsr.15 \r0, \s0, \s1
#else
  srli \r0, \s0, 15
  slli \t0, \s1, 17
  or   \r0, \r0, \t0
#endif  
.endm

.macro JAMBU_STATEUPD_STEP1 r0, s0, s1, t0
#if (JAMBU_RV32_TYPE2)
  jambu.fsri   \r0, \s0, \s1, 6
#elif (JAMBU_RV32_TYPE3)
  jambu.fsr.6  \r0, \s0, \s1
#else
  srli \r0, \s0, 6
  slli \t0, \s1, 26
  or   \r0, \r0, \t0
#endif  
.endm

.macro JAMBU_STATEUPD_STEP2 r0, s0, s1, t0
#if   (JAMBU_RV32_TYPE2)
  jambu.fsri   \r0, \s0, \s1, 21
#elif (JAMBU_RV32_TYPE3)
  jambu.fsr.21 \r0, \s0, \s1
#else
  srli \r0, \s0, 21
  slli \t0, \s1, 11
  or   \r0, \r0, \t0
#endif  
.endm

.macro JAMBU_STATEUPD_STEP3 r0, s0, s1, t0
#if   (JAMBU_RV32_TYPE2)
  jambu.fsri   \r0, \s0, \s1, 27
# elif (JAMBU_RV32_TYPE3)
  jambu.fsr.27 \r0, \s0, \s1
#else
  srli \r0, \s0, 27
  slli \t0, \s1, 5
  or   \r0, \r0, \t0
#endif  
.endm

.macro JAMBU_STATEUPD_STEP4 s0, k0, t1, t2, t3, t4
  and  \t2, \t2, \t3
  xnor \t2, \t1, \t2
  xor  \t2, \t2, \t4
  xor  \t2, \t2, \k0
  xor  \s0, \s0, \t2
.endm


// operations in each round

.macro JMABU_ROUND s0, s1, s2, s3, k0, t1, t2, t3, t4, t5 
  JAMBU_STATEUPD_STEP0 \t1, \s1, \s2, \t5
  JAMBU_STATEUPD_STEP1 \t2, \s2, \s3, \t5
  JAMBU_STATEUPD_STEP2 \t3, \s2, \s3, \t5
  JAMBU_STATEUPD_STEP3 \t4, \s2, \s3, \t5
  JAMBU_STATEUPD_STEP4 \s0, \k0, \t1, \t2, \t3, \t4
.endm


// state_update

.section .text

.global state_update

state_update:
  JAMBU_PROLOGUE
  JAMBU_LDSTATE  a0, a3, a4, a5, a6
  JAMBU_LDSTATE  a1, a7, t5, t6, a1
  // 
  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0

  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0

  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0

  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0

  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0
  // 
  addi a2, a2, -640
  beqz a2, JAMBU_END
  // 
  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0

  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0

  JMABU_ROUND    a3, a4, a5, a6, a7, t1, t2, t3, t4, t0
  JMABU_ROUND    a4, a5, a6, a3, t5, t1, t2, t3, t4, t0
  JMABU_ROUND    a5, a6, a3, a4, t6, t1, t2, t3, t4, t0
  JMABU_ROUND    a6, a3, a4, a5, a1, t1, t2, t3, t4, t0
  //
JAMBU_END: 
  JAMBU_STSTATE  a3, a4, a5, a6
  JAMBU_EPILOGUE
