# Arduino bring-up notes

This folder separates two different Arduino paths:

1. Arduino Starter Kit tests
2. SimpleFOC 3PWM BLDC reference work

The Arduino Starter Kit has an Uno R3, a small DC motor, a servo motor, an L293D H-bridge, and basic components

That kit is useful for practicing:

- PWM output
- enable pins
- motor direction control
- reading a potentiometer
- writing small bench-test sketches
- using Serial output for debugging

That kit does not directly test our final 3PWM BLDC motor-controller path because it does not include a BLDC motor driver/inverter

SimpleFOC 3PWM testing requires:

- BLDC motor
- 3-phase motor driver or inverter board
- three PWM inputs
- shared logic ground
- enable/sleep pin if the driver needs one
- low-voltage current-limited supply for first tests

## Files

- `starter_kit_dc_motor_pwm_test/starter_kit_dc_motor_pwm_test.ino`
  - tests PWM speed and direction with the Starter Kit DC motor and L293D

- `starter_kit_servo_sweep_test/starter_kit_servo_sweep_test.ino`
  - tests basic servo control from the Uno

- `simplefoc_3pwm_reference/simplefoc_3pwm_reference.ino`
  - reference shape for a SimpleFOC 3PWM BLDC open-loop test
  - this requires a compatible BLDC driver board and will not run correctly with only the Starter Kit DC motor

## Current SURG interpretation

Starter Kit work is a low-risk way to prove basic Arduino motor-control bring-up practice

SimpleFOC work is the more relevant path for a temporary BLDC bench setup

The custom SURG board still needs its own FPGA/PCB-specific mapping because it uses different gate drivers, current sensors, fault behavior, and possibly a different connector interface
