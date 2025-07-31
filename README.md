# Replacement of Integer Multiplier in SHAKTI C-Class Core

C-Class core RTL implementation and simulation: Integrate atleast two different integer multipliers (with different latencies) from Shakti mbox repository and evaluate using set of benchmarks given by Shakti team. Compare performance of all multipliers. Extra credit: Running comparisons on FPGA (with matrix multiplication and integer list tests)
al design 
---

##  Directory Structure

```bash
├── src/
│   ├── mbox/
│   │   ├── mbox_comb.bsv
│   │   ├── mbox_4stage.bsv
│   │   ├── mbox_5stage.bsv
│   ├── includes/
│   │   ├── mbox_parameters.bsv
│   │   ├── Logger.bsv
│   │   ├── ccore_params.defines
│   │   ├── ccore_types.bsv
│   ├── wrappers/
│   │   ├── combo.bsv
│   │   ├── restoring_div.bsv
│   ├── int_multiplier_pipelined_4stages.bsv
│   ├── int_multiplier_pipelined_5stages.bsv
├── custom_isa/
│   ├── mul.S
│   ├── mulh.S
│   ├── mulhsu.S
│   ├── mulhu.S
├── config/
│   ├── core64.yaml
│   ├── core64_4stage.yaml
│   ├── core64_5stage.yaml
├── testbench/
│   ├── tb_4stage.bsv
│   ├── tb_5stage.bsv
├── Results/
│   ├── isa_tests/
│   │   ├── mul.md
│   │   ├── mulh.S
│   │   ├── mulhsu.S
│   │   ├── mulhu.S
│   │   ├── mulw.S
│   │   ├── Readme.md
│   ├── 4stage_isa_tests.md
│   ├── 5stage_isa_tests.md
│   ├── 4stage_tb.md
│   ├── 5stage_tb.md
│   ├── testing_bsc.md
├── docs/
│   ├── Week3.md
│   ├── Workflow.md
│   ├── RSICV_report.pdf
├── README.md


 ```
---

##  Features

- **Configurable Multiplier**: Choose between 4-stage or 5-stage pipelined integer multipliers by changing one file and config.
- **RV64M Compliance**: Complete support for RISC-V multiplication instructions (MUL, MULH, MULHSU, MULHU, MULW).
- **Modular BSV Design**: Clean, scalable BSV modules—easy to extend or modify pipeline depth.
- **ISA and Benchmark Testing**: Validated with full RISC-V ISA tests and CoreMark for real workload performance.
- **Documented Results**: Test bench code and output screenshots provided for reproducibility.

---

##  Getting Started

### Prerequisites

- SHAKTI C-Class Source (v4.6.0+)
- Bluespec SystemVerilog Toolchain (BSC)
- RISC-V GCC Toolchain
- GNU Make (or similar build toolchain)
- Unix-like environment

---

##  Repo Setup

```bash
git clone https://github.com/akhshaiyas/CF-RV-25-24.git
cd CF-RV-25-24
 ```
# Add or link your SHAKTI C-Class and mbox code as required
---
##  Switching Between Multiplier Versions

Choose which `mbox` (see `src/mbox/`) and config YAML to use:
---
### For 4-stage pipeline:

```bash
cp src/mbox/mbox_4stage.bsv src/mbox.bsv
cp config/core64_4stage.yaml config/core64.yaml
make
 ```
### For 5-stage pipeline:

```bash
cp src/mbox/mbox_5stage.bsv src/mbox.bsv
cp config/core64_5stage.yaml config/core64.yaml
make
 ```
##  ISA Test and Benchmarks

- Run BSV testbenches (`testbench/`) to check functional correctness:
  - `tb_4stage.bsv` (4-stage)
  - `tb_5stage.bsv` (5-stage)

- Validate with `riscv-tests`. Output screenshots and logs are located in:
  - `results/4stage_isa_tests.md/`
  - `results/5stage_isa_tests.md/`

---

##  Documentation

- Refer to [`docs/report.pdf`](docs/report.pdf) for:
  - Technical background
  - Design choices
  - Integration details
  - Benchmarking results

- YAML files in `/config/` highlight top-level configuration differences for each multiplier pipeline.

- Screenshots and output logs of all ISA tests and testbench runs are available in `results/isa_tests/`.

---
## Authors and Supervisors
### Akhshaiya S 
### Krishnashree D

Mentors: Dr. Nitya Ranganathan, Mr. Sriram (SHAKTI Team)

 License
MIT License (LICENSE)

IITM/Institutional License (LICENSE.iitm) where referenced
---
#### For detailed integration, module, and benchmarking info, consult /docs/report.pdf and source code comments. All test bench and RISC-V compliance results are included for clarity and reproducibility.
