# 04 — UART Verification

Functional verification of a parameterized UART (TX + RX) using a class-based SystemVerilog testbench. Tests both transmit and receive paths with randomized operations.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     environment                          │
│                                                          │
│  ┌───────────┐  mbxgd   ┌───────────┐                  │
│  │ generator  │────────→│   driver   │                  │
│  └───────────┘          └───────────┘                  │
│   (randc: TX/RX)          │  TX: dintx + newd           │
│                           │  RX: rx bit-by-bit          │
│                           │  │ mbxds (golden ref)       │
│                           ▼  ▼                          │
│                    ┌──────────────┐                     │
│                    │  uart_top    │                     │
│                    │ ┌──────────┐ │                     │
│                    │ │  uarttx  │←── dintx, newd       │
│                    │ │  tx out  │──→ tx serial line     │
│                    │ └──────────┘ │                     │
│                    │ ┌──────────┐ │                     │
│                    │ │  uartrx  │←── rx serial line     │
│                    │ │  doutrx  │──→ doutrx, donerx    │
│                    │ └──────────┘ │                     │
│                    └──────────────┘                     │
│                           │                             │
│                           ▼                             │
│                    ┌───────────┐                        │
│                    │  monitor  │                        │
│                    └───────────┘                        │
│                           │ mbxms                       │
│                           ▼                             │
│                    ┌──────────────┐                     │
│                    │  scoreboard  │                     │
│                    └──────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

**Two data paths:**
- **TX path:** Generator → Driver sends `dintx` + `newd` → Master serializes → Monitor captures from `tx` line → Scoreboard compares
- **RX path:** Driver sends random bits on `rx` line → Slave deserializes → Monitor reads `doutrx` → Scoreboard compares

---

## What I Verified

| Scenario | Description | Status |
|----------|-------------|--------|
| TX transfer | 8-bit data transmitted correctly via tx line | ✅ |
| RX transfer | 8-bit data received correctly on doutrx | ✅ |
| TX data integrity | Monitor-captured tx bits match driver-sent data | ✅ |
| RX data integrity | doutrx matches driver-sent rx bits | ✅ |
| Alternating TX/RX | randc ensures both paths exercised equally | ✅ |
| donetx timing | Asserts after all TX bits sent | ✅ |
| donerx timing | Asserts after all RX bits received | ✅ |
| Reset behavior | Both TX and RX return to idle state | ✅ |

---

## Improvements Over Base Design

1. **Added `display()`** to transaction
2. **Removed unused FSM states** — `start` and `done` states in TX never used
3. **Removed declaration initialization** — moved to reset blocks
4. **Added `modport`** to interface
5. **Added SVA assertions** — donetx/donerx timing, done mutex
6. **Added timeout mechanism** — longer timeout due to baud rate division
7. **Added scoreboard summary** — pass/fail/total report
8. **Removed commented-out code** — clean file-per-class structure
9. **Named port connections** in tb_top instead of positional

---

## File Structure

```
04_uart_verification/
├── README.md
├── rtl/
│   └── uart.sv                ← uarttx + uartrx + uart_top + interface
├── tb/
│   ├── transaction.sv         ← TX/RX operation type with randc
│   ├── generator.sv
│   ├── driver.sv              ← handles both TX and RX driving
│   ├── monitor.sv             ← captures both TX and RX data
│   ├── scoreboard.sv          ← comparison with summary
│   ├── environment.sv         ← wiring + timeout
│   └── tb_top.sv
├── assertions/
│   └── uart_assertions.sv     ← 3 active SVA properties
├── docs/
│   ├── verification_plan.md
│   ├── coverage_report.md
│   └── bug_log.md
└── sim/
    └── run.sh
```

---

## Results

- **Transactions:** 5 (alternating TX/RX via randc)
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
xvlog -sv ../rtl/uart.sv ../tb/tb_top.sv ../assertions/uart_assertions.sv
xelab -debug typical tb -s sim_snapshot
xsim sim_snapshot -runall
```

---

## Key Learnings

- UART verification requires handling two independent data paths (TX and RX) with separate baud clocks
- `randc` on operation type ensures both TX and RX are tested equally — cycles through all values before repeating
- Cross-module references (`dut.utx.uclk`, `dut.rtx.uclk`) are necessary when internal clocks aren't exposed at top level
- Baud rate division makes UART simulation significantly slower than direct-clocked designs like DFF or FIFO
- Driver uses `$urandom` for RX data bits — a real improvement would use transaction data for full traceability
