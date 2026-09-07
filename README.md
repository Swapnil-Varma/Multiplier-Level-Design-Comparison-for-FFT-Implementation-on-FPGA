# Multiplier Leve Design Comparision for FFT Implementation on FPGA

## Overview

This repository presents the **design, implementation, verification, and comparative analysis of an 8-point Radix-2 Fast Fourier Transform (FFT)** using different multiplier architectures on FPGA.

The primary objective is to investigate how the choice of multiplier architecture inside the FFT butterfly affects important FPGA implementation parameters such as:

* Area / resource utilization
* Timing performance
* Maximum operating frequency
* Power consumption
* Hardware complexity

The FFT architecture is kept functionally equivalent across the different implementations, while the multiplier used in the complex multiplication stage is changed. This allows a fair comparison of the multiplier architectures at the FFT hardware level.

The project is developed using **Verilog HDL** and **Xilinx Vivado**, targeting the **Basys 3 FPGA development board with the Artix-7 XC7A35T FPGA**.

---

## Project Objective

The main objective is to develop a conventional FFT architecture and investigate whether replacing the conventional multiplication hardware with optimized multiplier architectures can improve the overall FPGA implementation.

The following multiplier architectures are implemented and integrated into the FFT:

1. **Array Multiplier**
2. **Vedic Multiplier**
3. **Wallace Tree Multiplier**
4. **Modified Booth Multiplier**

The implementations are evaluated using the same FFT algorithm, input data, precision, and FPGA target wherever applicable.

### Main Comparison Parameters

| Parameter                | Purpose                                         |
| ------------------------ | ----------------------------------------------- |
| LUT Utilization          | Measures combinational FPGA resource usage      |
| Flip-Flop Utilization    | Measures sequential resource usage              |
| Critical Path Delay      | Determines the limiting timing path             |
| Maximum Frequency (Fmax) | Indicates achievable operating frequency        |
| Dynamic Power            | Measures switching-related power                |
| Static Power             | Measures FPGA static power                      |
| Total On-Chip Power      | Overall estimated FPGA power                    |
| Hardware Complexity      | Qualitative comparison of multiplier structures |

---

# FFT Architecture

The project uses an **8-point Radix-2 FFT based on the Butterfly algorithm**.

The basic FFT structure consists of:

* Input data
* Butterfly computation stages
* Complex addition/subtraction
* Twiddle-factor multiplication
* Output data

For an 8-point FFT:

$$
N = 8
$$

and the number of Radix-2 stages is:

$$
\log_2(8) = 3
$$

The same basic FFT concept is maintained across the different multiplier implementations so that the multiplier architecture becomes the primary variable in the comparison.

---

# Implemented FFT Variants

## 1. Basic / Conventional FFT

The `Basic_FFT` directory contains the reference **8-point Radix-2 FFT implementation**.

This design serves as the baseline architecture against which the multiplier-based FFT implementations can be compared.

It includes:

* FFT datapath
* Butterfly architecture
* Complex arithmetic
* Testbench
* Vivado constraints
* MATLAB integration
* Implementation reports

Directory:

```text
Basic_FFT/
├── code/
├── constraints/
├── matlab_integration/
├── reports/
└── testbench/
```

---

## 2. Vedic Multiplier FFT

The `Vedic_FFT` directory contains the FFT implementation using a **Vedic multiplier**.

The Vedic multiplier is based on the **Urdhva Tiryagbhyam** multiplication technique.

The objective is to investigate whether the Vedic multiplication structure can provide improvements in FPGA implementation metrics compared with the conventional multiplier structure.

Directory:

```text
Vedic_FFT/
├── code/
├── constraints/
├── matlab_integration/
├── reports/
└── testbench/
```

---

## 3. Modified Booth Multiplier FFT

The `Modified_Booth_FFT` directory contains the FFT implementation using a **Modified Booth multiplier**.

Modified Booth encoding reduces the number of partial products generated during multiplication and can therefore influence:

* Area
* Delay
* Power
* Overall multiplier complexity

Directory:

```text
Modified_Booth_FFT/
├── code/
├── constraints/
├── matlab_integration/
├── reports/
└── testbench/
```

---

## 4. Wallace Tree Multiplier FFT

The `Wallace_Tree_FFT` directory contains the FFT implementation using a **Wallace Tree multiplier**.

The Wallace Tree structure reduces partial products using parallel reduction, potentially improving multiplication delay at the expense of additional hardware structure.

The architecture is investigated for its impact on:

* Critical path delay
* Maximum frequency
* FPGA resource utilization
* Power consumption

Directory:

```text
Wallace_Tree_FFT/
├── code/
├── constraints/
├── matlab_integration/
├── reports/
└── testbench/
```

---

# Multiplier Implementations

The `Multipliers` directory contains the individual multiplier architectures used in the project.

```text
Multipliers/
├── Array/
├── Modified_Booth/
├── Vedic/
└── Wallace_Tree/
```

Each multiplier can be independently simulated and verified before being integrated into the FFT architecture.

This separation makes it easier to:

* Verify multiplier functionality
* Compare multiplier-level characteristics
* Reuse multiplier modules
* Integrate the architectures into the FFT datapath

---

# MATLAB Integration

MATLAB integration has been added to the FFT implementations for numerical verification.

The MATLAB workflow is based on exchanging test data and FFT results through **CSV files**.

The general verification flow is:

```text
MATLAB
   │
   │ Generate Input
   ▼
CSV Input File
   │
   ▼
Vivado / Verilog Testbench
   │
   │ FFT Processing
   ▼
CSV Output File
   │
   ▼
MATLAB
   │
   │ Compare Results
   ▼
Reference FFT vs FPGA FFT
```

The MATLAB reference FFT can be used to verify the numerical correctness of the hardware implementation.

### Important

The MATLAB integration files should remain in the corresponding:

```text
matlab_integration/
```

directory.

The MATLAB scripts and CSV files should be kept in the expected directory structure described by the README files inside each FFT implementation.

The CSV-based approach makes it possible to use the same input data for:

* MATLAB reference FFT
* Verilog simulation
* Hardware-oriented verification
* Numerical error analysis

---

# Verification Methodology

The project follows a hierarchical verification approach.

### Step 1 — Multiplier Verification

Each multiplier is independently tested using dedicated testbenches.

```text
Multiplier
     ↓
Testbench
     ↓
Expected Product
     ↓
Pass / Fail
```

### Step 2 — FFT Functional Verification

Each FFT architecture is tested using predefined input vectors.

The output generated by the Verilog implementation is compared against the expected FFT output.

### Step 3 — MATLAB Verification

Hardware FFT outputs can be exported through CSV files and compared with MATLAB reference results.

### Step 4 — FPGA Synthesis

After functional verification, the design is synthesized in Vivado.

### Step 5 — Implementation Analysis

Vivado implementation results are used to obtain:

* LUT utilization
* Flip-Flop utilization
* Timing
* Maximum frequency
* Power estimates

---

# Vivado Design Flow

The complete design flow used in this project is:

```text
                 FFT Algorithm
                      │
                      ▼
              Butterfly Design
                      │
                      ▼
             Multiplier Design
                      │
                      ▼
             Functional Simulation
                      │
                      ▼
              MATLAB Verification
                      │
                      ▼
                 RTL Analysis
                      │
                      ▼
                  Synthesis
                      │
                      ▼
                Implementation
                      │
             ┌────────┴────────┐
             ▼                 ▼
       Timing Analysis    Power Analysis
             │                 │
             └────────┬────────┘
                      ▼
             Performance Comparison
```

---

# FPGA Target

| Parameter          | Configuration    |
| ------------------ | ---------------- |
| FPGA Board         | Digilent Basys 3 |
| FPGA Family        | Xilinx Artix-7   |
| FPGA Device        | XC7A35T          |
| HDL                | Verilog          |
| Design Tool        | Xilinx Vivado    |
| FFT Size           | 8-point          |
| FFT Architecture   | Radix-2          |
| Arithmetic         | Fixed-point      |
| Target Application | FPGA-based DSP   |

---

# Repository Structure

The current repository is organized as follows:

```text
Comparative-Analysis-of-FFT-Multiplier-Architectures-on-FPGA/
│
├── Basic_FFT/
│   ├── code/
│   ├── constraints/
│   ├── matlab_integration/
│   ├── reports/
│   └── testbench/
│
├── Modified_Booth_FFT/
│   ├── code/
│   ├── constraints/
│   ├── matlab_integration/
│   ├── reports/
│   └── testbench/
│
├── Vedic_FFT/
│   ├── code/
│   ├── constraints/
│   ├── matlab_integration/
│   ├── reports/
│   └── testbench/
│
├── Wallace_Tree_FFT/
│   ├── code/
│   ├── constraints/
│   ├── matlab_integration/
│   ├── reports/
│   └── testbench/
│
├── Multipliers/
│   ├── Array/
│   ├── Modified_Booth/
│   ├── Vedic/
│   └── Wallace_Tree/
│
├── final_test/
│
└── README.md
```

The repository currently contains these major FFT and multiplier directories.

---

# Comparative Analysis

The final objective of the project is to compare the four multiplier-based FFT implementations under the same FPGA environment.

A typical comparison table is:

| FFT Architecture | LUTs | FFs | Critical Delay | Fmax | Dynamic Power | Total Power |
| ---------------- | ---: | --: | -------------: | ---: | ------------: | ----------: |
| Basic / Array    |    — |   — |              — |    — |             — |           — |
| Vedic            |    — |   — |              — |    — |             — |           — |
| Wallace Tree     |    — |   — |              — |    — |             — |           — |
| Modified Booth   |    — |   — |              — |    — |             — |           — |

> **Note:** The final numerical values should be populated from the Vivado synthesis, implementation, timing, and power reports rather than using theoretical values.

This is important because the FPGA synthesis tool can map different multiplier architectures into LUTs, DSP resources, carry chains, and other FPGA primitives differently.

---

# Why Compare Multiplier Architectures?

Multiplication is an important operation in FFT butterfly processing, particularly during complex multiplication with twiddle factors.

Different multiplier structures generate different hardware characteristics.

### Array Multiplier

**Advantages**

* Simple structure
* Regular layout
* Easy to understand and verify

**Disadvantages**

* Larger number of partial products
* Potentially higher area and delay

### Vedic Multiplier

**Advantages**

* Parallel multiplication structure
* Modular design
* Potentially efficient for FPGA implementation

**Disadvantages**

* Hardware efficiency depends on implementation and synthesis
* May require additional logic for larger operands

### Wallace Tree Multiplier

**Advantages**

* Fast partial-product reduction
* Highly parallel architecture
* Potentially lower multiplication delay

**Disadvantages**

* More complex structure
* Routing and hardware complexity can increase

### Modified Booth Multiplier

**Advantages**

* Reduces partial-product count
* Efficient for signed multiplication
* Can reduce multiplication complexity

**Disadvantages**

* Encoding and control logic add complexity
* Actual FPGA benefit depends on synthesis and target architecture

---

# Final Test

The `final_test` directory is intended for consolidated testing and comparison of the completed FFT architectures.

It can be used to:

* Run common test vectors
* Compare FFT outputs
* Verify consistency between implementations
* Prepare final comparative results

The final comparison should use identical input conditions wherever possible.

---

# Reports

The individual FFT directories contain report-related material associated with the corresponding implementation.

Typical Vivado analysis includes:

```text
RTL Analysis
     │
     ├── RTL Schematic
     │
     ├── Synthesized Design
     │
     ├── Utilization Report
     │
     ├── Timing Report
     │
     └── Power Report
```

These reports are used to determine the hardware characteristics of each implementation.

---

# Expected Outcome

The project aims to determine which multiplier architecture provides the most favorable trade-off between:

* Area
* Power
* Timing
* Frequency
* Hardware complexity

There is **no assumption that one multiplier will be optimal for every metric**.

For example:

* One architecture may minimize LUT usage.
* Another may provide the highest Fmax.
* Another may provide lower estimated power.
* Another may provide the best overall area-performance trade-off.

Therefore, the final conclusion should be based on the **actual Vivado implementation results**.

---

# Applications

The developed FFT architecture and multiplier comparison are relevant to FPGA-based DSP applications such as:

* Digital Signal Processing
* OFDM communication
* Wireless communication
* Software Defined Radio
* Radar signal processing
* Audio processing
* Image processing
* Biomedical signal processing
* FPGA-based real-time signal processing

---

# Reference Work

This project is based on the concept of investigating **power- and area-efficient FFT hardware through multiplier-level architectural optimization**.

The repository is intended as an implementation and experimental study in which different multiplier architectures are integrated into an FFT datapath and evaluated using FPGA implementation metrics.

---

# Current Project Status

### Completed / Implemented

* [x] 8-point Radix-2 FFT architecture
* [x] Conventional / Basic FFT reference implementation
* [x] Array multiplier
* [x] Vedic multiplier
* [x] Wallace Tree multiplier
* [x] Modified Booth multiplier
* [x] FFT integration for different multiplier architectures
* [x] Verilog testbenches
* [x] Functional simulation
* [x] MATLAB CSV-based verification flow
* [x] Vivado synthesis and implementation workflow
* [x] Timing analysis
* [x] Power analysis
* [x] FPGA resource analysis
* [x] Comparative analysis framework

### Future Work

Possible extensions include:

* [ ] 16-point FFT
* [ ] 32-point FFT
* [ ] 64-point FFT
* [ ] Pipelined FFT architecture
* [ ] Higher-throughput FFT architecture
* [ ] Optimization of fixed-point precision
* [ ] DSP-slice-based comparison
* [ ] FPGA hardware validation
* [ ] ASIC-oriented implementation study
* [ ] Automated MATLAB/Vivado verification flow

---

# How to Use

## 1. Clone the Repository

```bash
git clone https://github.com/Swapnil-Varma/Comparative-Analysis-of-FFT-Multiplier-Architectures-on-FPGA.git
```

```bash
cd Comparative-Analysis-of-FFT-Multiplier-Architectures-on-FPGA
```

## 2. Open the Required FFT Project

Choose one of:

```text
Basic_FFT
Modified_Booth_FFT
Vedic_FFT
Wallace_Tree_FFT
```

## 3. Open in Vivado

Open the corresponding Vivado project or add the required Verilog source files, constraints, and testbench files.

## 4. Run Simulation

Run the corresponding testbench and verify that the FFT output matches the expected result.

## 5. Run MATLAB Verification

Use the MATLAB integration files to generate/reference input and compare the hardware FFT output using CSV files.

## 6. Run Synthesis

Run:

```text
Synthesis → Run Synthesis
```

Record the utilization results.

## 7. Run Implementation

Run:

```text
Implementation → Run Implementation
```

Then inspect:

* Timing Summary
* Utilization
* Power
* Critical paths

## 8. Record Results

Add the final results to the comparison table.

---

# Important Notes

### Fixed-Point Arithmetic

The FFT implementations use fixed-point representations. Therefore, small numerical differences between MATLAB floating-point results and Verilog fixed-point results can occur.

When comparing results, consider:

* Quantization
* Rounding
* Truncation
* Signed arithmetic
* Bit width
* Twiddle-factor precision

### Fair Comparison

For a meaningful comparison, keep the following consistent between implementations:

* FFT size
* Input vectors
* Data width
* Twiddle-factor representation
* Clock constraints
* FPGA device
* Vivado configuration
* Synthesis settings
* Implementation settings

Only the multiplier architecture should ideally change when comparing multiplier-level effects.

---

# Author

**Swapnil Varma**

Bachelor of Engineering — Electronics

The Maharaja Sayajirao University of Baroda

---

# License

This project is intended for **educational and research purposes**.

If a formal license file is included in the repository, refer to that license for the applicable terms.

---

## Keywords

`FPGA` `FFT` `Fast Fourier Transform` `Radix-2 FFT` `Verilog` `Vivado` `Basys 3` `Artix-7` `Array Multiplier` `Vedic Multiplier` `Wallace Tree Multiplier` `Modified Booth Multiplier` `DSP` `Digital Signal Processing` `Fixed Point` `MATLAB` `Power Optimization` `Area Optimization` `Timing Analysis` `Hardware Optimization`
