# Bug Log — D Flip-Flop

## Bugs Found

| # | Description | Severity | Found By | Status |
|---|-------------|----------|----------|--------|
| 1 | Monitor reuses same transaction object — scoreboard may read overwritten data | Medium | Code review | Fixed |
| 2 | Driver forces din=0 between transactions — masks back-to-back bugs | Low | Code review | Fixed |
| 3 | No timeout mechanism — simulation hangs on sync deadlock | Medium | Code review | Fixed |
| 4 | Interface missing modport — no direction enforcement | Low | Code review | Fixed |

## Bug Details

### Bug #1: Monitor shared-object reference

**Location:** `monitor.sv`
**Original code:**
```systemverilog
tr = new();         // called ONCE outside loop
forever begin
  repeat(2) @(posedge vif.clk);
  tr.dout = vif.dout;
  mbx.put(tr);     // same object reference every iteration
end
```

**Problem:** Mailbox passes by reference. If the monitor overwrites `tr.dout` before the scoreboard reads it, the scoreboard sees corrupted data.

**Fix:** Move `tr = new()` inside the loop to create a fresh object each iteration.

---

### Bug #2: Forced idle between transactions

**Location:** `driver.sv`
**Original code:**
```systemverilog
vif.din <= tr.din;
@(posedge vif.clk);
vif.din <= 1'b0;       // forced idle
@(posedge vif.clk);
```

**Problem:** Prevents testing consecutive non-zero inputs (din=1,1,1). The DFF might have a bug that only appears on back-to-back inputs, but this driver would never expose it.

**Fix:** Remove the forced idle — let randomization decide what comes next.

---

### Bug #3: No timeout

**Location:** `environment.sv`
**Problem:** If the scoreboard never triggers `sconext` (e.g., mailbox deadlock), the generator blocks forever. Simulation runs indefinitely with no error.

**Fix:** Added fork with timeout in `post_test()`.

---

### Bug #4: Missing modport

**Location:** `dff_if` interface
**Problem:** Without `modport`, any component can drive any signal. The monitor could accidentally drive `din` and nobody would know until silicon.

**Fix:** Added `modport DUT` and `modport TB` with explicit directions.
