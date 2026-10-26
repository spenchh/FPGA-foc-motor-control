# Recreate the simulations and implementation flow

Begin with simulation. A computer, Git, Python 3, and Icarus Verilog are enough. An FPGA, motor, power board, MATLAB license, and Vivado installation are unnecessary for the first result.

## 1. Get the source

```sh
git clone https://github.com/spenchh/FPGA-foc-motor-control.git
cd FPGA-foc-motor-control
git rev-parse HEAD
```

Record the printed revision with your results. The handbook's annotated RTL is pinned to `403730d5a780dc507cf42e4a531a077aca57214a`. The documentation and reproduction helpers were added afterward; they do not change the 13 design modules.

On Ubuntu or Ubuntu under WSL, a typical setup is:

```sh
sudo apt update
sudo apt install git python3 iverilog gtkwave
python3 --version
iverilog -V
vvp -V
```

GTKWave is optional. Native Windows and macOS also work when Python and Icarus are installed and visible in the same terminal. On a system whose interpreter command is `python`, use that in place of `python3`. See the [official Icarus installation guide](https://steveicarus.github.io/iverilog/usage/installation.html).

## 2. Run all existing directed tests

```sh
python3 rtl/sim/run_tests.py
```

The runner discovers `rtl/design/*.sv` and `rtl/verif/tb_*.sv`, compiles each test as its own simulation top, and runs it. Every test must return successfully and print its `PASS:` marker. A mismatch or timeout fails the run. Expect `13/13 testbenches passed` at the end.

This result means the selected expected-value checks passed. It does not prove arbitrary sample alignment, complete protection coverage, or stable physical motor control.

## 3. Inspect a waveform

```sh
python3 rtl/sim/trace_test.py tb_pi_controller_q15
gtkwave build/waves/tb_pi_controller_q15.vcd
```

In GTKWave, expand `trace_harness.test.dut` and add `clk`, `rst`, `sample_valid`, `v1`, `v2`, `v3`, `control_valid`, `err_s1`, `p_mult_s2`, `i_mult_s2`, `integrator_q`, and `output_q`. Use signed decimal display for signed codes. Divide a Q1.15 code by 32768 to interpret its normalized value.

The first accepted PI update has error 4096, P=2048, I=1024 and output 3072. The second update has I=2048 and output 4096. Compare the registers just after rising edges, when nonblocking updates have settled.

Other useful traces:

```sh
python3 rtl/sim/trace_test.py tb_foc_current_loop_top
python3 rtl/sim/trace_test.py tb_pwm_3phase_center_aligned
python3 rtl/sim/trace_test.py tb_pcb_disable_control
```

The integrated test uses a large PWM period and completes before one full carrier cycle. Use the standalone PWM test for complete cycles. A saved VCD records the same directed test; it does not expand its stimulus.

## 4. Understand the integrated numerical example

With each ADC and offset at 2048, measured currents are zero. At angle zero, `sin=0` and `cos=32767`. The test requests `iq_ref=4096` with `kp=16384`, `ki=0`. The q voltage command is 2048. Inverse Park truncates its beta voltage to 2047; phase reconstruction produces 1772 and -1772. With `period=1000`, the duty codes settle to A=500, B=527, C=472.

These exact codes follow the RTL's arithmetic shifts. B and C are not exact real-number mirror images because negative right shifts round down. The existing integrated test checks B>C, not every intermediate value. See the [worked walkthrough](https://spenchh.github.io/fpga-motor-control-lab/#/walkthrough).

## 5. Run the integrated test with Vivado/xsim

Use a Vivado command shell with `xvlog`, `xelab`, and `xsim` on PATH. The following Linux/WSL shell commands assume Vivado itself is configured there. Run from the repository root:

```sh
mkdir -p build/xsim
cd build/xsim
xvlog -sv ../../rtl/design/*.sv ../../rtl/verif/tb_foc_current_loop_top.sv
xelab --debug typical --relax --mt 2 -L work -snapshot foc_loop work.tb_foc_current_loop_top
xsim foc_loop -runall
```

For the Vivado GUI, create a project, add `rtl/design/*.sv` as design sources, add the selected `rtl/verif/tb_*.sv` as simulation sources, set the simulation top to that testbench, and run behavioral simulation. Select SystemVerilog for `.sv` files. The project's part setting is needed for implementation; behavioral tests do not establish placement or routing timing.

The archived direct xsim top test ended at 516 ns. That timestamp includes reset and checking and is not a sample-to-duty latency measurement. The new portable command layout requires a local Vivado installation; it has not been rerun in the documentation update environment.

## 6. Implement the reduced-I/O wrapper

From a Vivado command shell, at the repository root:

```sh
vivado -mode batch -source synth/run_wrapper.tcl
```

The default target is `xc7z010clg400-1` with a 10 ns clock. The script reads the current `rtl/design/*.sv` paths, synthesizes `foc_synth_wrapper`, optimizes, places, physically optimizes and routes, then saves checkpoints and reports in `build/vivado-wrapper/`.

The original published result was WNS=+0.557 ns, TNS=0 and WHS=+0.034 ns. A fresh run depends on source, tool version, target, constraints, directives and implementation choices. The new script supplies a portable flow; it does not guarantee an identical route or slack. It has been structurally checked, not executed with Vivado during this documentation update.

Inspect `post_route_timing_summary.rpt`, `critical_paths.rpt`, `post_route_utilization_hierarchical.rpt` and `check_timing.rpt`. Check setup, hold, clocks, unconstrained paths and external I/O warnings. A single positive WNS does not establish complete board timing.

## 7. Keep the targets distinct

The recorded route targets the earlier XC7Z010 configuration. Cora Z7 is the later board-integration direction. A different board requires its actual FPGA part, clock source, reset scheme, package pins, voltage standards and new timing constraints. The wrapper uses internally generated samples and a debug sink, so its ports are not the final motor-controller connector.

The helper deliberately does not write a bitstream. Complete the interface contract and [known limitations](KNOWN_LIMITATIONS.md) before treating the RTL as a powered motor controller.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `iverilog` or `vvp` not found | Install both and restart the terminal; verify both commands on PATH |
| Python cannot find the runner | Run from the cloned repository root |
| Syntax errors around `logic` or `always_ff` | Use SystemVerilog mode (`-g2012` for Icarus) |
| Top module not found | Select the exact `tb_*` name, without `.sv`, in the trace helper |
| Waveform appears one edge late | Account for old-value nonblocking semantics and downstream register capture |
| PWM never enables | Check reset, enable request, sensor/duty readiness, latched faults and configuration validity |
| Current values do not look like amperes | They are codes; check the physical base current, zero offset and scaler coefficient |
| Vivado cannot place the raw top | Use the reduced-I/O wrapper for this experiment; the raw top exposes configuration buses as package I/O |
