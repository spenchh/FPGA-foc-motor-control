# SURG FPGA/MCU FOC Quick Notes

General notes. Longer version in `notes/01_main_notes.md`.

## Main Takeaway

Cleanest setup is probably FPGA/MCU split:

- MCU: throttle, CAN/logging, startup/re-arm, slow safety, user/system state machine.
- FPGA: current sensor input, rotor position input, current-loop FOC, PWM/SVPWM, deadtime, fast shutdown.
- Gate driver/hardware: logic-to-gate drive, hardware power-stage protection, fault output.

For safety it shouldn't be an FPGA-vs-MCU argument. It should be layered:

- Hardware/gate driver catches the fastest destructive faults.
- FPGA shuts PWM down fast and predictably.
- MCU handles policy, logging, and whether the system is allowed to restart.

Correction:

- SimpleFOC/DRV8320 is useful for low-voltage learning and stage-1 testing.
- DRV8320 is not suitable for the final 96 V inverter because its recommended `VM` range is up to 60 V.
- The final 96 V design needs a real high-voltage inverter design pass: gate driver, isolation, current sensing, protection, creepage/clearance, layout, thermal stuff, the whole deal.

Plan:

1. Stage 1: low-voltage prototype to prove FPGA current-loop FOC.
2. Stage 2: separate 96 V-class inverter after control architecture works.

FPGA stuff to actually work on:

1. Build floating-point Simulink FOC model.
2. Simulate PWM frequency vs current ripple.
3. Add closed-loop `id/iq` current control.
4. Convert HDL subsystem to fixed point.
5. Compare fixed point vs floating point.
6. Generate HDL and HDL testbench with HDL Coder.
7. Synthesize and report FPGA timing/resource usage.

PCB questions we should prolly ask before we all suffer:

1. Is the board low-voltage prototype or 96 V inverter?
2. What gate driver is used?
3. Is control 3PWM or 6PWM?
4. Where is deadtime inserted?
5. Does `nFAULT` go to both FPGA and MCU?
6. Where do current sensors route?
7. What ADC sample rate/resolution is planned?
8. What rotor position signal reaches the FPGA?
9. What is the isolation strategy?
10. Is there overcurrent protection faster than an MCU ADC loop?
