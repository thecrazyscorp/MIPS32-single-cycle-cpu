# MIPS32 Single-Cycle CPU & OS

A custom-designed 32-bit MIPS-inspired single-cycle CPU, complete with its own Instruction Set Architecture (ISA), a self-built assembler, and a small "operating system" written in assembly — implemented and verified in **Verilog** using **Intel ModelSim (FPGA Starter Edition)**.

This project was built for **CSE332: Computer Organization and Architecture** at **North South University**, under the guidance of **Dr. Mohammad Abdul Qayum**.

> Design Your Own CPU and Own OS — from ISA design on paper, to an assembler in C++, to working hardware simulated in ModelSim.

---

## Table of Contents

- [Overview](#overview)
- [Project Pipeline](#project-pipeline)
- [1. Instruction Set Architecture (ISA)](#1-instruction-set-architecture-isa)
- [2. Assembler](#2-assembler)
- [3. Operating System (MIPS Assembly)](#3-operating-system-mips-assembly)
- [4. Full CPU (Verilog)](#4-full-cpu-verilog)
- [Simulation & Testing](#simulation--testing)
- [Challenges & Key Learnings](#challenges--key-learnings)
- [Repository Structure](#repository-structure)
- [Tools Used](#tools-used)
- [How to Run](#how-to-run)
- [Acknowledgements](#acknowledgements)

---

## Overview

The goal of this project was to design a complete, working CPU system end-to-end:

1. Design a general-purpose 32-bit **ISA** (instruction formats, opcodes, register set) inspired by MIPS.
2. Build/use an **assembler** to translate assembly programs into machine code (hex).
3. Write a small **"OS"** in assembly — a program that computes the **MAX**, **MIN**, and **MEAN** of ten integers using function calls (`JAL`/`JR`) and a custom division subroutine (since the CPU has no native divide instruction).
4. Implement the **datapath and control unit** in Verilog, extend the base CPU with `JAL` (Jump and Link) and `JR` (Jump Register) support, and verify functional correctness through waveform and register-file inspection in ModelSim.

Since the CPU has no physical I/O (no display, no keyboard), all program inputs/outputs are handled through **register files and data memory**, inspected directly via ModelSim's memory viewer.

---

## Project Pipeline

```
ISA (Homework)  --->  Assembler (Project 1)  --->  Full CPU in Verilog (Project 2)
  Design of              Translates              Complete hardware that
  instruction            assembly to             executes the machine
  types/formats           machine code             instructions in ModelSim
```

---

## 1. Instruction Set Architecture (ISA)

A 32-bit, general-purpose, single-cycle ISA with separate instruction and data memory, modeled closely on MIPS.

### Design Decisions
- **Operands:** 2 source + 1 destination register for arithmetic/logic ops, immediate operands for constant-valued ops, single operand for jumps/shifts.
- **Operand type:** Mostly register-based for speed, with memory-based operands (`LW`/`SW`) for data access, and immediate operands for constants.
- **Operation count:** 20 instructions total, covering arithmetic, logical, branch/jump, memory, and shift categories.

### Instruction Set (20 instructions)

| Category | Instructions |
|---|---|
| Arithmetic | `ADD`, `ADDI`, `SUB` |
| Logical | `AND`, `OR`, `XOR`, `NOR`, `ANDI`, `ORI` |
| Branch / Jump | `BEQ`, `BNE`, `J`, `JAL`, `JR` |
| Memory Access | `LW`, `SW` |
| Shift | `SLL`, `SRL`, `SRA` |

### Instruction Formats

**R-type**

| Field | Opcode | Rs | Rt | Rd | Shamt | Funct |
|---|---|---|---|---|---|---|
| Bits | 6 | 5 | 5 | 5 | 5 | 6 |

**I-type**

| Field | Opcode | Rs | Rt | Immediate |
|---|---|---|---|---|
| Bits | 6 | 5 | 5 | 16 |

**J-type**

| Field | Opcode | Address |
|---|---|---|
| Bits | 6 | 26 |

### Register File (32 registers)

| Register | Name | Purpose |
|---|---|---|
| `$0` | Zero | Always 0 |
| `$1–$3` | Temporary | General purpose |
| `$4–$7` | Argument | Function arguments |
| `$8–$15` | Temporary | Temp variables |
| `$16–$23` | Saved | Saved variables |
| `$24–$25` | Temporary | Temp variables |
| `$26–$27` | Reserved | Reserved for OS |
| `$28` | Global Pointer | — |
| `$29` | Stack Pointer | — |
| `$30` | Frame Pointer | — |
| `$31` | Return Address | Stores return address |

---

## 2. Assembler

Rather than writing machine code by hand, a C++-based assembler ([UpgradedMIPS32Assembler](https://github.com/RoySRC/UpgradedMIPS32Assembler)) was used and adapted to translate `.asm` assembly files into hex machine code for loading directly into the Verilog instruction memory.

### Workflow
1. Clone and compile the assembler (`g++ finalassembler.cpp -o assembler`).
2. Write assembly source (e.g. `smp.asm`).
3. Run the assembler: `./assembler smp.asm output.hex`.
4. Verify the generated hex output against expected machine code.

### Sample Test Program

```mips
.text
main:
    addi $4, $0, 27
    xori $5, $4, 5
    add  $6, $4, $5
    sub  $7, $5, $4
    slt  $8, $7, $6
    or   $9, $7, $0
    and  $10, $7, $0
    sll  $11, $7, 1
    srl  $12, $7, 1
```

The assembler correctly resolved all instructions, arithmetic, logical, and shift operations, and label references — output was manually cross-checked against expected MIPS machine code.

---

## 3. Operating System (MIPS Assembly)

Since the CPU has no OS-level I/O support, a small assembly "OS" was written that:

- Initializes ten integers directly in memory (no data segment support — uses `li` + `sw`).
- Calls three subroutines via `JAL`/`JR`: **MAX**, **MIN**, **MEAN**.
- Uses a provided **division subroutine** for the MEAN calculation, since the CPU lacks a native divide instruction.

**Test input:** `5, 12, 8, 15, 3, 20, 7, 18, 10, 25`

**Expected results:**

| Function | Result |
|---|---|
| MAX | 25 |
| MIN | 3 |
| MEAN | 12 |

All three results were verified in the ModelSim register/memory viewer and matched expected values.

---

## 4. Full CPU (Verilog)

A single-cycle 32-bit MIPS-like processor implementing R-type, I-type, and J-type instructions, extended beyond the base template with:

- **`JAL`** (Jump and Link): jumps to a target address and saves `PC+4` into `$31`.
- **`JR`** (Jump Register): sets `PC` to the value held in a register (`$rs`).

### Core Modules

| Module | Responsibility |
|---|---|
| `MIPS_SCP.v` | Top-level CPU module |
| `MIPS_SCP_tb.v` | Testbench (clock + reset generation) |
| `datapath.v` | Connects ALU, register file, muxes, PC logic |
| `control.v` | Generates control signals from opcode/funct |
| `alu32.v` | 32-bit ALU (add, sub, logic, shifts, comparisons) |
| `regfile32.v` | 32×32-bit register file |
| `rom.v` | Instruction memory (loaded via `$readmemh`) |
| `ram.v` | Data memory |
| `adder.v` | Ripple-carry adder (PC+4, branch target) |
| `mux2.v` | 2-to-1 datapath multiplexer |
| `mux4.v` | 4-to-1 datapath multiplexer (extended for JAL) |
| `signext.v` | Immediate sign-extension |
| `sl2.v` | Shift-left-2 for branch/jump target calc |
| `decoder4.v` | 4-bit decoder |
| `flopr_param.v` | Parameterized flip-flop register (PC) |

### Extending the Control Unit for JAL/JR

| Signal | Width | Purpose |
|---|---|---|
| `RegDst` | 2 bits | Selects write destination (`$rt`, `$rd`, `$31`) |
| `MemtoReg` | 2 bits | Selects write-back data (ALU result, memory, PC+4) |
| `RegWrite` | 1 bit | Enables register write |
| `ALUSrc` | 1 bit | Selects ALU 2nd operand (register vs immediate) |
| `MemWrite` | 1 bit | Enables data memory write |
| `Jump` | 1 bit | Enables jump to `Instr[25:0]` |
| `PCSrc` | 1 bit | Branch decision |
| `ALUControl` | 5 bits | Selects ALU operation (MSB flags `JR`) |

- **JAL** (`opcode = 000011`): `RegDst = 2'b10` (write to `$31`), `MemtoReg = 2'b10` (write `PC+4`), `RegWrite = 1`, `Jump = 1`.
- **JR** (R-type, `funct = 001000`): `ALUControl = 5'b1_1111`; the final PC mux selects `register[rs]` when `ALUControl[4] = 1`.

### Datapath Changes
- Extended `writeopmux` and `resultmux` from 2×1 to 4×1 muxes to support writing to `$31` and writing back `PC+4`.
- Extended `ALUControl` to 5 bits, using the MSB as a dedicated JR flag.
- Added a final PC-selection mux to choose `register[rs]` when the JR flag is set.

---

## Simulation & Testing

Testing was performed in **Intel ModelSim (FPGA Starter Edition)**:

1. Create a ModelSim project and add all Verilog source files.
2. Load the generated instruction hex file into the instruction ROM via `$readmemh("memfile.hex", Imem)`.
3. Run the testbench (`MIPS_SCP_tb.v`) — clock toggles every 50 ns, reset is asserted then de-asserted.
4. Inspect waveforms for PC, ALU results, and control signals.
5. Inspect the register file and data memory viewer to confirm correct final results.

Sample verified results included:
- Arithmetic/logical/shift instruction sequence (`ADDI`, `XORI`, `ADD`, `SUB`, `SLT`, `OR`, `AND`, `SLL`, `SRL`) — all register values matched expected computations.
- MAX-finding subroutine using `JAL`/`JR` — correctly stored the maximum of three values in `$v0`.
- Full MIN/MAX/MEAN OS program — correct results verified in memory.

---

## Challenges & Key Learnings

- **Adding `JR`** required extending the ALU control signal and figuring out a free encoding to flag it without colliding with existing ALU operations.
- **Adding `JAL`** required:
  - A 4-way mux to override the write-register with `$31`.
  - A second 4-way mux for write-back data to support `PC+4`.
  - Careful control-bit design so JAL didn't interfere with normal R-type/I-type decoding.
- **No data segment / no divide instruction:** worked around by initializing values with `li` + `sw`, and using a provided software division subroutine for the MEAN calculation.
- **Debugging control signal alignment:** verified that `RegDst[1:0]`, `MemtoReg[1:0]`, and the JR flag lined up correctly between `Datapath.v` and `control.v`.
- **Branch-target bug discovered:** while testing `BNE`, the PC was observed jumping far beyond the valid instruction memory range (e.g., PC = 148 in a 26-instruction program with max valid PC = 100), suggesting a possible issue in branch target calculation or in the assembler's branch offset generation — documented as an open issue for further investigation.

---

## Repository Structure

```
mips32-single-cycle-cpu/
├── verilog/
│   ├── MIPS_SCP.v          # Top-level CPU module
│   ├── MIPS_SCP_tb.v       # Testbench (clock + reset generation)
│   ├── datapath.v          # Datapath (ALU, regfile, muxes, PC logic)
│   ├── control.v           # Control unit
│   ├── alu32.v              # 32-bit ALU
│   ├── regfile32.v         # Register file
│   ├── rom.v                # Instruction memory
│   ├── ram.v                # Data memory
│   ├── adder.v              # Ripple-carry adder
│   ├── mux2.v               # 2-to-1 multiplexer
│   ├── mux4.v               # 4-to-1 multiplexer
│   ├── signext.v           # Sign extension
│   ├── sl2.v                # Shift-left-2
│   ├── decoder4.v          # 4-bit decoder
│   └── flopr_param.v       # Parameterized flip-flop register
├── assembly/
│   ├── smp2.asm             # Sample arithmetic/logic test program
│   └── sample3.asm         # MAX/MIN/MEAN OS program
├── hex/
│   ├── memfile1.hex        # Assembled machine code (test 1)
│   ├── memfile2.hex        # Assembled machine code (test 2)
│   └── memfile3.hex        # Assembled machine code (test 3)
├── sim/
│   ├── 332project.mpf      # ModelSim project file
│   ├── 332project.cr.mti   # ModelSim compile record
│   ├── rom.v.bak            # Backup of ROM module
│   ├── transcript           # ModelSim simulation transcript log
│   └── vsim.wlf             # ModelSim waveform log
├── docs/
│   └── CSE332_Project_report.pdf
└── README.md
```

---

## Tools Used

- **Verilog HDL** — datapath, control unit, and full CPU implementation
- **Intel ModelSim (FPGA Starter Edition)** — simulation, waveform analysis, register/memory inspection
- **C++ / GCC** — custom assembler compilation
- **Git & WSL (Ubuntu)** — version control and Linux-based toolchain

---

## How to Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/thecrazyscorp/MIPS32-single-cycle-cpu.git
   ```

2. **Assemble a program:**
   ```bash
   cd assembler
   g++ finalassembler.cpp -o assembler
   ./assembler ../assembly/smp.asm output.hex
   ```

3. **Simulate in ModelSim:**
   - Open ModelSim → create a new project.
   - Add all files from `verilog/`.
   - Ensure `rom.v` points to your generated `.hex` file via `$readmemh`.
   - Compile all files, then run:
     ```
     vsim work.MIPS_SCP_tb
     add wave -radix hex /*
     run -all
     ```
   - Inspect the waveform and register file/data memory views to confirm results.

---

## Acknowledgements

- Course: **CSE332 — Computer Organization and Architecture**, North South University
- Instructor: **Dr. Mohammad Abdul Qayum**
- Base assembler adapted from [RoySRC/UpgradedMIPS32Assembler](https://github.com/RoySRC/UpgradedMIPS32Assembler)
- Base single-cycle CPU template provided by the course, extended with `JAL`/`JR`
