Custom Dual-Drive FPGA Motor Controller Architecture
    This repository contains the hardware design files, gateware (Verilog), and software firmware for a custom, isolated dual-drive motor controller system. Designed specifically for high-efficiency electric vehicles (such as solar racing cars), this architecture implements a hardware-accelerated Field Oriented Control (FOC) pipeline on an FPGA, managed by a robust microcontroller-driven Motor Interface Board running a passive differential configuration.

System Architecture Overview
    To isolate high-voltage switching noise from sensitive digital logic and provide physical modularity, the system is strictly split into three distinct hardware and control layers:

    [ Master Vehicle Inputs ] (Throttle, Brake, Switches, CAN)
            │
            ▼
    ┌────────────────────────────────────────────────────────┐
    │ Phase 3: Motor Interface Board (Microcontroller)       │
    │ - Galvanic Isolation Barrier (ISO7421 / ISO6740)       │
    │ - Dual DAC (MCP4922) for Independent L/R Throttle      │
    └──────────────────────────┬─────────────────────────────┘
                            │ (Isolated Signals)
                            ▼
    ┌────────────────────────────────────────────────────────┐
    │ Phase 2: Low-Voltage Logic Board (FPGA)                │
    │ - Core FOC Loop: Clarke/Park & Pipelined PI Loops      │
    │ - High-Speed ADC Decoding & CORDIC Sine/Cosine         │
    │ - Space Vector Modulation (SVM) & Dead-Time Insertion  │
    └──────────────────────────┬─────────────────────────────┘
                            │ (Synchronized PWM / Gate Drives)
                            ▼
    ===========================▼============================== [Isolation Barrier]
    ┌────────────────────────────────────────────────────────┐
    │ Phase 1: High-Voltage Power Board (Inverter)           │
    │ - 96V DC Bus (150V - 200V Rated MOSFETs, TOLL/DFN)     │
    │ - Galvanically Isolated Gate Drivers (UCC21520)        │
    │ - Phase Current Shunts & Isolated Amplifiers (AMC1301)  │
    └────────────────────────────────────────────────────────┘

Project Development Phases

Phase 1: High-Voltage Inverter PCB (Power Stage)
    This board handles the heavy-lifting muscle of the system, managing the 96V nominal battery pack.
    Specifications & Components:
        DC Bus Voltage: 96V Nominal (Peak 115V).
        Power Switching: 150V–200V N-Channel MOSFETs featuring ultra-low $R_{ds(\text{on})}$ in high-thermal efficiency TOLL (TO-Leadless) or DFN 8x8 packages.
        Gate Drivers: Dual-channel galvanically isolated gate drivers (TI UCC21520 or similar) to isolate the 96V domain from logic.
        Current Feedback: In-line or low-side current shunts paired with high-speed isolated amplifiers (AMC1301) feeding external ADCs.
        Thermal & Power Integrity: Thick copper weight (2oz or 3oz), massive low-ESR bulk decoupling capacitor bank, and dedicated creepage/clearance channels ($\ge 2\text{mm}$) to prevent electrical arcing.
Phase 2: Low-Voltage Logic PCB (FPGA Brain)
    The digital engine executing deterministic, nanosecond-latency motor math.
    Hardware Design:
        Dedicated FPGA development SoC or standalone chip (e.g., Cyclone IV/V or Spartan-7).
        High-speed connector interface matching the Power Board control lines.
        Onboard ultra-low jitter clock source for highly precise PWM generation.
    Gateware Architecture (Verilog):
        ADC Ingestion Module: High-speed SPI Master / Delta-Sigma decoder to capture phase current simultaneously at the center of the PWM cycle.
        Coordinate Transformation (Fixed-Point Math): Clarke and Park transformations implemented via a pipelined CORDIC engine to handle trigonometric calculations without lookup tables.
        Pipelined PI Controllers: Dual, parallel hardware PI loops regulating $I_d$ (flux) and $I_q$ (torque).
        Space Vector Modulation (SVM): Maximizes DC bus utilization by up to 15.5% compared to standard sine-PWM.
        PWM & Dead-Time Generation: Center-aligned triangle counter with a hardware shift-register delay block to strictly enforce dead-time and eliminate shoot-through risk.
Phase 3: Motor Interface & Microcontroller Firmware
    The supervisory control layer that interfaces with the driver controls and distributes commands.
    Hardware Isolation Design:
        Built around an nRF52840 or equivalent microcontroller for system management and wireless telemetry.
        Digital isolators (ISO7421 / ISO6740) cleanly split the MCU domain from the noisy motor controller grounds.
        A dual-channel MCP4922 12-bit DAC generates independent analog 0–5V output curves (THROTTLE_L and THROTTLE_R).
        CMOS Level Shifters (CD40109B) step up logic control switches to 12V_MC or 5V_MC levels.
    Firmware Execution Loop:
        Ingests physical vehicle inputs: Foot switches, brake pedals, direction toggles, and CAN bus commands.
        Executes a Passive Differential Strategy: Distributes matching, software-profiled throttle voltages across the isolated SPI bus to both controllers, letting the independent hub motors differentiate naturally based on turn physics.Monitors safety boundaries and asserts global hardware shut-offs if a fault is triggered.
        
Repository Structure
├── hardware/
│   ├── phase1-hv-inverter/      # Altium/KiCad PCB layouts & schematics (96V Power Stage)
│   ├── phase2-lv-fpga/          # Altium/KiCad PCB layouts for FPGA logic board
│   └── phase3-interface-board/  # PCB layouts for isolated Motor Interface Board
├── gateware/
│   ├── rtl/                     # Verilog source files (FOC Core, CORDIC, SVM, PWM)
│   ├── bench/                   # Testbenches for ModelSim/GHDL verification
│   └── fpga_project.qsf         # FPGA Toolchain configuration files
└── firmware/
│   ├── src/                     # Microcontroller C/C++ source code (nRF52840)
│   ├── lib/                     # Peripheral drivers (DAC, SPI, CAN)
│   └── platformio.ini           # Firmware build configurations

Bring-up & Testing Safety Protocol
Because this project interfaces with a high-energy 96V battery pack, follow this step-by-step validation sequence to minimize equipment damage:
    RTL Simulation: Verify all fixed-point math and state machines in standard RTL simulation (ModelSim) to check for integer overflows or timing race conditions.
    Logic-Level Validation: Power the FPGA and Interface Board on a bench without high-voltage hooked up. Use an oscilloscope to verify that the PWM outputs inject the correct dead-time duration.
    Low-Voltage Bench Spinning: Connect a low-voltage, current-limited bench power supply (e.g., 12V–24V) to the Power Stage. Validate that the FPGA can smoothly spin the motor in open-loop voltage mode.
    Closed-Loop Calibration: Enable the ADC modules and current PI loops under small mechanical loads, optimizing the torque response.
    High-Voltage Integration: Gradually scale the DC bus power up to the 96V pack, utilizing inline fuses and an external emergency stop circuit.