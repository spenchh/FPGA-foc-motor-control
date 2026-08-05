# SURG FPGA Motor Controller

![Project](https://img.shields.io/badge/status-active%20research-1f6feb?style=flat-square)
![Platform](https://img.shields.io/badge/FPGA-Arty%20Z7--10-2f4f4f?style=flat-square)
![Control](https://img.shields.io/badge/control-3PWM%20FOC-0076a8?style=flat-square)
![Tools](https://img.shields.io/badge/tools-MATLAB%20%7C%20Vivado%20%7C%20HDL%20Coder-555555?style=flat-square)

PCB-aware FPGA and MATLAB work for the SURG motor controller

Current local board files:

- `C:\Users\HP\Documents\SURG\DriverBoard.SchDoc`
- `C:\Users\HP\Documents\SURG\ActualDriverBoard.PcbDoc`
- `C:\Users\HP\Documents\SURG\HV Motor Driver.BomDoc`
- `C:\Users\HP\Documents\SURG\PCB_CROSSCHECK_2026-08-05.md`
- `C:\Users\HP\Documents\SURG\FPGA_KNOWN_INFO_2026-08-05.md`

## Current Board Interface

Confirmed from the updated cross-check:

- control still starts as three phase duty commands in software/math
- updated PCB exposes physical controller outputs for `MCU HI A`, `MCU LO A`, `MCU HI B`, `MCU LO B`, `MCU HI C`, and `MCU LO C`
- those six physical lines feed the three UCC21222 gate drivers through small RC input filters
- UCC21222 adds driver-side interlock/dead-time behavior, but there is no separate onboard logic block that creates the HI/LO input pairs for the FPGA
- `DISABLE` is routed to the UCC21222 disable pins and should be treated as active-high disable, drive low to run
- Hall A/B/C are digital labels routed to the controller header
- Hall pullups appear to be 5 V, so the Zynq/Arty input-level path needs to be checked before hardware connection
- current sense has three measured channels: `MCU CSENSE A`, `MCU CSENSE B`, and `MCU CSENSE C`
- voltage sense has `MCU VSENSE A` and `MCU VSENSE Vm`
- `MCU MOTOR THERM` is also present as an analog/controller input
- updated board text did not show `nOC` or `FAULT` nets

## FPGA Work

Active RTL:

- `fpga/rtl/pwm_3phase_center_aligned.v`
- `fpga/rtl/hall_decoder.v`
- `fpga/rtl/phase_current_balance_monitor.v`
- `fpga/rtl/phase_current_limit_monitor.v`
- `fpga/rtl/voltage_sense_monitor.v`
- `fpga/rtl/pcb_disable_control.v`

Active testbenches:

- `fpga/tb/tb_pwm_3phase_center_aligned.v`
- `fpga/tb/tb_hall_decoder.v`
- `fpga/tb/tb_phase_current_balance_monitor.v`
- `fpga/tb/tb_phase_current_limit_monitor.v`
- `fpga/tb/tb_voltage_sense_monitor.v`
- `fpga/tb/tb_pcb_disable_control.v`

What the FPGA layer is trying to cover right now:

- generate center-aligned phase duty timing
- expand three duty commands into the updated PCB's physical HI/LO driver-input pins
- keep all PWM outputs off during reset or inhibit
- create sample timing for current and voltage reads
- read Hall states if the voltage-level issue is handled
- monitor measured A/B/C current consistency
- monitor per-phase current limits separately from current consistency
- monitor phase/bus voltage limits
- drive the PCB `DISABLE` line from confirmed software-side inhibit conditions

This is bring-up/control-interface logic, not full fixed-point FOC yet

The current control path should be treated as Hall-assisted FOC / bring-up first. Sensorless FOC can be researched later, but it is not the immediate hardware bring-up assumption.

## MATLAB Work

Current MATLAB focus:

- fixed-point FOC starter math
- PI behavior and Q-format effects
- inverse Park / three duty-command generation
- board-interface check against the updated PCB labels
- current and voltage scaling placeholders until the analog path is confirmed

Run:

```matlab
foc_fixed_point_starter
stage1_3pwm_foc_sim
board_interface_check
```

## Things To Confirm Before PCB Order / Final HDL

- exact Arty Z7 shield-header pin map and XDC names
- whether shield IO is safe with the Hall pullups shown at 5 V
- whether analog signals use Arty XADC, an external ADC, or another route
- current-sense zero-current voltage and positive/negative-current representation
- PWM dead-time policy between FPGA non-overlap and UCC21222 resistor-programmed dead time
- current shunt values
- whether current sense has a mid-rail offset for bidirectional current
- final AMC1300 + OPA4388 gain, offset, and filtering
- whether current/voltage signals go into XADC, external ADC, or the Zynq PS side
- final voltage-sense ADC-side scaling and clamp/protection path
- motor thermistor scaling
- isolated 12 V source on the driver side
- OPA4388 symbol pin mapping versus datasheet pinout
- whether the resistor BOM entries with capacitor-looking MPNs are real mistakes
- final expected PWM frequency
