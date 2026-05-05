# Bug Log — UART

## Bugs Found

| # | Description | Severity | Found By | Status |
|---|-------------|----------|----------|--------|
| 1 | Transaction missing display() method | Low | Code review | Fixed |
| 2 | Declaration initialization in RTL — not synthesizable | Low | Code review | Fixed |
| 3 | Interface missing modport | Low | Code review | Fixed |
| 4 | No timeout mechanism | Medium | Code review | Fixed |
| 5 | No scoreboard summary report | Low | Code review | Fixed |
| 6 | Commented-out intermediate testbenches left in code | Low | Code review | Fixed |
| 7 | Unused FSM state (start) in TX — jumps from idle to transfer | Low | Code review | Fixed |

## Bug Details

### Bug #1: Missing display()

**Location:** `transaction` class
**Problem:** No debug display method. Makes tracing transactions through the log difficult.
**Fix:** Added `display()` method showing oper, dintx, doutrx, done flags, and timestamp.

---

### Bug #6: Commented-out code

**Location:** Throughout testbench file
**Problem:** Multiple commented-out `module tb` blocks from intermediate development stages left in the production code. Clutters the file and confuses readers about which testbench is active.
**Fix:** Removed all commented-out testbench blocks. Clean file-per-class structure eliminates this entirely.

---

### Bug #7: Unused TX FSM state

**Location:** `uarttx` module
**Original:** `enum bit[1:0] {idle = 2'b00, start = 2'b01, transfer = 2'b10, done = 2'b11}`
**Problem:** States `start` and `done` are defined but never used. The FSM goes directly from `idle` to `transfer`. Dead encoding.
**Fix:** Removed unused states, kept `IDLE` and `TRANSFER` only.
