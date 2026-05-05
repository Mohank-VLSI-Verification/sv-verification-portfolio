# Verification Plan — AXI4-Lite Slave

## 1. DUT Specification

| Parameter | Value |
|-----------|-------|
| Module | `axilite_s` |
| Protocol | AXI4-Lite (AMBA) |
| Data width | 32 bits |
| Address width | 32 bits |
| Memory | 128 x 32-bit words |
| Reset | Active-low (aresetn) |
| Write channels | AW (address) → W (data) → B (response) |
| Read channels | AR (address) → R (data + response) |
| Error response | DECERR (2'b11) for address >= 128 |

## 2. Verification Goals

Prove the AXI4-Lite slave correctly:
- Accepts write address on awvalid/awready handshake
- Accepts write data on wvalid/wready handshake
- Stores data in memory at specified address
- Returns write response (OKAY or DECERR) on bvalid/bready
- Accepts read address on arvalid/arready handshake
- Returns correct data from memory on rvalid/rready
- Returns DECERR for out-of-range addresses (>= 128)
- Resets all outputs on aresetn

## 3. Test Scenarios

| ID | Scenario | Method | Priority |
|----|----------|--------|----------|
| T1 | Single write transaction | Random | High |
| T2 | Single read transaction | Random | High |
| T3 | Write then read same address | Random | High |
| T4 | Write to multiple addresses | Random | High |
| T5 | Read from multiple addresses | Random | High |
| T6 | Write to invalid address (>= 128) | Directed | High |
| T7 | Read from invalid address (>= 128) | Directed | High |
| T8 | Alternating read/write (randc) | Random | High |
| T9 | Reset during idle | Directed | Medium |
| T10 | Back-to-back writes | Random | Medium |

## 4. Assertions

| ID | Property | Type |
|----|----------|------|
| A1 | awready responds within 5 cycles of awvalid | Concurrent |
| A2 | wready responds within 10 cycles of wvalid | Concurrent |
| A3 | bvalid asserts within 20 cycles after write | Concurrent |
| A4 | arready responds within 5 cycles of arvalid | Concurrent |
| A5 | rvalid asserts within 20 cycles after read address | Concurrent |
| A6 | All outputs cleared after reset | Concurrent |
| A7 | wresp is either OKAY (00) or DECERR (11) | Concurrent |

## 5. Pass Criteria

- 0 assertion failures
- 0 scoreboard read mismatches
- All DECERR responses for invalid addresses
- Simulation completes without timeout
