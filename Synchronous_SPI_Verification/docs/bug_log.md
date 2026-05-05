# Bug Log — SPI

## Bugs Found

| # | Description | Severity | Found By | Status |
|---|-------------|----------|----------|--------|
| 1 | Transaction missing display() method | Low | Code review | Fixed |
| 2 | Monitor creates tr outside loop — potential shared reference | Low | Code review | Fixed |
| 3 | Unused FSM states (enable, comp) defined in master | Low | Code review | Fixed |
| 4 | Width mismatch: 12-bit temp assigned 8'h00 in master idle | Medium | Code review | Fixed |
| 5 | State initialization in declaration — not reliably synthesizable | Low | Code review | Fixed |
| 6 | Interface missing modport | Low | Code review | Fixed |
| 7 | No timeout mechanism | Medium | Code review | Fixed |
| 8 | No scoreboard summary report | Low | Code review | Fixed |

## Bug Details

### Bug #4: Width mismatch in master

**Location:** `spi_master.sv` — IDLE state
**Original:** `temp <= 8'h00;`
**Problem:** `temp` is 12 bits wide but assigned an 8-bit literal. Works in simulation (zero-extends) but is a code quality issue — tools may warn, and it signals carelessness to reviewers.
**Fix:** Changed to `temp <= 12'h000;`

---

### Bug #3: Unused FSM states

**Location:** `spi_master.sv`
**Original:** `typedef enum bit [1:0] {idle = 2'b00, enable = 2'b01, send = 2'b10, comp = 2'b11}`
**Problem:** States `enable` and `comp` are defined but never used in the case statement. Dead code that confuses readers and wastes encoding space.
**Fix:** Removed unused states, kept only `IDLE` and `SEND`.

---

### Bug #5: Declaration initialization

**Location:** `spi_master.sv`, `spi_slave.sv`
**Original:** `state_type state = idle;`, `reg [11:0] temp = 12'h000;`
**Problem:** Initial values in declarations work in simulation but are not reliably synthesizable across all tools. Reset block should handle all initialization.
**Fix:** Removed declaration initialization, added proper reset handling.
