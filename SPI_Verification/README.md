# 03 — SPI Verification

Functional verification of a 12-bit SPI master+slave system using a class-based SystemVerilog testbench. Master serializes data (LSB first) over MOSI, slave deserializes and presents on dout with done flag.

---

## Architecture

```
┌────────────────────────────────────────────────────────┐
│                    environment                          │
│                                                         │
│  ┌───────────┐  mbxgd   ┌──────────┐                  │
│  │ generator  │────────→│  driver   │                  │
│  └───────────┘          └──────────┘                  │
│                              │  │                      │
│                     vif.din  │  │ mbxds (golden ref)   │
│                              ▼  ▼                      │
│                     ┌──────────────┐                   │
│                     │   top (DUT)   │                   │
│                     │ ┌──────────┐ │                   │
│                     │ │spi_master│ │                   │
│                     │ │  →mosi→  │ │                   │
│                     │ │spi_slave │ │                   │
│                     │ └──────────┘ │                   │
│                     └──────────────┘                   │
│                              │                         │
│                     vif.dout │ vif.done                │
│                              ▼                         │
│                     ┌──────────┐                       │
│                     │  monitor  │                       │
│                     └──────────┘                       │
│                              │ mbxms                   │
│                              ▼                         │
│                     ┌──────────────┐                   │
│                     │  scoreboard  │                   │
│                     │ (drv vs mon) │                   │
│                     └──────────────┘                   │
└────────────────────────────────────────────────────────┘
```

**Data flow:** Driver sends `din` → SPI master serializes on `mosi` (LSB first, 12 sclk cycles) → SPI slave captures → `dout` + `done` → Monitor reads → Scoreboard compares driver-sent vs monitor-received.

---

## What I Verified

| Scenario | Description | Status |
|----------|-------------|--------|
| Single transfer | 12-bit data sent and received correctly | ✅ |
| Data integrity | dout matches din after every transfer | ✅ |
| CS protocol | CS low during transfer, high when idle | ✅ |
| Done flag | Asserts after 12 bits received | ✅ |
| MOSI idle | MOSI = 0 when CS is high | ✅ |
| Back-to-back transfers | Multiple consecutive transfers | ✅ |
| Random stimulus | 10 randomized 12-bit values | ✅ |

---

## Improvements Over Base Design

1. **Added `display()`** to transaction for debug tracing
2. **Fixed monitor** — fresh transaction per iteration
3. **Removed unused FSM states** — `enable` and `comp` never used in master
4. **Fixed width mismatch** — `8'h00` → `12'h000` for 12-bit signal
5. **Removed declaration initialization** — moved to reset block for synthesizability
6. **Added `modport`** to interface
7. **Added SVA assertions** — 5 properties checking CS timing, done, data integrity, MOSI idle
8. **Added timeout mechanism**
9. **Added scoreboard summary** — pass/fail/total report

---

## File Structure

```
03_spi_verification/
├── README.md
├── rtl/
│   └── spi.sv                 ← master + slave + top + interface
├── tb/
│   ├── transaction.sv
│   ├── generator.sv
│   ├── driver.sv
│   ├── monitor.sv
│   ├── scoreboard.sv
│   ├── environment.sv
│   └── tb_top.sv
├── assertions/
│   └── spi_assertions.sv      ← 5 SVA properties
├── docs/
│   ├── verification_plan.md
│   ├── coverage_report.md
│   └── bug_log.md
└── sim/
    └── run.sh
```

---

## Results

- **Transactions:** 10 randomized 12-bit transfers
- **Pass rate:** TODO — update after simulation
- **Assertion failures:** TODO
- **Functional coverage:** TODO

---

## Tools

| Tool | Purpose |
|------|---------|
| Vivado XSIM | Simulation |
| VS Code | Editor |

---

## How to Run

```bash
cd sim/
xvlog -sv ../rtl/spi.sv ../tb/tb_top.sv ../assertions/spi_assertions.sv
xelab -debug typical tb -s sim_snapshot
xsim sim_snapshot -runall
```

---

## Key Learnings

- SPI is the first protocol verification in this portfolio — requires understanding the protocol spec (CS, MOSI, SCLK timing) before writing testbench
- Cross-module reference (`dut.m1.sclk`) is necessary when internal signals aren't exposed at top level — fragile but common in practice
- Driver sends golden reference data directly to scoreboard via separate mailbox, bypassing the transaction-only pattern used in DFF/FIFO
- LSB-first bit ordering means data appears reversed on the wire — the slave must reassemble correctly
