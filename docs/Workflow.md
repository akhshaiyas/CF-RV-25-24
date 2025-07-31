## CF-RV-25-24
## Team Members - Akhshaiya S & Krishnashree D
## Problem Statement
C-Class core RTL implementation and simulation: Integrate atleast two different integer multipliers (with different latencies) from Shakti mbox repository and evaluate using set of benchmarks given by Shakti team. Compare performance of all multipliers. Extra credit: Running comparisons on FPGA (with matrix multiplication and integer list tests)	

## Workflow
## 1. Build Environment Setup

- Build RISC-V GCC Toolchain  (spike)
  https://github.com/riscv-collab/riscv-gnu-toolchain

- Build BSC Simulator  
  https://github.com/B-Lang-org/bsc

---

## 2. Verify Pipelined Multiplier in Isolation

- Use:  
  https://gitlab.com/shaktiproject/cores/mbox/-/blob/master/pipelined_multiplier/int_multiplier_pipelined_4stages.bsv  
  https://gitlab.com/shaktiproject/cores/mbox/-/blob/master/pipelined_multiplier/int_multiplier_pipelined_5stages.bsv

- Write Bluespec testbenches for:
  - Signed and unsigned multiplication
  - Edge cases (zero, negative)
  - Matrix multiplication

- Simulate using BSC and validate output

- Write matching RISC-V assembly programs

- Run using Spike and compare with Bluespec results

---

## 3. Multiplier Integration in C-Class

- Place the chosen multiplier `.bsv` file in the same directory as `mbox.bsv`

- Write a wrapper module (e.g., `pipelined_mul_wrapper.bsv`) to adapt interface if needed

- Replace in `mbox.bsv`:
  `Ifc_combo_mul mul_ <- mkcombo_mul;`  
  with either the new multiplier or its wrapper:  
  `Ifc_int_multiplier mul_ <- mk_int_multiplier;`

- Ensure correct connections to methods:
  - `ma_inputs`
  - `mv_output_valid`
  - `mv_output`
  - `mv_ready`

---

## 4. Pipeline and FIFO Logic Adaptation

- Adjust FIFO (`ff_ordering`) depth based on the new multiplier's latency

- Update mbox rules:
  - Capture multiply inputs correctly
  - Dequeue results in correct order
  - Maintain valid signal flow

- Ensure only multiplier path is modified; divider logic remains unchanged

---

## 5. Verification and Validation

- Run a basic BSC simulation to ensure compilation success

- Verify functional correctness using various testcases:
  - Edge values
  - Signed/unsigned mix
  - Timing correctness

- Compare output with Spike for correctness

---

## 6. Performance Evaluation

- Run benchmark suites:
  - riscv-tests 
  - CoreMark

- Collect and log these:
  - Multiply instruction latency
  - Total instruction cycles
  - Core throughput
