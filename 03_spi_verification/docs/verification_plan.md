# Verification Plan — SPI (Master + Slave)

## 1. DUT Specification

| Parameter | Value |
|-----------|-------|
| Module | `top` (wraps `spi_master` + `spi_slave`) |
| Data width | 12 bits |
| Bit order | LSB first |
| sclk | Generated from clk (divide by 22) |
| CS | Active-low during transmission |
| Protocol | Master drives mosi, slave reads mosi, asserts done on completion |

## 2. Verification Goals

Prove the SPI master+slave correctly:
- Transmits 12-bit data from master to slave via mosi
- Slave output matches master input after transfer
- CS goes low at start, high at end of transfer
- Done asserts after all 12 bits received
- MOSI is idle (low) when CS is high
- Handles reset correctly
- Handles back-to-back transfers

## 3. Test Scenarios

| ID | Scenario | Method | Priority |
|----|----------|--------|----------|
| T1 | Single 12-bit transfer | Directed | High |
| T2 | Data integrity (din == dout) | Random | High |
| T3 | Back-to-back transfers | Random | High |
| T4 | Reset during idle | Directed | Medium |
| T5 | Reset during active transfer | Directed | High |
| T6 | All zeros transfer (12'h000) | Directed | Medium |
| T7 | All ones transfer (12'hFFF) | Directed | Medium |
| T8 | Alternating bits (12'hAAA, 12'h555) | Directed | Medium |
| T9 | Multiple random transfers (10+) | Random | High |

## 4. Coverage Targets

| Coverpoint | Target |
|------------|--------|
| `newd` values (0, 1) | 100% |
| `done` values (0, 1) | 100% |
| `cs` values (0, 1) | 100% |
| `din` boundary values (0, FFF) | 100% |
| Transfer count (1, 2, 5, 10) | 100% |

## 5. Assertions

| ID | Property | Type |
|----|----------|------|
| A1 | CS goes low within 3 sclk cycles of newd | Concurrent |
| A2 | CS returns high within 3 sclk cycles of done | Concurrent |
| A3 | Done asserts within 50 sclk cycles after CS falls | Concurrent |
| A4 | dout matches din when done rises | Concurrent |
| A5 | MOSI is 0 when CS is high (idle) | Concurrent |

## 6. Pass Criteria

- 0 assertion failures
- 0 scoreboard mismatches
- Simulation completes without timeout
