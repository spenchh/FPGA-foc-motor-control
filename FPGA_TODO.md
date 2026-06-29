# FPGA TODO List

## 1. Learn Arty Z7 / Zynq Basics
- Understand ARM processing system versus FPGA fabric.
- Learn Vivado project setup.
- Install Digilent board files.

## 2. Build First Vivado Test Project
- Blink an LED from FPGA fabric.
- Confirm constraints/XDC workflow.
- Learn how Arduino-header pins map to FPGA pins.

## 3. Make a Basic 3PWM Generator
- Programmable frequency.
- Programmable duty cycle.
- Enable input.
- Safe reset state where PWM outputs are off.

## 4. Compare 3PWM vs 6PWM
- 3PWM only works if the gate driver handles complementary outputs and deadtime.
- 6PWM is needed if the driver exposes separate high-side and low-side inputs.
- 6PWM lets FPGA control deadtime directly.

## 5. Research Current Sensing Into FPGA
- Check Arty Z7 XADC limits and sample rate.
- Decide XADC versus external ADC versus ARM ADC.
- Figure out whether current sampling can sync to PWM center.

## 6. Build Hall Sensor Input Logic
- Read Hall A/B/C.
- Decode rotor sector.
- Track transitions and estimate speed.

## 7. Learn AXI / Shared Register Interface
- ARM writes duty/Iq command, enable, and mode.
- FPGA reports fault flags, Hall state, current data, and telemetry.

## 8. Start Fixed-Point FOC Research
- Q-format numbers.
- PI controller.
- Clarke/Park transforms.
- Inverse Park.
- SVPWM.

## 9. Safety / Fault Behavior
- FPGA should disable PWM on fault if assigned.
- Gate-driver/chip protection should be the first layer.
- ARM handles logging, recovery, and re-enable.
- PWM and ENABLE should default off during FPGA reset/programming.

## 10. Hardware Info Still Needed From PCB Side
- Final gate-driver choice.
- Exact Arduino-header pin map.
- Whether the driver is 3PWM or 6PWM.
- Current-sensor voltage range.
- Fault signals routed to FPGA.
- Expected PWM frequency.
