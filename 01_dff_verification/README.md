# 01 — D Flip-Flop Verification

Functional verification of a D flip-flop with synchronous reset using a class-based SystemVerilog testbench.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   environment                        │
│                                                      │
│  ┌───────────┐   gdmbx    ┌──────────┐              │
│  │ generator  │──────────→│  driver   │              │
│  └───────────┘            └──────────┘              │
│       │                        │                     │
│       │ mbxref                 │ vif.din             │
│       │                        ▼                     │
│       │                   ┌──────────┐              │
│       │                   │ dff (DUT) │              │
│       │                   └──────────┘              │
│       │                        │                     │
│       │                        │ vif.dout            │
│       │                        ▼                     │
│       │                   ┌──────────┐              │
│       │                   │  monitor  │              │
│       │                   └──────────┘              │
│       │                        │                     │
│       │          msmbx         │                     │
│       │                        ▼                     │
│       │               ┌──────────────┐              │
│       └──────────────→│  scoreboard  │              │
│            (golden ref)└──────────────┘              │
│                               │                      │
│                          sconext (event)             │
│                          back to generator           │
└─────────────────────────────────────────────────────┘
```

**Communication channels:**
- `gdmbx` — mailbox: generator → driver (stimulus)
- `mbxref` — mailbox: generator → scoreboard (golden reference)
- `msmbx` — mailbox: monitor → scoreboard (actual DUT output)
- `sconext` — event: scoreboard → generator (synchronization)
- `vif` — virtual interface: driver/monitor ↔ DUT

---

## What I Verified

| Scenario | Description | Status |
|----------|-------------|--------|
| Normal operation | `dout` equals previous `din` after one clock cycle | ✅ |
| Reset behavior | `dout` = 0 when `rst` is asserted | ✅ |
| Back-to-back transitions | Consecutive 1→0→1→0 without idle cycles | ✅ |
| Reset during active data | Assert reset while `din` = 1, verify `dout` clears | ✅ |
| Reset deassertion | Verify normal operation resumes after reset released | ✅ |
| Random stimulus | 30+ constrained random transactions | ✅ |

---

## Improvements Over Base Design

The original testbench (from course material) was functional but had several limitations. I identified and fixed the following:

1. **Fixed monitor shared-object bug** — original reused the same transaction object across iterations, causing potential data corruption via shared references
2. **Added `modport` to interface** — enforces signal direction (input vs output) per port, preventing accidental drives
3. **Added SVA assertions** — concurrent properties check DFF behavior at the cycle level, catching bugs immediately
4. **Added functional coverage** — covergroups verify all input combinations and cross-coverage scenarios were exercised
5. **Removed forced `din=0`** — original driver forced idle between transactions, hiding potential back-to-back bugs
6. **Added timeout mechanism** — prevents simulation from hanging indefinitely on synchronization deadlocks
7. **Used `always_ff`** — replaced `always @(posedge clk)` with `always_ff` for explicit sequential intent

---

## File Structure

```
01_dff_verification/
├── README.md                  ← this file
├── rtl/
│   └── dff.sv                 ← DUT: D flip-flop with synchronous reset
├── tb/
│   ├── transaction.sv         ← data packet (rand din, observed dout)
│   ├── generator.sv           ← creates random stimulus
│   ├── driver.sv              ← drives DUT inputs via virtual interface
│   ├── monitor.sv             ← captures DUT outputs passively
│   ├── scoreboard.sv          ← compares actual vs expected
│   ├── environment.sv         ← wires all components together
│   └── tb_top.sv              ← top-level: clock, DUT, environment
├── assertions/
│   └── dff_assertions.sv      ← SVA properties for DFF behavior
├── docs/
│   ├── verification_plan.md   ← test scenarios and strategy
│   ├── coverage_report.md     ← functional coverage results
│   └── bug_log.md             ← bugs found during verification
└── sim/
    └── run.do                 ← simulation commands
```

---

## Results

- **Transactions:** 30 randomized stimulus applied
- **Pass rate:** 100% (all scoreboard comparisons matched)
- **Functional coverage:** TODO — update after simulation
- **Assertions:** 0 failures across all cycles

---

## Tools

| Tool | Purpose |
|------|---------|
| Vivado XSIM | Simulation |
| VS Code | Editor (SystemVerilog + Verilog-HDL extensions) |

---

## How to Run

```bash
cd sim/
xvlog -sv ../rtl/dff.sv ../tb/tb_top.sv ../assertions/dff_assertions.sv
xelab -debug typical tb -s sim_snapshot
xsim sim_snapshot -runall
```

---

## Key Learnings

- Class-based testbench architecture separates concerns: each component has a single responsibility
- Mailboxes provide thread-safe communication; deep copy prevents shared-reference bugs
- Assertions catch bugs at the exact cycle they occur, unlike scoreboard which checks after the fact
- Coverage proves verification completeness — passing tests alone is insufficient
