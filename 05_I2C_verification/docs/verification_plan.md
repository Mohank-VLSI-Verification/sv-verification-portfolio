# Verification Plan — I2C (Master + Slave)

## 1. DUT Specification

| Parameter | Value |
|-----------|-------|
| Module | `i2c_top` (wraps `i2c_master` + `i2c_slave`) |
| Data width | 8 bits |
| Address width | 7 bits |
| System clock | 40 MHz |
| I2C clock | 100 kHz (standard mode) |
| SDA | Bidirectional, open-drain (active-low with pull-up) |
| SCL | Master-generated |
| Slave memory | 128 bytes, initialized to mem[i] = i |
| Protocol | Start → Address+R/W → ACK → Data → ACK → Stop |

## 2. Verification Goals

Prove the I2C master+slave correctly:
- Writes 8-bit data to slave memory at specified address
- Reads 8-bit data from slave memory and returns correct value
- Generates proper start and stop conditions
- Handles ACK/NACK handshaking
- Busy flag asserts during transfer, deasserts on completion
- Done flag asserts after transfer completes
- ack_err flags NACK conditions
- Handles reset correctly

## 3. Test Scenarios

| ID | Scenario | Method | Priority |
|----|----------|--------|----------|
| T1 | Single write to slave | Directed | High |
| T2 | Single read from slave | Directed | High |
| T3 | Write then read same address (data integrity) | Random | High |
| T4 | Multiple writes to different addresses | Random | High |
| T5 | Multiple reads from different addresses | Random | High |
| T6 | Alternating read/write (50/50) | Random | High |
| T7 | Write to constrained address range (2-4) | Constrained random | Medium |
| T8 | Reset during idle | Directed | Medium |
| T9 | Back-to-back transactions | Random | Medium |
| T10 | Read initial memory values (mem[i]=i) | Directed | Medium |

## 4. Assertions

| ID | Property | Type |
|----|----------|------|
| A1 | Busy asserts within 10 clk cycles of newd | Concurrent |
| A2 | Done asserts within 100000 clk cycles of busy | Concurrent |
| A3 | Busy deasserts within 5 clk cycles of done | Concurrent |
| A4 | Done and newd never active simultaneously | Concurrent |

## 5. Pass Criteria

- 0 assertion failures
- 0 scoreboard read mismatches
- All writes stored correctly in golden model
- Simulation completes without timeout
