# Bug Log — FIFO

## Bugs Found

| # | Description | Severity | Found By | Status |
|---|-------------|----------|----------|--------|
| 1 | Transaction missing copy() — shared-reference bug in mailbox | Medium | Code review | Fixed |
| 2 | Driver generates own random data, ignores transaction data_in | High | Code review | Fixed |
| 3 | Monitor reuses same transaction object across iterations | Medium | Code review | Fixed |
| 4 | Simultaneous read+write not handled in RTL (else-if blocks only write) | High | Code review | Fixed |
| 5 | No timeout mechanism — simulation hangs on sync deadlock | Medium | Code review | Fixed |
| 6 | Interface missing modport — no direction enforcement | Low | Code review | Fixed |
| 7 | Pointer initialization in declaration — not synthesizable on all tools | Low | Code review | Fixed |

## Bug Details

### Bug #1: Missing copy() on transaction

**Location:** `generator.sv` (original), `transaction.sv`
**Problem:** Generator puts the same object handle into mailbox. When it randomizes again, the driver sees the new value, not the one intended.
**Fix:** Added `copy()` to transaction class, generator calls `tr.copy` before `mbx.put`.

---

### Bug #2: Driver ignores transaction data

**Location:** `driver.sv`
**Original:** `fif.data_in <= $urandom_range(1, 10);`
**Problem:** Generator randomizes `data_in` but driver throws it away and generates its own. The scoreboard has no way to know what data was actually written — breaks the generator → driver → DUT → monitor → scoreboard data integrity chain.
**Fix:** Driver now accepts `data_in` from transaction: `write(datac.data_in)`.

---

### Bug #3: Monitor shared-object reference

**Location:** `monitor.sv`
**Problem:** Same as DFF project — `tr = new()` called once outside loop. Scoreboard may read overwritten values.
**Fix:** Moved `tr = new()` inside the forever loop.

---

### Bug #4: Simultaneous read+write ignored

**Location:** RTL `fifo.sv`
**Original:**
```systemverilog
if (wr && !full)        // write
else if (rd && !empty)  // read — SKIPPED if write happens
```
**Problem:** When both `wr` and `rd` are asserted, only write executes. Real FIFOs should handle both simultaneously — one item in, one item out, count unchanged.
**Fix:** Replaced with `case ({wr && !full, rd && !empty})` handling all four combinations including `2'b11`.

---

### Bug #5: No timeout

**Location:** `environment.sv`
**Problem:** Same as DFF — no safety net for synchronization deadlocks.
**Fix:** Added fork with timeout in `post_test()`.

---

### Bug #6: Missing modport

**Location:** `fifo_if` interface
**Fix:** Added `modport DUT` and `modport TB`.

---

### Bug #7: Non-synthesizable initialization

**Location:** RTL `fifo.sv`
**Original:** `reg [3:0] wptr = 0, rptr = 0;`
**Problem:** Initial value in declaration works in simulation but isn't reliably synthesizable. Reset block should handle initialization.
**Fix:** Removed declaration initialization, reset block sets all to 0.
