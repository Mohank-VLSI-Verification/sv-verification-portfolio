# Bug Log — I2C

## Bugs Found

| # | Description | Severity | Found By | Status |
|---|-------------|----------|----------|--------|
| 1 | Generator puts tr without copy() — shared-reference bug | High | Code review | Fixed |
| 2 | Transaction missing display() method | Low | Code review | Fixed |
| 3 | Monitor shared-object bug — tr = new() outside loop | Medium | Code review | Fixed |
| 4 | No environment class — test phases in tb module directly | Medium | Code review | Fixed |
| 5 | No timeout mechanism | Medium | Code review | Fixed |
| 6 | No scoreboard summary report | Low | Code review | Fixed |
| 7 | Interface missing modport | Low | Code review | Fixed |
| 8 | Declaration initialization in RTL | Low | Code review | Fixed |
| 9 | Commented-out intermediate testbench left in code | Low | Code review | Fixed |

## Bug Details

### Bug #1: Missing copy() in generator

**Location:** `generator` class
**Original:** `mbxgd.put(tr);`
**Problem:** Generator puts the same transaction handle into the mailbox every iteration. When it randomizes again, the driver may see the new randomized values instead of the intended ones. This is the most critical bug — it can cause intermittent, hard-to-debug mismatches.
**Fix:** Changed to `mbxgd.put(tr.copy);`

---

### Bug #4: No environment class

**Location:** `tb` module
**Original:** Test phases (`pre_test`, `test`, `post_test`) were defined as tasks directly inside the `tb` module, with component instantiation in an `initial` block.
**Problem:** Breaks the class-based layered architecture pattern. Components should be created and wired inside an environment class, not scattered in the top module.
**Fix:** Created proper `environment` class with constructor handling all wiring, and `run()` orchestrating test phases.

---

### Bug #3: Monitor shared-object

**Location:** `monitor` class
**Original:** `tr = new()` called once before the forever loop.
**Problem:** Same transaction object put into mailbox each iteration. Scoreboard may read overwritten values if timing misaligns.
**Fix:** Moved `tr = new()` inside the forever loop.
