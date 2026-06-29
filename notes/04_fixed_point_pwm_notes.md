# Fixed-Point, PWM, and FPGA Implementation Notes

## Floating Point

Pros:

- Easier to write.
- Easier to debug.
- Good for reference model.
- Handles wide dynamic range.

Cons:

- Higher FPGA resource use.
- More latency.
- More complex timing closure.
- Less aligned with low-cost efficient FPGA implementation.

## Fixed Point

Pros:

- Efficient in FPGA fabric.
- Lower latency and area.
- Good for deterministic motor-control datapaths.

Cons:

- Requires range analysis.
- Requires scaling decisions.
- Overflow can silently break control quality, which is extremely rude.
- Needs saturation and anti-windup.

## Suggested Fixed-Point Starting Points

| Signal | Type idea |
|---|---|
| ADC current input | signed 16-18 bit |
| normalized current | signed Q1.15 or Q2.16 |
| normalized voltage | signed Q1.15 or Q2.16 |
| sin/cos | signed Q1.15 |
| transform intermediate | 24-32 bit |
| PI integrator | signed 32 bit |
| PWM duty | unsigned 12-16 bit |
| angle | unsigned 16-18 bit circular |

## PWM Resolution

Formula:

```text
PWM counts = FPGA clock / PWM frequency
resolution_bits = log2(PWM counts)
```

Examples with 100 MHz FPGA clock:

| PWM frequency | Counts | Approx resolution |
|---|---:|---:|
| 20 kHz | 5000 | 12.3 bits |
| 50 kHz | 2000 | 11.0 bits |
| 100 kHz | 1000 | 10.0 bits |

Higher PWM frequency reduces current ripple but increases switching losses. So the move is not "max PWM frequency because FPGA go brrr." The move is finding the best efficiency tradeoff.

## PWM Block Requirements

- Center-aligned PWM option.
- Synchronous duty update at period boundary.
- Minimum and maximum duty clamp.
- Deadtime insertion for 6PWM.
- Fault override.
- Enable gating.
- Safe reset state.
- Status/debug counters.

## SVPWM vs Sine PWM

Sine PWM:

- Easier to understand.
- Good first simulation.
- Lower DC-bus utilization.

SVPWM:

- More common in high-performance FOC.
- Better DC-bus utilization.
- Slightly more complex.

Recommendation:

- Start with sine PWM in the first model.
- Move to SVPWM once the loop works.

## Implementation Risks

- PI integrator overflow.
- Missing anti-windup.
- Bad angle scaling.
- Wrong phase/current sensor polarity.
- Current sensor latency.
- PWM update at wrong time.
- Deadtime too short or too long.
- Forgetting fault latch/re-arm behavior.
