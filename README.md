# UART RX Verification Using SystemVerilog UVM

A **SystemVerilog Universal Verification Methodology (UVM)** testbench for verifying an 8-bit UART receiver. The environment generates UART serial frames, monitors the receiver's parallel output, and uses a scoreboard to compare expected and actual data. Directed and randomized stimulus, false-start recovery testing, and code coverage collection are included.

## Highlights

- Transaction-level, reusable **UVM verification environment**
- UART serial stimulus generation with **start bit, 8 data bits (LSB first), and stop bit**
- Reference transactions delivered through a **UVM analysis port**
- Output monitoring using the DUT's `o_valid` and `o_data` signals
- Automatic expected-versus-actual comparison in a **scoreboard**
- Directed corner-case patterns and randomized UART data
- False-start rejection and receiver recovery test
- **32/32 frames matched** in the demonstration test, with no UVM errors
- **98.16% total code coverage** reported for the DUT instance; **100% FSM state and transition coverage**

## DUT Specifications

| Parameter | Value |
| --- | --- |
| Module | `receiver` (UART RX) |
| Clock frequency | 10 MHz |
| UART baud rate | 115,200 bps |
| Data width | 8 bits |
| Bit order | LSB first |
| Start bits | 1 (logic `0`) |
| Stop bits | 1 (logic `1`) |
| Parity | None |
| Output | `o_data[7:0]` and a one-clock-cycle `o_valid` pulse |

Each UART frame uses the **8N1** format:

```text
Idle (1) | Start (0) | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 | Stop (1) | Idle (1)
                           <--------- LSB first --------->
```

At 10 MHz and 115,200 baud, the nominal bit duration is approximately 86.8 system-clock cycles. The DUT coverage report shows a clock counter compared against 87 cycles.

## UVM Testbench Architecture

```text
                       +--------------------+
                       |      UVM Test      |
                       +---------+----------+
                                 |
                       +---------v----------+
                       |  UART Sequence(s)  |
                       +---------+----------+
                                 |
                       +---------v----------+
                       |     Sequencer      |
                       +---------+----------+
                                 |
                +----------------v----------------+
                |          UART Driver            |
                |  Serialize: start + data + stop |
                +--------+---------------+--------+
                         |               |
                   Serial RX       Reference transaction
                         |               |
                +--------v--------+      |
                |     UART RX     |      |
                |      DUT        |      |
                +--------+--------+      |
                         |               |
                   o_valid/o_data         |
                         |               |
                +--------v--------+      |
                | Output Monitor  |      |
                +--------+--------+      |
                         |               |
                   Actual transaction    |
                         |               |
                         v               v
                     +-----------------------+
                     |    UVM Scoreboard     |
                     |   Expected vs Actual  |
                     +-----------------------+
```

### Verification Components

| Component | Responsibility |
| --- | --- |
| **UART transaction** | Holds randomized 8-bit payload data. |
| **Sequence / Sequencer** | Creates and supplies UART transactions to the driver. |
| **UART driver** | Adds start and stop bits, drives the serial RX input, and publishes the expected transaction via an analysis port. |
| **UART monitoring** | Observes UART reception / stop-bit behavior and captures `o_data` when `o_valid` is asserted. |
| **Scoreboard** | Compares expected payloads against actual received bytes and reports matches or failures. |
| **UVM environment** | Instantiates and connects agents, monitors, and scoreboard. |
| **UVM tests** | Configure and execute normal data reception and error-recovery scenarios. |

### Verification Flow

1. A sequence generates a UART transaction containing an 8-bit value.
2. The driver serializes the transaction into an 8N1 frame and drives the DUT RX line.
3. The driver forwards the original payload to the scoreboard as the **expected** value.
4. The monitor observes the receiver, including stop-bit behavior, and captures the DUT output when `o_valid` is asserted.
5. The monitor sends the captured `o_data` to the scoreboard as the **actual** value.
6. The scoreboard compares expected and actual bytes and reports the result.

## Test Scenarios

| Test | Description | Observed result |
| --- | --- | --- |
| `uart_demo_test` | Directed patterns followed by additional payloads; verifies UART reception and scoreboard matching. | **PASS — 32/32 frames matched** |
| `uart_err_test` | Injects a false start, verifies rejection, and checks successful reception of recovery byte `0xA5`. | **PASS** |

Examples of directed patterns in the demo test include `0x00`, `0xFF`, `0x55`, `0xAA`, `0x01`, and `0x80`. Additional payloads are exercised in the same run.

## Simulation

**Simulator used:** Siemens QuestaSim 2021.2_1 with UVM support.

After compiling and optimizing the DUT and UVM testbench with your project's simulation scripts, run the corresponding test. The commands below reproduce the invocations shown in the supplied logs; they assume `top`, `vopt_top`, `sim.do`, and `cov.do` have been set up as in the project.

### Normal UART reception test with coverage

```bash
vsim -c -sv_seed random -coverage vopt_top -do cov.do +UVM_TESTNAME=uart_demo_test
```

### False-start recovery test

```bash
vsim -c top -do sim.do +UVM_TESTNAME=uart_err_test
```

### DUT code coverage report

After generating or merging the coverage database into `merged.ucdb`:

```bash
vcover report -details -codeAll -instance=/top/dut0 merged.ucdb
```

> **Note:** Compilation and optimization commands are project-specific and are not included here because they are not shown in the available simulation logs.

## Verification Results

### UART data reception

The `uart_demo_test` simulation successfully compared **32 transmitted and received frames**.

```text
[DRV]      Driving UART frame: data = 0x55 (8'b01010101)
[SLV_MON]  Captured DUT output: o_data = 0x55 (8'b01010101)
[SB_MATCH] Frame #3 MATCH | expected=0x55 == actual=0x55

[DRV]      Driving UART frame: data = 0xaa (8'b10101010)
[SLV_MON]  Captured DUT output: o_data = 0xaa (8'b10101010)
[SB_MATCH] Frame #4 MATCH | expected=0xaa == actual=0xaa

[SB_PASS] Successfully compared 32 frames with no errors

UVM_WARNING : 0
UVM_ERROR   : 0
UVM_FATAL   : 0
```

### False-start rejection and recovery

The `uart_err_test` reports that the receiver rejected a false start and correctly received the following valid byte:

```text
[ERR_PASS] False start rejected and recovery byte A5 received

UVM_WARNING : 0
UVM_ERROR   : 0
UVM_FATAL   : 0
```

### DUT code coverage

Coverage was collected for **`/top/dut0` (`work.receiver`)** and reported using QuestaSim `vcover`.

| Coverage metric | Covered / Total | Coverage |
| --- | ---: | ---: |
| Branch | 17 / 18 | **94.44%** |
| Condition | 4 / 4 | **100.00%** |
| FSM states | 5 / 5 | **100.00%** |
| FSM transitions | 6 / 6 | **100.00%** |
| Statement | 36 / 37 | **97.29%** |
| Toggle | 70 / 72 | **97.22%** |
| **Total coverage by instance (filtered view)** | — | **98.16%** |

All five receiver FSM states were covered:

```text
s_IDLE -> s_RX_START_BIT -> s_RX_DATA_BITS -> s_RX_STOP_BIT
   ^                                                  |
   |                  s_CLEANUP <----------------------+
   +----------------------+

False-start recovery: s_RX_START_BIT -> s_IDLE
```

**Remaining uncovered areas:** one branch, one statement, and two toggle bins. The coverage report identifies the missed branch/statement around line 134–135 of `receiver.v` and the missing toggles on `r_Clock_Count[7]`. These are candidates for further coverage analysis; the report alone does not establish whether they are reachable.

> The reported **98.16%** is the simulator's *total coverage by instance (filtered view)*, not functional coverage or a claim that every UART error scenario has been tested.

## Technologies

- **Languages:** SystemVerilog, Verilog
- **Verification methodology:** UVM (Universal Verification Methodology)
- **Simulator and coverage:** Siemens QuestaSim 2021.2_1, `vcover`
- **Verification concepts:** Constrained-random stimulus, UVM sequences and agents, analysis ports, monitors, reference/actual scoreboarding, directed error testing, and code coverage

## Future Improvements

- Add dedicated stop-bit framing-error tests and checks, based on the receiver's documented error behavior.
- Add randomized inter-frame gaps and reset-during-reception scenarios.
- Introduce functional coverage for byte values, bit patterns, and error/recovery sequences.
- Analyze unreachable or unexercised RTL coverage bins.
- Add assertions for `o_valid` pulse width and output timing.

## Summary

This project demonstrates a modular UVM verification flow for a UART receiver, from transaction generation and serial stimulus through output monitoring, automated checking, error recovery, and RTL coverage analysis. The supplied simulation logs show **32 successful frame comparisons**, **successful false-start recovery**, **zero UVM errors**, and **98.16% reported total DUT code coverage**.
