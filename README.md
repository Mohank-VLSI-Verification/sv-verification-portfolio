# SystemVerilog Verification Portfolio

Functional verification projects built with class-based SystemVerilog testbenches, progressing from simple sequential blocks to interface and bus protocol verification.

---

## About

This portfolio demonstrates a structured approach to VLSI functional verification — starting from foundational RTL blocks and scaling to protocol-level verification. Each project includes a verification plan, class-based testbench architecture (Transaction → Generator → Driver → Monitor → Scoreboard), functional coverage, SVA assertions, and documented results.

---

## Projects

| # | Project | DUT Type | Status |
|---|---------|----------|--------|
| 01 | [D Flip-Flop Verification](./01_dff_verification/) | Sequential | ✅ Complete |
| 02 | [FIFO Verification](./02_fifo_verification/) | Memory | 🔲 Planned |
| 03 | [SPI Verification](./03_spi_verification/) | Interface Protocol | 🔲 Planned |
| 04 | [UART Verification](./04_uart_verification/) | Interface Protocol | 🔲 Planned |
| 05 | [APB Verification](./05_apb_verification/) | Bus Protocol | 🔲 Planned |
| 06 | [Original Project](./06_original_project/) | TBD | 🔲 Planned |

---

## Skills Demonstrated

| Domain | Details |
|--------|---------|
| **Language** | SystemVerilog (IEEE 1800-2017) |
| **Testbench** | Class-based layered architecture, constrained random verification |
| **Assertions** | SystemVerilog Assertions (SVA) — immediate and concurrent |
| **Coverage** | Functional coverage (covergroups, cross coverage, bins) |
| **Protocols** | SPI, UART, I2C, APB |
| **Tools** | Vivado XSIM, VS Code |
| **Methodology** | Coverage-driven verification, verification planning |

---

## Repository Structure

```
sv-verification-portfolio/
├── README.md
├── 01_dff_verification/
│   ├── README.md              ← verification plan + results
│   ├── rtl/                   ← design under test
│   ├── tb/                    ← testbench components
│   ├── assertions/            ← SVA properties
│   ├── docs/                  ← verification plan, coverage, bug log
│   └── sim/                   ← simulation scripts + waveforms
├── 02_fifo_verification/
├── 03_spi_verification/
├── 04_uart_verification/
├── 05_apb_verification/
└── 06_original_project/
```

---

## How to Run

Each project contains a `sim/` directory with simulation scripts. General flow:

```bash
cd <project>/sim/
# For Vivado XSIM:
xvlog -sv ../rtl/*.sv ../tb/*.sv ../assertions/*.sv
xelab -debug typical tb -s sim_snapshot
xsim sim_snapshot -runall
```

Refer to individual project READMEs for specific instructions.

---

## Author

**Chief**
Verification Engineer (in training)
Learning Path: Namaste FPGA → SystemVerilog & UVM Fundamentals

---

## License

This repository is for educational and portfolio purposes.
