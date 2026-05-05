# Coverage Report — FIFO

## Simulation Details

| Parameter | Value |
|-----------|-------|
| Simulator | Vivado XSIM 2025.2 |
| Transactions | 30 |
| Sim Time | 1890 ns |
| Seed | default |

## Scoreboard Summary

| Metric | Count |
|--------|-------|
| PASS | 11 |
| FAIL | 0 |
| TOTAL | 11 |

## Result

11 out of 30 transactions were read operations with data available for comparison. All 11 matched. Remaining 19 transactions were writes (data stored in queue) or reads from empty FIFO (correctly rejected). Write path and read path both verified clean.
