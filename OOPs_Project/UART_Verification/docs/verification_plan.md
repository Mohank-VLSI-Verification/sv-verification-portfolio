# Verification Plan — UART (TX + RX)

## 1. DUT Specification

| Parameter | Value |
|-----------|-------|
| Module | `uart_top` (wraps `uarttx` + `uartrx`) |
| Data width | 8 bits |
| Baud rate | Parameterized (default: 9600) |
| Clock freq | Parameterized (default: 1 MHz) |
| TX protocol | Start bit (0) + 8 data bits (LSB first) + idle (1) |
| RX protocol | Detect start bit (rx=0), shift in 8 bits, assert donerx |

## 2. Verification Goals

Prove the UART correctly:
- Transmits 8-bit data serially (LSB first) with correct start bit
- Receives 8-bit data and presents on doutrx with donerx flag
- TX line is idle (high) when no transmission active
- donetx asserts after all bits transmitted
- donerx asserts after all bits received
- Handles reset correctly on both TX and RX paths
- Handles alternating TX/RX operations

## 3. Test Scenarios

| ID | Scenario | Method | Priority |
|----|----------|--------|----------|
| T1 | Single TX transfer | Directed | High |
| T2 | Single RX transfer | Directed | High |
| T3 | TX data integrity (dintx matches monitored tx bits) | Random | High |
| T4 | RX data integrity (driven rx bits match doutrx) | Random | High |
| T5 | Alternating TX/RX operations | Random (randc) | High |
| T6 | Back-to-back TX transfers | Random | Medium |
| T7 | Back-to-back RX transfers | Random | Medium |
| T8 | Reset during TX | Directed | Medium |
| T9 | Reset during RX | Directed | Medium |
| T10 | All zeros TX (8'h00) | Directed | Low |
| T11 | All ones TX (8'hFF) | Directed | Low |

## 4. Assertions

| ID | Property | Type |
|----|----------|------|
| A1 | donetx asserts within 5000 clk cycles after newd | Concurrent |
| A2 | donerx asserts within 5000 clk cycles after start bit | Concurrent |
| A3 | donetx and donerx not both active simultaneously | Concurrent |

## 5. Pass Criteria

- 0 assertion failures
- 0 scoreboard mismatches
- Simulation completes without timeout
