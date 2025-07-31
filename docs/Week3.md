##  Week 3 Progress – 4-Stage Pipelined Multiplier Integration & Testing

---

###  Baseline Evaluation (Before Modification)  
-  Ran RISC-V ISA tests (mul.S,mulh.S,mulhsu.S,mulw.S) for multiplication instructions using the default combinational multiplier.  
-  Executed CoreMark benchmark on the original (unmodified) C-Class core.  
-  Logged outputs to serve as a performance reference for comparison.

---

###  Files Modified (Post-Evaluation)  
1. `mbox.bsv`  
   → Replaced the existing combinational multiplier (`mkcombo_mul`) with the new pipelined multiplier module `mk_int_multiplier`.

2. `int_multiplier_pipelined_4stages.bsv`  
   → Newly added module from mbox implementing the 4-stage pipelined multiplier logic.

3. `core64.yaml`  
   → Updated parameters:
   ```yaml
   int_mul_stages: 4       # Configures the multiplier latency
   verbosity: 4            # Enables detailed simulation and benchmark logging
---

#### Completed running the isa tests (mul.S,mulh.S,mulhsu.S,mulw.S) for the new multiplier module 4stages 
