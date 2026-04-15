# SystemVerilog Verification Portfolio

Functional verification projects built with class-based SystemVerilog testbenches, progressing from simple sequential blocks to interface and bus protocol verification.

---

## About

This portfolio demonstrates a structured approach to VLSI functional verification — starting from foundational RTL blocks and scaling to protocol-level verification. Each project includes a verification plan, class-based testbench architecture (Transaction → Generator → Driver → Monitor → Scoreboard), functional coverage, SVA assertions, and documented results.

---

## Projects

| # | Project | DUT Type | Transactions | Result | Status |
|---|---------|----------|-------------|--------|--------|
| 01 | [D Flip-Flop Verification](https://github.com/Mohank-VLSI-Verification/sv-verification-portfolio/tree/main/01_dff_verification) | Sequential | 30 | PASS:30 FAIL:0 | ✅ Complete |
| 02 | [FIFO Verification](https://github.com/Mohank-VLSI-Verification/sv-verification-portfolio/tree/main/02_fifo_verification) | Memory | 30 | PASS:11 FAIL:0 | ✅ Complete |
| 03 | [SPI Verification](https://github.com/Mohank-VLSI-Verification/sv-verification-portfolio/tree/main/03_spi_verification) | Interface Protocol | 4 | PASS:4 FAIL:0 | ✅ Complete |
| 04 | [UART Verification](https://github.com/Mohank-VLSI-Verification/sv-verification-portfolio/tree/main/04_uart_verification) | Interface Protocol | 5 | PASS:5 FAIL:0 | ✅ Complete |
| 05 | [I2C Verification](https://github.com/Mohank-VLSI-Verification/sv-verification-portfolio/tree/main/05_i2c_verification) | Interface Protocol | 20 | PASS:13 FAIL:7 | ⚠️ Read bug found |
| 06 | [AXI-Lite Verification](https://github.com/Mohank-VLSI-Verification/sv-verification-portfolio/tree/main/06_axilite_verification) | Bus Protocol | 10 | PASS:10 FAIL:0 | ✅ Complete |

---

## Skills Demonstrated

| Domain | Details |
|--------|---------|
| **Language** | SystemVerilog (IEEE 1800-2017) |
| **Testbench** | Class-based layered architecture, constrained random verification |
| **Assertions** | SystemVerilog Assertions (SVA) — immediate and concurrent |
| **Coverage** | Functional coverage (covergroups, cross coverage, bins) |
| **Protocols** | SPI, UART, I2C, AXI4-Lite |
| **Tools** | Vivado XSIM 2025.2, VS Code |
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
├── 05_i2c_verification/
└── 06_axilite_verification/
```

---

## How to Run

Each project requires only 2 files in Vivado XSIM: `rtl/*.sv` and `tb/tb_top.sv`.

```
1. Create Vivado project → Add simulation sources (2 files only)
2. Set 'tb' as top module
3. Run Behavioral Simulation
4. Type 'run all' in Tcl Console
5. Check scoreboard summary in Tcl Console output
```

---

## Author

Mohan Kalaiselvan
Verification Engineer
Learning Path: SystemVerilog & UVM Fundamentals

---

## License

This repository is for educational and portfolio purposes.
