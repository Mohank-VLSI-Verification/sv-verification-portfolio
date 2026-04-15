# Coverage Report — I2C

## Simulation Details

| Parameter | Value |
|-----------|-------|
| Simulator | Vivado XSIM 2025.2 |
| Transactions | 20 |
| Sim Time | 1601295 ns |
| Seed | default |

## Scoreboard Summary

| Metric | Count |
|--------|-------|
| PASS | 13 |
| FAIL | 7 |
| TOTAL | 20 |

## Result

13 out of 20 transactions passed. All 7 failures are **read operations**. Write path verified clean with zero failures.

## Failure Analysis

Read failures show `exp:N got:0` pattern — the scoreboard expected data at the address but the DUT returned 0. Root cause: I2C master's READ_DATA state has a timing misalignment when sampling SDA. The master samples SDA at a hardcoded count value (`count1 == 200`) which doesn't align correctly with the slave's data output timing in all cases.

This is a **real RTL bug** found by the testbench — demonstrating that the verification environment successfully catches design issues. The write path (master→slave) works correctly; the read path (slave→master) has an SDA sampling window problem.

## Bug documented in bug_log.md
