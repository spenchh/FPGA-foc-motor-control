/*
  SimpleFOC 3PWM BLDC reference sketch

  This is for a compatible BLDC driver board with 3PWM inputs
  It is not for the Starter Kit DC motor + L293D setup

  Before running:
  - confirm BLDC driver board supports 3PWM
  - confirm PWM pins
  - confirm enable/sleep pin
  - confirm motor pole pairs
  - use low voltage and current limit
*/

#include <SimpleFOC.h>

// TODO: replace 7 with the actual BLDC motor pole-pair count
BLDCMotor motor = BLDCMotor(7);

// Arduino Uno example pins based on common SimpleFOC examples
// phase A PWM, phase B PWM, phase C PWM, enable
BLDCDriver3PWM driver = BLDCDriver3PWM(9, 5, 6, 8);

void setup() {
  Serial.begin(115200);
  SimpleFOCDebug::enable(&Serial);

  driver.voltage_power_supply = 12;
  driver.voltage_limit = 2;
  driver.pwm_frequency = 20000;

  driver.init();
  driver.enable();

  motor.linkDriver(&driver);

  motor.controller = MotionControlType::velocity_openloop;
  motor.voltage_limit = 2;
  motor.velocity_limit = 5;

  motor.init();

  Serial.println("SimpleFOC 3PWM open-loop reference ready");
}

void loop() {
  motor.move(1.0);
}
