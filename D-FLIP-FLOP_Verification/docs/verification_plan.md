# Verification Plan — D Flip-Flop

## 1. DUT Specification

| Parameter | Value |
|-----------|-------|
| Module | `dff` |
| Interface | `dff_if` (clk, rst, din, dout) |
| Reset type | Synchronous, active-high |
| Trigger | Positive edge of clk |
| Behavior | On posedge clk: if rst=1, dout=0; else dout=din |

## 2. Verification Goals

Prove that the DFF:
- Correctly captures `din` to `dout` on every rising clock edge
- Correctly resets `dout` to 0 when `rst` is asserted
- Resumes normal operation after reset is deasserted
- Handles all input transitions (0→0, 0→1, 1→0, 1→1)

## 3. Test Scenarios

| ID | Scenario | Method | Priority |
|----|----------|--------|----------|
| T1 | Normal capture: din=0 → dout=0 | Random + directed | High |
| T2 | Normal capture: din=1 → dout=1 | Random + directed | High |
| T3 | Reset asserted: dout forced to 0 | Directed | High |
| T4 | Reset deasserted: normal operation resumes | Directed | High |
| T5 | Back-to-back 1s: din=1,1,1 | Random | Medium |
| T6 | Back-to-back 0s: din=0,0,0 | Random | Medium |
| T7 | Alternating: din=0,1,0,1 | Random | Medium |
| T8 | Reset during din=1 | Directed | High |
| T9 | Reset held for multiple cycles | Directed | Medium |

## 4. Coverage Targets

| Coverpoint | Target |
|------------|--------|
| `din` values (0, 1) | 100% |
| `rst` values (0, 1) | 100% |
| `dout` values (0, 1) | 100% |
| Cross: din × rst | 100% (all 4 combinations) |
| din transitions (0→0, 0→1, 1→0, 1→1) | 100% |

## 5. Assertions

| ID | Property | Type |
|----|----------|------|
| A1 | When !rst, dout == $past(din) after posedge clk | Concurrent |
| A2 | When rst, dout == 0 after posedge clk | Concurrent |
| A3 | When din stable and !rst, dout stable | Concurrent |

## 6. Testbench Architecture

Class-based layered testbench:
- **Transaction** — rand din, observed dout, deep copy
- **Generator** — constrained random stimulus, sends to driver + scoreboard
- **Driver** — drives DUT via virtual interface
- **Monitor** — passively captures DUT output
- **Scoreboard** — compares actual vs expected, tracks pass/fail
- **Environment** — wires components, runs test phases (reset → fork → finish)

## 7. Pass Criteria

- 0 assertion failures
- 0 scoreboard mismatches
- 100% functional coverage on all coverpoints
- Simulation completes without timeout
