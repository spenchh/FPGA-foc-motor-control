# FPGA software side

This folder contains the FPGA-side Verilog for the SURG motor-controller bring-up layer

The current setup is:

- Zynq SoC target, likely Arty Z7-10
- PS side handles higher-level control, parameters, logging, communication, and slow bring-up commands
- PL side handles deterministic PWM timing, sample strobes, fast inhibit behavior, and simple sensor checks
- software/math produces three phase duty commands
- PL expands those three duty commands into the physical PCB driver-input pins: `MCU HI/LO A/B/C`
- near-term control assumption is Hall-assisted FOC / bring-up before any fully sensorless FOC path

## Verilog files needed right now

- `rtl/pwm_3phase_center_aligned.v`
  - center-aligned phase duty timing
  - inputs are `duty_a`, `duty_b`, and `duty_c`
  - outputs physical HI/LO pairs for phases A/B/C
  - includes `enable`, `pwm_inhibit`, `nonoverlap_ticks`, PWM-peak strobe, cycle strobe, and configuration-error output
  - loads duty updates together at the PWM cycle boundary

- `rtl/hall_decoder.v`
  - decodes digital Hall A/B/C states into an electrical sector
  - tracks valid/illegal Hall states and skipped transitions
  - needed because updated board labels show Hall A/B/C into the controller header
  - hardware still needs the 5 V Hall pullup issue checked before connecting to Zynq IO

- `rtl/phase_current_balance_monitor.v`
  - accepts measured `ia_q`, `ib_q`, and `ic_q`
  - checks whether `Ia + Ib + Ic` stays inside the allowed balance limit
  - matches the updated board assumption that A/B/C current sense are all available
  - this is a measurement-consistency check, not the actual overcurrent check

- `rtl/phase_current_limit_monitor.v`
  - checks each measured phase current against a configured absolute limit
  - catches the case where all three phase currents are large even if they still sum close to zero

- `rtl/voltage_sense_monitor.v`
  - accepts phase-voltage and bus-voltage sense values
  - checks whether voltage readings stay inside configured limits
  - exists because voltage sense should be handled like current sense in the software/FPGA interface

- `rtl/pcb_disable_control.v`
  - controls PWM enable and PCB `DISABLE`
  - treats `DISABLE` as active-high disable based on the updated board cross-check
  - does not assume a separate PCB fault-status net

## Testbenches needed right now

- `tb/tb_pwm_3phase_center_aligned.v`
- `tb/tb_hall_decoder.v`
- `tb/tb_phase_current_balance_monitor.v`
- `tb/tb_phase_current_limit_monitor.v`
- `tb/tb_voltage_sense_monitor.v`
- `tb/tb_pcb_disable_control.v`

## Not in the required path right now

- a dedicated `fault_manager.v` block tied to `nOC` or `FAULT`
- phase-C current reconstruction as the main current path

The updated board points toward measured A/B/C current, plus controller-side inhibit from current/voltage/status conditions

## Open Hardware Questions

- exact Arty Z7 pin map and XDC names
- whether Hall signals are level-shifted/protected for 3.3 V logic
- current-sense shunt values and bidirectional offset
- voltage-sense ADC-side range
- ADC route for current, voltage, and motor therm
- dead-time policy between FPGA non-overlap and UCC21222 resistor-programmed dead time
- final PWM frequency
- isolated 12 V source and OPA4388 symbol pin mapping before fabrication
