# 02 — FIFO Verification

Functional verification of a 16-deep, 8-bit wide synchronous FIFO using a class-based SystemVerilog testbench with golden model comparison.

---

## Architecture

```
┌───────────────────────────────────────────────────────┐
│                    environment                        │
│                                                       │
│  ┌───────────┐   gdmbx    ┌──────────┐                │
│  │ generator │──────────→ │  driver  │                │
│  └───────────┘            └──────────┘                │
│       │                        │                      │
│       │                        │ vif (wr, rd, data_in)│
│       │                        ▼                      │
│       │                  ┌───────────┐                │
│       │                  │ FIFO (DUT)│                │
│       │                  │ 16x8-bit  │                │
│       │                  └───────────┘                │
│       │                        │                      │
│       │                        │ vif (data_out,       │
│       │                        │      full, empty)    │
│       │                        ▼                      │
│       │                  ┌───────────┐                │
│       │                  │  monitor  │                │
│       │                  └───────────┘                │
│       │                        │                      │
│       │          msmbx         │                      │
│       │                        ▼                      │
│       │               ┌───────────────┐               │
│       │               │  scoreboard   │               │
│       │               │ (queue-based  │               │
│       │               │  golden model)│               │
│       │               └───────────────┘               │
│       │                       │                       │
│       │                  nextgs (event)               │
│       └←←←←←←←←←←←←←←←←←←←←┘                          │
└───────────────────────────────────────────────────────┘
```

---

## What I Verified

| Scenario | Description | Status |
|----------|-------------|--------|
| Write operation | Data stored correctly when not full | ✅ |
| Read operation | Data returned in FIFO order when not empty | ✅ |
| Write when full | Write rejected, no overflow | ✅ |
| Read when empty | Read rejected, no underflow | ✅ |
| Full flag | Asserts at count=16, deasserts on read | ✅ |
| Empty flag | Asserts at count=0, deasserts on write | ✅ |
| Full/empty mutex | Never both asserted simultaneously | ✅ |
| Simultaneous r/w | Both operations execute in same cycle | ✅ |
| Reset behavior | Pointers and count clear, empty=1, full=0 | ✅ |
| Random stimulus | 30+ constrained random transactions (50/50 r/w) | ✅ |

---

## Improvements Over Base Design

1. **Fixed transaction shared-reference bug** — added `copy()` and `display()` methods
2. **Fixed driver data flow** — driver now uses transaction's `data_in` instead of generating its own random data with `$urandom_range`
3. **Fixed monitor shared-object bug** — fresh transaction per iteration
4. **Fixed RTL simultaneous r/w** — original `else-if` skipped read during write; now uses `case` to handle all combinations
5. **Added `modport`** — enforces signal direction on interface
6. **Added SVA assertions** — 6 concurrent properties checking flag behavior, reset, and overflow/underflow protection
7. **Added timeout mechanism** — prevents infinite simulation hangs
8. **Added scoreboard summary** — pass/fail/total report at end of simulation
9. **Removed non-synthesizable initialization** — pointer init moved to reset block

---

## File Structure

```
02_fifo_verification/
├── README.md
├── rtl/
│   └── fifo.sv                ← DUT + interface with modport
├── tb/
│   ├── transaction.sv         ← data packet with copy() and display()
│   ├── generator.sv           ← constrained random (50/50 r/w)
│   ├── driver.sv              ← drives via transaction data (not self-generated)
│   ├── monitor.sv             ← passive capture, fresh object per cycle
│   ├── scoreboard.sv          ← queue-based golden model with summary
│   ├── environment.sv         ← wiring + timeout
│   └── tb_top.sv              ← top-level: clock, DUT, environment
├── assertions/
│   └── fifo_assertions.sv     ← 6 SVA properties
├── docs/
│   ├── verification_plan.md
│   ├── coverage_report.md
│   └── bug_log.md
└── sim/
    └── run.sh
```

---

## Results

- **Transactions:** 30 randomized (50% write, 50% read)
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

## Key Learnings

- Scoreboard golden model using SystemVerilog queue mirrors FIFO behavior perfectly (push_front for write, pop_back for read)
- Driver must use transaction data to maintain data integrity across the testbench — generating its own data breaks the verification chain
- Simultaneous read+write is a critical corner case that else-if RTL silently ignores
- FIFO has significantly more state than a DFF — verification plan must explicitly list boundary conditions
