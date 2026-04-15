# Coverage Report — AXI4-Lite

## Simulation Details

| Parameter | Value |
|-----------|-------|
| Simulator | Vivado XSIM 2025.2 |
| Transactions | 10 |
| Sim Time | 795 ns |
| Seed | default |

## Scoreboard Summary

| Metric | Count |
|--------|-------|
| PASS | 10 |
| FAIL | 0 |
| TOTAL | 10 |

## Result

All 10 AXI4-Lite transactions completed successfully. Write transactions stored data correctly in slave memory. Read transactions returned correct data matching the golden memory model. AXI handshake protocol (awvalid/awready, wvalid/wready, bvalid/bready, arvalid/arready, rvalid/rready) verified correct for all transactions.
