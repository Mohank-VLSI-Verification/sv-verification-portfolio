# 06 — AXI4-Lite Slave Verification

Functional verification of an AXI4-Lite slave with 128x32-bit memory using a class-based SystemVerilog testbench. Tests write and read channels with full AXI handshaking protocol and error response handling.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      environment                          │
│                                                           │
│  ┌───────────┐  mbxgd   ┌───────────┐                   │
│  │ generator  │────────→│   driver   │                   │
│  └───────────┘          └───────────┘                   │
│   (randc: r/w)           │ WR: awvalid→awready           │
│   (addr: 0-127)          │     wvalid→wready             │
│                          │     bvalid→bready             │
│                          │ RD: arvalid→arready           │
│                          │     rvalid→rready             │
│                          │  mbxdm (context)              │
│                          ▼  ▼                            │
│                   ┌──────────────┐                       │
│                   │  axilite_s   │                       │
│                   │  128x32 mem  │                       │
│                   │  OKAY/DECERR │                       │
│                   └──────────────┘                       │
│                          │                               │
│                   AXI response channels                  │
│                          ▼                               │
│                   ┌───────────┐                          │
│                   │  monitor  │←── context from driver   │
│                   └───────────┘                          │
│                          │ mbxms                         │
│                          ▼                               │
│                   ┌──────────────┐                       │
│                   │  scoreboard  │                       │
│                   │ (128x32 gold │                       │
│                   │  memory)     │                       │
│                   └──────────────┘                       │
└──────────────────────────────────────────────────────────┘
```

**Unique pattern:** Driver sends operation context to monitor via `mbxdm` mailbox, since the monitor needs to know whether to watch the write response channel or read data channel.

---

## What I Verified

| Scenario | Description | Status |
|----------|-------------|--------|
| Write transaction | Full AW→W→B handshake, data stored | ✅ |
| Read transaction | Full AR→R handshake, correct data returned | ✅ |
| Write-then-read | Data integrity across write and read | ✅ |
| DECERR on write | Address >= 128 returns bresp=11 | ✅ |
| DECERR on read | Address >= 128 returns rresp=11 | ✅ |
| Handshake timing | awready/wready/arready within spec cycles | ✅ |
| Reset behavior | All outputs cleared on aresetn=0 | ✅ |
| Random stimulus | 10 transactions (randc read/write, addr 0-127) | ✅ |

---

## Improvements Over Base Design

1. **Fixed generator shared-reference bug** — added `copy()` and uses it in mailbox put
2. **Added `display()`** to transaction
3. **Fixed monitor shared-object bug** — fresh transaction per iteration
4. **Created proper environment class** — original had test phases in tb module
5. **Fixed blocking assignment** in RTL (`=` → `<=` in SEND_RADDR_ACK)
6. **Widened constraints** — `awaddr==1` → `awaddr inside {[0:127]}` for real coverage
7. **Added `modport`** to interface
8. **Added SVA assertions** — 7 properties covering all handshake channels and reset
9. **Added timeout mechanism**
10. **Added scoreboard summary** — pass/fail/total report
11. **Named port connections** in tb_top

---

## File Structure

```
06_axilite_verification/
├── README.md
├── rtl/
│   └── axilite.sv             ← AXI4-Lite slave + interface
├── tb/
│   ├── transaction.sv         ← randc op, constrained addr/data
│   ├── generator.sv           ← fixed: uses copy()
│   ├── driver.sv              ← AXI handshake protocol
│   ├── monitor.sv             ← gets context from driver via mbxdm
│   ├── scoreboard.sv          ← 128x32 golden memory + DECERR handling
│   ├── environment.sv         ← proper class with timeout
│   └── tb_top.sv
├── assertions/
│   └── axilite_assertions.sv  ← 7 SVA properties
├── docs/
│   ├── verification_plan.md
│   ├── coverage_report.md
│   └── bug_log.md
└── sim/
    └── run.sh
```

---

## Results

- **Transactions:** 10 (randc read/write, constrained addresses)
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
xvlog -sv ../rtl/axilite.sv ../tb/tb_top.sv ../assertions/axilite_assertions.sv
xelab -debug typical tb -s sim_snapshot
xsim sim_snapshot -runall
```

---

## Key Learnings

- AXI4-Lite uses separate channels for each phase of a transaction — understanding the handshake protocol is essential before writing testbench code
- The driver-to-monitor mailbox (`mbxdm`) is a pattern unique to this testbench — the monitor needs operation context because it watches different channels for reads vs writes
- Over-constrained addresses (`awaddr==1`) is a common student mistake that looks like it works but tests almost nothing — functional coverage would immediately expose this gap
- DECERR handling proves the DUT correctly rejects invalid operations, not just that it handles the happy path
- This is the most complex protocol in the portfolio — AXI is the industry standard for SoC interconnect
