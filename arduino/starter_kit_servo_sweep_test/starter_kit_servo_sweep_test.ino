/*
  Arduino Starter Kit servo sweep test

  Purpose:
  - verify the Uno can command a hobby servo
  - practice safe incremental actuator testing

  Assumed wiring:
  - servo signal -> Uno D9
  - servo power  -> 5 V
  - servo ground -> GND
*/

#include <Servo.h>

Servo testServo;

const int SERVO_PIN = 9;

void setup() {
  Serial.begin(115200);
  testServo.attach(SERVO_PIN);
  Serial.println("Starter Kit servo sweep test ready");
}

void loop() {
  for (int angle = 20; angle <= 160; angle += 5) {
    testServo.write(angle);
    Serial.print("angle=");
    Serial.println(angle);
    delay(100);
  }

  for (int angle = 160; angle >= 20; angle -= 5) {
    testServo.write(angle);
    Serial.print("angle=");
    Serial.println(angle);
    delay(100);
  }
}
