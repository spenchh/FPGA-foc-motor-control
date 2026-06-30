# MATLAB Starter Notes

This folder is for first-pass MATLAB simulations before moving into Simulink or HDL Coder.

## First Script

Run:

```matlab
foc_fixed_point_starter
```

What it shows:

- Per-unit scaling.
- Q1.15 encode/decode behavior.
- Fixed-point multiply and saturation.
- Floating-point PI versus fixed-point PI.
- Basic first-order current-loop response.
- Clarke/Park transform sanity check.
- PWM-center sample strobe timing.

## Suggested Order

1. Run the script unchanged.
2. Change `kp_pu`, `ki_pu`, `base_current_A`, and `f_pwm_Hz`.
3. Compare floating-point and fixed-point plots.
4. Increase/decrease `Q_FRAC` and observe quantization error.
5. Move the PI block into a Simulink subsystem.
6. Convert the PI subsystem to fixed point with HDL Coder later.

## Notes

The script intentionally uses plain MATLAB integer math instead of Fixed-Point Designer objects. That makes the scaling visible and closer to what the FPGA RTL will eventually do.
