# Coverage Report — UART

## Simulation Details

| Parameter | Value |
|-----------|-------|
| Simulator | Vivado XSIM 2025.2 |
| Transactions | 5 |
| Sim Time | 126230 ns |
| Seed | default |

## Scoreboard Summary

| Metric | Count |
|--------|-------|
| PASS | 5 |
| FAIL | 0 |
| TOTAL | 5 |

## Result

All 5 UART transactions completed successfully. Both TX path (write) and RX path (read) verified clean. TX data matched between driver-sent and monitor-captured serial bits. RX data matched between driver-driven bits and slave output.
