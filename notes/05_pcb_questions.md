# PCB and Hardware Questions

Use this before the schematic/pinout gets locked, because changing pins later is pain.

## Project Scope

1. Is this PCB a low-voltage learning board or the final 96 V inverter?
2. If it is low-voltage, what exact voltage/current limit is it designed for?
3. If it is 96 V-class, what transient margin is assumed?
4. What is the first test motor?
5. What is the final target motor?

## Gate Driver and Power Stage

1. What exact gate driver is being used?
2. Is the gate driver rated for the target bus voltage?
3. Is the power stage MOSFET-based or IGBT-based?
4. Is the control mode 3PWM or 6PWM?
5. If 6PWM, where is deadtime inserted?
6. What is the default safe state at power-up?
7. Is `ENABLE` pulled down so the inverter stays off during reset?
8. Does `nFAULT` go to FPGA, MCU, or both?
9. Is there a hardware fast-shutdown path independent of firmware?

## Current Sensing

1. Are we measuring two phase currents, three phase currents, or DC bus current?
2. Are current sensors low-side shunts, inline shunts, Hall sensors, or isolated amplifiers?
3. What ADC is used?
4. Does the ADC route to FPGA, MCU, or both?
5. What is ADC sample rate?
6. What is ADC resolution?
7. Can current sampling be synchronized to the PWM center?
8. Is current-sensor bandwidth enough for the target PWM/current-loop frequency?

## Rotor Position

1. Are we using Hall sensors, encoder, magnetic encoder, resolver, or sensorless?
2. Does raw position data go to the FPGA?
3. What voltage level are the position signals?
4. Do Hall sensors need pullups?
5. How is electrical angle offset calibrated?

## MCU/FPGA Interface

1. How do MCU and FPGA communicate: SPI, UART, parallel bus, AXI, or something else?
2. What commands does MCU send to FPGA?
3. What telemetry does FPGA send to MCU?
4. Is there a watchdog between MCU and FPGA?
5. What happens if MCU freezes?
6. What happens if FPGA freezes?

## High-Voltage Layout

1. What creepage/clearance rules are being used?
2. Are high-voltage and low-voltage grounds separated intentionally?
3. Is CAN isolated?
4. Are digital isolators needed between controller logic and gate driver?
5. Are isolation slots needed?
6. Are phase-current paths short and wide?
7. Are Kelvin sense routes used where needed?
8. Where are fuses/contactors/precharge components?

## Safety

1. What faults disable PWM immediately?
2. What faults only log/warn?
3. Who owns re-arm after a fault?
4. Is motor temperature measured?
5. Is MOSFET or PCB temperature measured?
6. Is throttle plausibility checked?
7. Is startup-at-zero-throttle required?
8. Is brake input handled?
9. Is forward/reverse handled?
