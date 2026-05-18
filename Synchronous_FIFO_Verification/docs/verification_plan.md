# Verification Plan — FIFO

## 1. DUT Specification

| Parameter | Value |
|-----------|-------|
| Module | `FIFO` |
| Depth | 16 entries |
| Width | 8 bits |
| Reset | Synchronous, active-high |
| Flags | `full` (count=16), `empty` (count=0) |
| Pointers | 4-bit write pointer, 4-bit read pointer |
| Counter | 5-bit (0-16) |

## 2. Verification Goals

Prove the FIFO correctly:
- Stores data on write when not full
- Returns data in FIFO order (first in, first out) on read when not empty
- Rejects writes when full (no overflow)
- Rejects reads when empty (no underflow)
- Asserts full/empty flags at correct thresholds
- Handles simultaneous read+write
- Resets to known empty state
- Wraps pointers correctly at boundary (15 → 0)

## 3. Test Scenarios

| ID | Scenario | Method | Priority |
|----|----------|--------|----------|
| T1 | Single write + single read | Directed | High |
| T2 | Fill FIFO to full (16 writes) | Directed | High |
| T3 | Write when full (overflow attempt) | Directed | High |
| T4 | Read until empty | Directed | High |
| T5 | Read when empty (underflow attempt) | Directed | High |
| T6 | Simultaneous read + write | Random | High |
| T7 | Pointer wraparound (write past entry 15) | Random | High |
| T8 | Reset during active operation | Directed | Medium |
| T9 | Reset when full | Directed | Medium |
| T10 | Alternating write/read patterns | Random | Medium |
| T11 | Back-to-back writes | Random | Medium |
| T12 | Back-to-back reads | Random | Medium |
| T13 | Random mixed operations (50/50 r/w) | Random | High |

## 4. Coverage Targets

| Coverpoint | Target |
|------------|--------|
| `wr` values (0, 1) | 100% |
| `rd` values (0, 1) | 100% |
| `full` flag (0, 1) | 100% |
| `empty` flag (0, 1) | 100% |
| Cross: wr × full | 100% (write when full, write when not full) |
| Cross: rd × empty | 100% (read when empty, read when not empty) |
| Cross: wr × rd | 100% (simultaneous r/w) |
| FIFO count (0, 1-15, 16) | 100% (empty, partial, full) |

## 5. Assertions

| ID | Property | Type | What it catches |
|----|----------|------|-----------------|
| A1 | After reset: empty=1, full=0, cnt=0 | Concurrent | Incomplete reset (e.g., pointer reset but cnt not reset) |
| A2 | No write accepted when full — pointer and count unchanged | Concurrent | Overflow / memory corruption |
| A3 | No read accepted when empty — pointer, count, dout unchanged | Concurrent | Underflow / spurious data output |
| A4 | Simultaneous R+W: cnt stable, both pointers advance | Concurrent | Simultaneous-op handling bugs |
| A5 | Empty clears after successful write; full clears after successful read | Concurrent | Flag-transition bugs |
| A6 | Full and empty are mutually exclusive (and consistent with cnt) | Concurrent | Flag/count desync, illegal state |

### Assertion Implementations

```systemverilog
// A1 — Reset state
property p_reset_state;
  @(posedge clk) $rose(rst) |=> (empty && !full && cnt == 0);
endproperty
assert property (p_reset_state)
  else $error("[A1] Reset did not clear FIFO state @ %0t", $time);

// A2 — Overflow protection (strengthened with internal state)
property p_no_overflow;
  @(posedge clk) disable iff (rst)
    (full && wr && !rd) |=> $stable(wptr) && $stable(cnt);
endproperty
assert property (p_no_overflow)
  else $error("[A2] Write accepted when full @ %0t", $time);

// A3 — Underflow protection
property p_no_underflow;
  @(posedge clk) disable iff (rst)
    (empty && rd && !wr) |=> $stable(rptr) && $stable(cnt) && $stable(dout);
endproperty
assert property (p_no_underflow)
  else $error("[A3] Read accepted when empty @ %0t", $time);

// A4 — Simultaneous R+W
property p_simultaneous_rw;
  @(posedge clk) disable iff (rst)
    (wr && !full && rd && !empty) |=> 
      $stable(cnt) && (wptr == $past(wptr) + 1) && (rptr == $past(rptr) + 1);
endproperty
assert property (p_simultaneous_rw)
  else $error("[A4] Simultaneous R/W mishandled @ %0t", $time);

// A5 — Flag transitions
property p_empty_clears;
  @(posedge clk) disable iff (rst)
    (empty && wr && !full) |=> !empty;
endproperty
assert property (p_empty_clears)
  else $error("[A5a] Empty did not clear after write @ %0t", $time);

property p_full_clears;
  @(posedge clk) disable iff (rst)
    (full && rd && !wr) |=> !full;
endproperty
assert property (p_full_clears)
  else $error("[A5b] Full did not clear after read @ %0t", $time);

// A6 — Flag consistency
property p_full_empty_mutex;
  @(posedge clk) disable iff (rst) !(full && empty);
endproperty
assert property (p_full_empty_mutex)
  else $error("[A6a] FIFO is both full and empty @ %0t", $time);

property p_flag_cnt_consistency;
  @(posedge clk) disable iff (rst)
    (empty == (cnt == 0)) && (full == (cnt == 16));
endproperty
assert property (p_flag_cnt_consistency)
  else $error("[A6b] Flag/count mismatch @ %0t", $time);
```

**Note on binding:** A1, A2, A3, A4, A6 reference internal signals (`cnt`, `wptr`, `rptr`). Use `bind` to attach the assertion module inside the DUT scope without modifying the RTL:

```systemverilog
bind FIFO fifo_assertions u_asserts (.*);
```

## 6. Testbench Architecture

Class-based layered testbench with golden model:
- **Transaction** — rand oper (r/w), rand data_in, observed data_out, flags
- **Generator** — constrained random (50/50 read/write distribution)
- **Driver** — drives write data from transaction (not self-generated)
- **Monitor** — captures all FIFO signals passively
- **Scoreboard** — uses SystemVerilog queue as golden FIFO model (proves FIFO ordering — the one property SVA cannot fully express)
- **Environment** — wires components, runs test phases with timeout

## 7. Pass Criteria

- 0 assertion failures (A1–A6)
- 0 scoreboard data mismatches (proves data integrity and ordering)
- 100% functional coverage on all coverpoints
- All 13 test scenarios executed
- Simulation completes without timeout
