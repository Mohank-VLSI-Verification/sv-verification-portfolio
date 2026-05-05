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

| ID | Property | Type |
|----|----------|------|
| A1 | No data accepted on write when full | Concurrent |
| A2 | No data output on read when empty | Concurrent |
| A3 | Full and empty are mutually exclusive | Concurrent |
| A4 | After reset: empty=1, full=0 | Concurrent |
| A5 | Empty clears after successful write | Concurrent |
| A6 | Full clears after successful read | Concurrent |

## 6. Testbench Architecture

Class-based layered testbench with golden model:
- **Transaction** — rand oper (r/w), rand data_in, observed data_out, flags
- **Generator** — constrained random (50/50 read/write distribution)
- **Driver** — drives write data from transaction (not self-generated)
- **Monitor** — captures all FIFO signals passively
- **Scoreboard** — uses SystemVerilog queue as golden FIFO model
- **Environment** — wires components, runs test phases with timeout

## 7. Pass Criteria

- 0 assertion failures
- 0 scoreboard data mismatches
- 100% functional coverage on all coverpoints
- Simulation completes without timeout
