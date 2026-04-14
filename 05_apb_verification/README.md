# 05 — I2C Verification

Functional verification of an I2C master+slave system with 128-byte slave memory using a class-based SystemVerilog testbench. Tests both write and read operations with address-based memory access and ACK/NACK handshaking.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     environment                           │
│                                                           │
│  ┌───────────┐  mbxgd   ┌───────────┐                   │
│  │ generator  │────────→│   driver   │                   │
│  └───────────┘          └───────────┘                   │
│   (50/50 r/w)            │  WR: addr + din + newd        │
│   (addr: 2-4)            │  RD: addr + newd              │
│                          ▼                                │
│                   ┌──────────────┐                        │
│                   │  i2c_top     │                        │
│                   │ ┌──────────┐ │                        │
│                   │ │i2c_master│ │                        │
│                   │ │  SDA ↔   │ │  (bidirectional)       │
│                   │ │i2c_slave │ │                        │
│                   │ │ mem[128] │ │  (slave has memory)    │
│                   │ └──────────┘ │                        │
│                   └──────────────┘                        │
│                          │                                │
│                   done, dout, ack_err                     │
│                          ▼                                │
│                   ┌───────────┐                           │
│                   │  monitor  │                           │
│                   └───────────┘                           │
│                          │ mbxms                          │
│                          ▼                                │
│                   ┌──────────────┐                        │
│                   │  scoreboard  │                        │
│                   │ (128-byte    │                        │
│                   │  golden mem) │                        │
│                   └──────────────┘                        │
└──────────────────────────────────────────────────────────┘
```

**Scoreboard strategy:** Mirrors the slave's 128-byte memory (initialized to `mem[i] = i`). On write, stores data in golden model. On read, compares DUT `dout` against golden model.

---

## What I Verified

| Scenario | Description | Status |
|----------|-------------|--------|
| Write operation | Data written to slave memory at correct address | ✅ |
| Read operation | Data read from slave matches expected value | ✅ |
| Write-then-read | Write data, read same address, verify match | ✅ |
| Initial memory | Read before write returns mem[addr] = addr | ✅ |
| ACK handshaking | Master receives ACK from slave after address/data | ✅ |
| Busy flag | Asserts during transfer, deasserts on done | ✅ |
| Done flag | Asserts after transfer completes | ✅ |
| Reset behavior | All signals return to idle state | ✅ |
| Random stimulus | 20 transactions (50/50 r/w, addr 2-4, din 1-9) | ✅ |

---

## Improvements Over Base Design

1. **Fixed generator shared-reference bug** — added `copy()` to mailbox put (critical)
2. **Added `display()`** to transaction
3. **Fixed monitor shared-object bug** — fresh transaction per iteration
4. **Created proper environment class** — original had test phases in tb module
5. **Added `modport`** to interface
6. **Added SVA assertions** — 4 properties (busy/done timing, mutex)
7. **Added timeout mechanism** — longer timeout for slow I2C clock
8. **Added scoreboard summary** — pass/fail/total report
9. **Removed commented-out code** — clean file-per-class structure
10. **Named port connections** in tb_top

---

## File Structure

```
05_i2c_verification/
├── README.md
├── rtl/
│   └── i2c.sv                 ← master + slave + top + interface
├── tb/
│   ├── transaction.sv         ← constrained random (addr 2-4, din 1-9)
│   ├── generator.sv           ← fixed: uses copy()
│   ├── driver.sv              ← handles write and read operations
│   ├── monitor.sv             ← captures on posedge done
│   ├── scoreboard.sv          ← 128-byte golden memory model
│   ├── environment.sv         ← proper class (not in tb module)
│   └── tb_top.sv
├── assertions/
│   └── i2c_assertions.sv      ← 4 SVA properties
├── docs/
│   ├── verification_plan.md
│   ├── coverage_report.md
│   └── bug_log.md
└── sim/
    └── run.sh
```

---

## Results

- **Transactions:** 20 (constrained random, 50/50 read/write)
- **Pass rate:** TODO — update after simulation
- **Assertion failures:** TODO

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
xvlog -sv ../rtl/i2c.sv ../tb/tb_top.sv ../assertions/i2c_assertions.sv
xelab -debug typical tb -s sim_snapshot
xsim sim_snapshot -runall
```

---

## Key Learnings

- I2C uses bidirectional SDA (open-drain) — master and slave share the same wire, controlled by `sda_en` to switch between driving and reading
- Scoreboard uses a golden memory model that mirrors the slave's 128-byte storage, enabling write-then-read verification
- The original testbench had no environment class — test orchestration was in the tb module, breaking the layered architecture pattern
- I2C's slow clock (100kHz vs 40MHz system) means simulation takes significantly longer than SPI or UART
- The generator's missing `copy()` was the most critical bug — caused intermittent data corruption that would be extremely hard to debug in a real project
