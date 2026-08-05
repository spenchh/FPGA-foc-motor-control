/*
  Arduino Starter Kit DC motor PWM test

  Purpose:
  - practice PWM speed control
  - practice direction control through the L293D H-bridge
  - use Serial output for simple debugging

  Assumed wiring:
  - Uno D9  -> L293D enable pin for motor channel
  - Uno D8  -> L293D input 1
  - Uno D7  -> L293D input 2
  - Uno A0  -> potentiometer center pin
  - shared GND between Uno and motor supply

  This is not a BLDC / SimpleFOC test
*/

const int PWM_PIN = 9;
const int IN1_PIN = 8;
const int IN2_PIN = 7;
const int POT_PIN = A0;

void setup() {
  pinMode(PWM_PIN, OUTPUT);
  pinMode(IN1_PIN, OUTPUT);
  pinMode(IN2_PIN, OUTPUT);
  pinMode(POT_PIN, INPUT);

  Serial.begin(115200);

  digitalWrite(IN1_PIN, LOW);
  digitalWrite(IN2_PIN, LOW);
  analogWrite(PWM_PIN, 0);

  Serial.println("Starter Kit DC motor PWM test ready");
}

void loop() {
  int potValue = analogRead(POT_PIN);
  int speedCommand = map(potValue, 0, 1023, -255, 255);
  int pwmValue = abs(speedCommand);

  if (speedCommand > 20) {
    digitalWrite(IN1_PIN, HIGH);
    digitalWrite(IN2_PIN, LOW);
  } else if (speedCommand < -20) {
    digitalWrite(IN1_PIN, LOW);
    digitalWrite(IN2_PIN, HIGH);
  } else {
    digitalWrite(IN1_PIN, LOW);
    digitalWrite(IN2_PIN, LOW);
    pwmValue = 0;
  }

  analogWrite(PWM_PIN, pwmValue);

  Serial.print("pot=");
  Serial.print(potValue);
  Serial.print(" speedCommand=");
  Serial.print(speedCommand);
  Serial.print(" pwm=");
  Serial.println(pwmValue);

  delay(100);
}
