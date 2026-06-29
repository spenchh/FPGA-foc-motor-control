# Research Log: FPGA/MCU Field-Oriented Control for Lightweight Motors

## 1. Metadata & Source Citations
- **Source Type:** Research proposal PDF; `6_21 Meeting notes.docx`; `6_22 Notes.docx`; `a.f. simplefoc notes.docx`; `a.f. TI doc.docx`; BOM spreadsheets; [TI DRV8320 datasheet](https://www.ti.com/lit/ds/symlink/drv8320.pdf); [SimpleFOC DriveShield](https://github.com/simplefoc/SimpleFOC-DriveShield); [MathWorks HDL Coder](https://www.mathworks.com/help/hdlcoder/); [MathWorks Motor Control Blockset](https://www.mathworks.com/help/mcb/).
- **Key Authors/Entities:** Spencer Kogoma; Angelina Feng; Spencer Kogoma; SimpleFOC; Texas Instruments; MathWorks; STMicroelectronics; Terasic; Kelly Controls; Prohelion.
- **Temporal Context:** Proposal accessed March 13, 2026; meeting notes dated June 21-22, 2026; SimpleFOC Drive schematic dated August 23, 2024; DRV8320 datasheet revised March 2022.

## 2. Core Thesis & Primary Findings
- **The Main Argument:** FPGA acceleration is only meaningful if current sensing, rotor position, current-loop FOC, and PWM timing remain inside the fast path. MCU-only sensing or MCU-generated current commands reduce the FPGA to a PWM helper.
- **Critical Insights:**
  * The June 22 notes define the strongest architecture: MCU handles throttle, CAN, logging, slow safety; FPGA reads current/position, runs current-loop FOC, generates SVPWM/PWM, inserts deadtime, and performs fast shutdown.
  * SimpleFOC/DRV8320 is valid for low-voltage bring-up only. DRV8320 supports 6-60 V `VM`; team notes target a 96 V inverter.
  * Safety must be layered. Gate-driver/hardware protection handles destructive faults; FPGA handles deterministic shutdown; MCU handles policy, logging, and re-arm.
  * Current sensing should route directly to the FPGA or FPGA-adjacent ADC. MCU ADC forwarding adds latency and jitter.
  * Fixed-point HDL is the likely final FPGA implementation. Floating point remains the correct reference-model workflow.

## 3. Granular Evidence & Data Breakdown
- **Quantitative Data:**
  * Proposal states EV motor losses exceed 10% of total energy consumption.
  * Proposal compares NUSolar Mitsuba M2096 motor mass at 11 kg against Tesla Model 3 motor unit mass at 80 kg.
  * Proposal cites Prohelion WaveSculptor22 cost above $6,000 per controller.
  * Proposal cites Kelly Mini KLS9620 cost near $200 per controller.
  * Team notes list QS260 scooter motor context: 5,000 W; 77 A at 72 V requires verification.
  * Team notes list Kelly Mini KLS9620M: 48-96 V nominal; 36-115 V max; 200 A and 100 A ratings require datasheet confirmation.
  * `6_22 Notes.docx` specifies a 96 V DC bus switching into U/V/W phases.
  * SimpleFOCShield notes list $35, 3 A, 35 V input.
  * SimpleFOCDrive notes list $50, 20 A, 30 V input.
  * Stage-1 BOM lists driver near $30, test motor near $14, STM32 Nucleo-F401RE near $25, S49E Hall sensor near $0.50.
  * DRV8320 recommended `VM` operating range is 6-60 V.
  * DRV8320 supports applied PWM input frequency up to 200 kHz, subject to thermal limits.
  * DRV8320 `DVDD` regulator can source up to 30 mA externally.
  * With 100 MHz FPGA clock: 20 kHz PWM gives 5,000 counts; 50 kHz gives 2,000 counts; 100 kHz gives 1,000 counts.
- **Qualitative Evidence:**
  * `6_22 Notes.docx` explicitly says "No more simple FOC."
  * `6_22 Notes.docx` assigns MCU: throttle/command intake, `Iq` target, logging, CAN, slow safety.
  * `6_22 Notes.docx` assigns FPGA: current sensors, rotor position, current-loop FOC, SVPWM/PWM, deadtime, fast shutdown.
  * `a.f. simplefoc notes.docx` identifies current-mode FOC as the relevant control mode.
  * SimpleFOC current-control diagram maps directly to FPGA blocks: Clarke, Park, `id/iq` PI, inverse transforms, driver output.
  * `a.f. TI doc.docx` notes MCU ADC monitoring is insufficient for fastest short-circuit and overcurrent detection.
  * TI TIDA-01418 diagram separates low-voltage 12 V side, isolation barrier, MCU, current monitoring, gate driver, and high-voltage inverter.
  * Kelly KLS-N wiring reference includes throttle, foot switch, brake, forward/reverse, Hall sensors, motor temperature, fuse, contactor, and key switch.
  * STM32N6570-DK is an MCU board, not FPGA hardware.
  * DE10-Nano is a true SoC FPGA board with Cyclone V FPGA fabric and dual-core ARM Cortex-A9.

## 4. Methodology & Theoretical Framework
- **Approach Used:** The proposal uses three phases: motor characterization, hardware/software development, and efficiency testing. Characterization targets stator resistance, `Ld`, `Lq`, and back-EMF constant. Testing compares mechanical power against battery power and monitors temperature.
- **Underlying Theories:** Field-oriented control; Clarke transform; Park transform; inverse Park/Clarke; space-vector PWM; sinusoidal PWM; fixed-point arithmetic; PI current control; per-unit normalization; low-inductance current ripple; hardware/software partitioning; layered functional safety.

## 5. Limitations, Gaps, & Contradictions
- **Identified Flaws:** The current notes lack a final FPGA board, ADC, current-sensor topology, rotor-position sensor, gate-driver family, and 96 V protection strategy. The proposal overstates FPGA benefit if sensing remains MCU-routed. SimpleFOC/DRV8320 cannot be scaled directly to 96 V. The QS260 and Kelly current ratings need primary datasheet verification.
- **Anomalies:** The proposal frames the FPGA mainly as PWM/FOC generation; later notes require full FPGA current-loop ownership. The team debated MCU safety versus FPGA safety, but the evidence supports layered safety. Linked IGBT exploration conflicts with DRV8320 MOSFET-gate-driver assumptions. Hall sensors provide coarse position sectors unless interpolation or better sensing is added. Higher PWM reduces ripple but raises switching loss and thermal stress.

## 6. Synthesis & Cross-References
- **Open Questions:** Is the next PCB low-voltage validation hardware or a 96 V inverter? What gate driver supports 96 V plus transients? Will control use 3PWM or 6PWM? Where is deadtime inserted? Does `nFAULT` route to both FPGA and MCU? What current sensors and ADC sample rate are required? Can ADC sampling synchronize to PWM center? What rotor-position signal reaches FPGA? Is CAN isolated? What creepage, clearance, fuse, contactor, precharge, and thermal rules apply? What MCU-FPGA interface carries `Iq_ref`, mode, fault flags, and telemetry?
- **Keywords/Tags:** FPGA FOC; MCU-FPGA partitioning; PMSM; BLDC; SVPWM; fixed-point HDL; MATLAB HDL Coder; Simulink; current-loop control; DRV8320; SimpleFOC; 96 V inverter; current sensing; deadtime; overcurrent protection; CAN isolation; low-inductance motor.
