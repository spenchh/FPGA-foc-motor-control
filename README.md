# FPGA Field-Oriented Motor Control

A SystemVerilog implementation of a fixed-point current controller for a three-phase motor. It converts digitized phase currents and an electrical-angle input into inverter duty commands, complementary PWM, and protection outputs.

**New to this project?** Start with the [beginner learning guide](https://spenchh.github.io/fpga-motor-control-lab/#/start), then [recreate the simulations](docs/REPRODUCING.md). The [worked example](https://spenchh.github.io/fpga-motor-control-lab/#/walkthrough) follows actual integer values through the control path. No FPGA board is needed for those steps.

## Current state

Documentation reviewed against the SURG research notes and design sources on **26 October 2026**.

| Area | What exists | Boundary |
| --- | --- | --- |
| RTL | 13 design modules and 13 directed testbenches | See [known limitations](docs/KNOWN_LIMITATIONS.md) before extending the integrated top |
| Simulation | Portable Icarus regression; preserved Vivado/xsim evidence | Directed tests cover selected behaviors, not motor stability or complete corner coverage |
| Arithmetic | Q1.15 current/control values, wider products, shifts and saturation | Physical units require calibrated per-unit bases and ADC scaling |
| Implementation | Preserved XC7Z010 wrapper result: 100 MHz, WNS +0.557 ns, TNS 0, WHS +0.034 ns | The saved result belongs to a reduced-I/O wrapper; it is not a measured Cora board result |
| Board integration | Cora Z7 is the later integration direction | ADC acquisition, calibrated angle, AXI/PS software, final pin mapping and powered motor operation remain separate work |

The research investigated whether FPGA computation could support practical, efficient lightweight motor drives. Efficiency improvement and lower total system cost remain research questions; the results above establish RTL behavior and a specific implementation result.

## Run the existing tests

Install Python 3 and Icarus Verilog (`iverilog` and `vvp` on PATH), then run from this repository:

```sh
python3 rtl/sim/run_tests.py
```

Expected final line:

```text
13/13 testbenches passed
```

Save a waveform from an existing test without editing the testbench:

```sh
python3 rtl/sim/trace_test.py tb_pi_controller_q15
```

Open `build/waves/tb_pi_controller_q15.vcd` in a VCD viewer such as GTKWave. The trace harness instantiates the existing test and records its signals. It adds observability, not new test coverage.

## How the controller works

| Stage | Why it exists |
| --- | --- |
| ADC current scaling | Subtract zero-current offsets and map ADC counts into signed current codes |
| Clarke and Park | Express phase current in stationary αβ and then rotor-aligned dq coordinates |
| d/q PI regulators | Compare requested and measured current; calculate corrective voltage commands |
| Inverse Park | Return voltage commands to stationary coordinates |
| Phase duty generation | Reconstruct three phase commands and convert them into timer counts |
| Center-aligned PWM | Expand three duties into six HI/LO signals with a count-domain non-overlap window |
| Protection | Check phase magnitudes and current sum; inhibit drive and retain a fault |

The top accepts an electrical angle directly. The Hall decoder and voltage monitor are separately tested support modules. The current duty conversion is sinusoidal phase reconstruction, not SVPWM. Valid strobes accompany results, but the top's delayed handoffs and latest-held angle still need transaction-alignment work for arbitrary changing samples.

## Repository map

| Path | Contents |
| --- | --- |
| `rtl/design/` | Synthesizable design modules |
| `rtl/verif/` | Directed SystemVerilog testbenches with automatic checks |
| `rtl/sim/run_tests.py` | Compile and run all tests in temporary directories |
| `rtl/sim/trace_test.py` | Run one test and preserve a VCD waveform |
| `synth/foc_synth_wrapper.sv` | Reduced-I/O implementation wrapper with internal stimulus |
| `synth/run_wrapper.tcl` | Portable non-project Vivado flow using the current directory layout |
| `synth/wrapper_clock.xdc` | Historical 10 ns wrapper clock constraint |
| `docs/REPRODUCING.md` | Setup, simulations, waveforms, xsim and implementation steps |
| `docs/KNOWN_LIMITATIONS.md` | Current integration and arithmetic boundaries |

## Learn the decisions

- [Start from zero](https://spenchh.github.io/fpga-motor-control-lab/#/start)
- [Design choices and alternatives](https://spenchh.github.io/fpga-motor-control-lab/#/decisions)
- [Project history and source reconciliation](https://spenchh.github.io/fpga-motor-control-lab/#/history)
- [Study checkpoints and interview questions](https://spenchh.github.io/fpga-motor-control-lab/#/study)
- [Annotated design and testbench explorer](https://spenchh.github.io/fpga-motor-control-lab/#/rtl)
- [Preserved reports and verification evidence](https://spenchh.github.io/fpga-motor-control-lab/#/implementation)

The companion [documentation repository](https://github.com/spenchh/fpga-motor-control-lab) contains the illustrated handbook, pinned source snapshots, archived reports, and historical MATLAB models. Those MATLAB examples are conceptual models, not a bit-exact golden model for every current RTL block.
