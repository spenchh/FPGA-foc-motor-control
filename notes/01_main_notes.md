# SURG FPGA/MCU FOC Notes

## Project Goal

We are trying to see if FPGA-accelerated FOC can make lightweight motor control cheaper/more efficient than just buying a commercial controller. The basic idea is: lightweight motors usually have low inductance, so current can move around fast. If our current loop and PWM are faster/more deterministic, maybe we can reduce ripple and waste less energy.

## Current Architecture Direction

The current team notes point toward an FPGA/MCU split:

| Block | Responsibility |
|---|---|
| MCU | Receives throttle/command, handles CAN/logging, startup/re-arm logic, slow safety, user/system interface |
| FPGA | Reads current sensors, reads rotor position, runs current-loop FOC, generates PWM/SVPWM, inserts deadtime, handles fast shutdown |
| Gate driver | Converts logic-level PWM into MOSFET/IGBT gate drive |
| Inverter | Switches the DC bus into U/V/W motor phases |
| Motor/sensors | Provides current, position, and temperature feedback |

This split honestly makes sense. FPGA gets the fast loop; MCU gets the slower "manage the whole system and talk to stuff" job.

## Big Correction: SimpleFOC/DRV8320 Is Low Voltage

SimpleFOC and the DRV8320H board are useful for learning and low-voltage prototyping, but not for the final 96 V inverter.

- DRV8320 is a low-voltage MOSFET gate-driver family with recommended `VM` up to 60 V.
- Team notes mention a 96 V DC bus and Kelly controller class hardware.
- Therefore, SimpleFOC/DRV8320 can be stage-1 only.
- The final inverter needs a high-voltage design pass: gate-driver voltage margin, isolation, current sensing, creepage/clearance, protection, thermal design, and proper layout. Basically, we cannot just "scale up" a SimpleFOC shield and call it a day.

## Recommended Two-Stage Plan

### Stage 1: Low-Voltage Prototype

Goal: prove the control architecture without immediately messing with the spicy 96 V system.

```text
MCU:
  throttle filtering
  command generation
  CAN/logging
  startup/re-arm
  slow safety policy

FPGA:
  current sensing interface
  rotor position interface
  current-loop FOC
  PWM/SVPWM generation
  deadtime
  fast shutdown

Gate driver:
  low-voltage MOSFET gate driver or off-the-shelf driver

Motor:
  small low-voltage BLDC/PMSM
```

### Stage 2: 96 V-Class Prototype

Goal: build the real high-voltage inverter after the control loop is not sketchy anymore.

```text
Gate driver:
  selected for 96 V bus plus transient margin

Power stage:
  MOSFETs/IGBTs
  DC-link capacitors
  current sensors
  thermal design
  fusing/contactor/precharge

Isolation:
  CAN/logic/measurement isolation
  separated high-voltage and low-voltage domains

Protection:
  gate-driver faults
  hardware overcurrent
  FPGA fast shutdown
  MCU fault logging/re-arm policy
```

## Safety Split

Safety should be layered, not owned by only one chip. Putting everything on the MCU is too slow for some faults, but putting everything on the FPGA is also kinda doing too much.

| Layer | Location | Purpose |
|---|---|---|
| Hardware/gate driver | Gate driver, comparators, analog protection | Fastest MOSFET/inverter protection |
| Fast digital protection | FPGA | PWM inhibit, illegal state prevention, cycle-level shutdown |
| Supervisory safety | MCU | throttle plausibility, state machine, CAN faults, logging, re-arm |
| System safety | External hardware + MCU | E-stop, key switch, precharge, brake, operator controls |

Good rule:

> FPGA should be able to shut down PWM immediately. MCU should decide when the system may start again. Hardware should still protect the power stage if the digital side is having a bad day.

## FOC Data Path

Minimum current-loop FOC:

```text
phase currents ia/ib/ic
  -> Clarke transform
  -> Park transform using electrical angle
  -> id/iq PI current controllers
  -> voltage limiting / anti-windup
  -> inverse Park
  -> inverse Clarke or SVPWM
  -> PWM compare values
  -> gate driver
```

For our throttle-ish application:

- Throttle should map to `iq_ref`, not directly to duty cycle.
- `iq` controls torque.
- `id_ref` usually starts at 0.
- Rotor electrical angle is required for sensored FOC.
- Current sensing is required for real current-mode FOC.

## MATLAB / Simulink / HDL Coder Work

FPGA-side work should probably focus on:

1. Build a floating-point Simulink FOC reference model.
2. Add motor/inverter/current-sensor plant modeling.
3. Simulate PWM frequency vs current ripple.
4. Build closed-loop `id/iq` current control.
5. Convert the HDL subsystem to fixed point.
6. Compare fixed-point output to floating-point output.
7. Generate HDL using HDL Coder.
8. Generate an HDL testbench.
9. Simulate generated HDL.
10. Synthesize for target FPGA and report timing/resource usage.

Recommended HDL subsystem boundary:

- Inside FPGA/HDL: Clarke/Park, PI loops, inverse transforms/SVPWM, PWM generation, deadtime, fast fault shutdown.
- Outside HDL/FPGA fast loop: CAN, logging, user interface, high-level state machine, long-term fault policy.

## Fixed Point vs Floating Point

Floating point:

- Best for initial model/debugging.
- Easier dynamic range.
- More expensive in FPGA resources and latency.

Fixed point:

- More work, but better for FPGA area/power/latency.
- Needs range analysis, scaling, saturation, and overflow checks.
- Probably the right final implementation style for a compact motor controller, even though it is more annoying.

First-pass type ideas:

| Signal | Starting point |
|---|---|
| ADC current inputs | signed 16-18 bits |
| normalized current/voltage | signed Q1.15 or Q2.16 |
| sin/cos | signed Q1.15 |
| multiply intermediates | 24-32 bits |
| PI integrators | signed 32 bits |
| PWM duty | unsigned 12-16 bits |
| angle | unsigned 16-18 bits circular |

## Current Sensing Decision

This is a huge PCB/architecture decision.

If FPGA is doing real FOC, current samples should reach the FPGA with low latency.

Best direction:

- Current sensors -> ADC -> FPGA.
- FPGA computes current loop and PWM.
- MCU receives decimated telemetry/status.

Risky direction:

- Current sensors -> MCU ADC -> MCU sends values to FPGA.
- This may add latency/jitter and kinda defeats the point of using the FPGA for the fast loop.

## Rotor Position

Possible feedback:

- Hall sensors.
- Quadrature encoder.
- Magnetic encoder over SPI/I2C.
- Resolver.
- Sensorless observer later.

For the first prototype, use the simplest reliable sensored option. FPGA is good at quadrature counting, Hall capture, timestamping, and angle interpolation.

## PCB Meeting Questions

Stuff to ask before the schematic gets locked:

1. Is this PCB low-voltage learning hardware or the 96 V inverter?
2. What exact gate driver is being used?
3. Is PWM mode 3PWM or 6PWM?
4. Where is deadtime inserted?
5. Does `nFAULT` go to both FPGA and MCU?
6. Does the FPGA have a direct PWM shutdown path?
7. Where do current sensors route: FPGA, MCU, or both?
8. What ADC sample rate/resolution/latency is planned?
9. What rotor position signal goes to the FPGA?
10. What is the isolation strategy for CAN/logic/current sensing?
11. What creepage/clearance rules are being applied for 96 V?
12. Is there overcurrent protection faster than MCU ADC monitoring?
13. Are fuse, precharge, contactor, key switch, brake, and motor temp included?
14. What is the target PWM frequency and current-loop frequency?
15. What is the low-voltage test motor before the high-voltage motor?

## Useful Images

Proposal figures:

![Proposal PWM/current ripple and function split](../assets/proposal_page5-5.png)

DRV8320 block diagram:

![DRV8320H block diagram](../assets/drv8320_page23-23.png)

SimpleFOC current-mode diagram from team notes:

![SimpleFOC current-mode FOC diagram](../assets/source_docs/a_f__simplefoc_notes_media_12.png)

TI high-voltage inverter diagram from team notes:

![TI high-voltage inverter block diagram](../assets/source_docs/a_f__TI_doc_media_01.png)

Kelly controller wiring reference from team notes:

![Kelly KLS-N wiring reference](../assets/source_docs/a_f__to_look_into_media_03.png)

DE10-Nano SoC FPGA board:

![DE10-Nano block diagram](../assets/de10_nano_blockdiagram.jpg)

## Near-Term To-Do

For the FPGA side:

- Learn HDL Coder workflow.
- Build a floating-point FOC model.
- Build current-ripple simulations for PWM frequency sweep.
- Learn fixed-point conversion workflow.
- Decide what signals must enter/leave the FPGA.
- Make a proposed FPGA register map.
- Write a short memo on safety split: fast FPGA/hardware protection vs MCU supervisory policy.
- Bring PCB questions to the schematic team before pinout gets locked.

## Source Links

- TI DRV8320 datasheet: https://www.ti.com/lit/ds/symlink/drv8320.pdf
- SimpleFOC DriveShield: https://github.com/simplefoc/SimpleFOC-DriveShield
- SimpleFOC 3PWM docs: https://docs.simplefoc.com/bldcdriver3pwm
- SimpleFOC 6PWM docs: https://docs.simplefoc.com/bldcdriver6pwm
- SimpleFOC STM32 docs: https://docs.simplefoc.com/stm32_mcu
- MathWorks HDL Coder: https://www.mathworks.com/help/hdlcoder/
- MathWorks FOC examples: https://www.mathworks.com/help/mcb/
- STM32N6570-DK: https://www.st.com/en/evaluation-tools/stm32n6570-dk.html
- Terasic DE10-Nano: https://www.terasic.com.tw/cgi-bin/page/archive.pl?CategoryNo=167&Language=English&No=1046
