# Bug Log — AXI4-Lite

## Bugs Found

| # | Description | Severity | Found By | Status |
|---|-------------|----------|----------|--------|
| 1 | Generator puts tr without copy() — shared-reference bug | High | Code review | Fixed |
| 2 | Transaction missing copy() and display() methods | Medium | Code review | Fixed |
| 3 | Monitor shared-object bug — tr = new() outside loop | Medium | Code review | Fixed |
| 4 | No environment class — test phases in tb module | Medium | Code review | Fixed |
| 5 | Blocking assignment in RTL (send_raddr_ack state) | High | Code review | Fixed |
| 6 | Constraints too narrow (awaddr==1, araddr==1) — barely tests memory range | High | Code review | Fixed |
| 7 | Interface missing modport | Low | Code review | Fixed |
| 8 | No timeout mechanism | Medium | Code review | Fixed |
| 9 | No scoreboard summary report | Low | Code review | Fixed |
| 10 | Declaration initialization in RTL | Low | Code review | Fixed |

## Bug Details

### Bug #5: Blocking assignment in RTL

**Location:** `axilite_s.sv` — SEND_RADDR_ACK state
**Original:** `s_axi_arready = 1'b0;` (blocking `=`)
**Problem:** All other assignments in this always block use non-blocking (`<=`). Mixing blocking and non-blocking in a sequential always block creates race conditions in simulation and is a synthesis warning. The behavior may differ between simulators.
**Fix:** Changed to `s_axi_arready <= 1'b0;`

---

### Bug #6: Over-constrained addresses

**Location:** `transaction` class
**Original:** `constraint valid_addr_range {awaddr == 1; araddr == 1;}`
**Problem:** Both addresses are forced to exactly 1. This means every write goes to address 1 and every read comes from address 1. You're testing one memory location out of 128 — 99.2% of the address space is never verified. A recruiter would immediately flag this as inadequate coverage.
**Fix:** Changed to `awaddr inside {[0:127]}; araddr inside {[0:127]};` — full valid range.

---

### Bug #1: Missing copy() in generator

**Location:** `generator` class
**Original:** `mbxgd.put(tr);`
**Problem:** Same shared-reference bug seen across all projects. Generator randomizes tr, puts handle into mailbox, then randomizes again — driver may get the wrong values.
**Fix:** Changed to `mbxgd.put(tr.copy);`
