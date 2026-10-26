# Current boundaries and next verification work

Source review: 26 October 2026. These items describe the current design; documentation changes do not repair the RTL.

| Area | Current behavior | Next check or integration task |
| --- | --- | --- |
| Transaction alignment | The top delays handoff valid signals while holding the latest sine/cosine values | Capture and delay matching current, angle and valid data; test distinct adjacent samples and gaps |
| Most-negative current | The magnitude monitor calculates abs in signed WIDTH bits | Widen before negation and test `-32768` with positive thresholds |
| Disable during PI processing | Multiple independent clocked branches can have pending pipeline work | Test enable dropping at every stage and define flush/restart priority |
| Sensor freshness | Readiness remembers the first sample and stays set | Add a specified stale-sample watchdog and recovery test |
| Gain updates | PI gains are read at multiplication, after error acceptance | Hold them stable or capture/commit a matching parameter bank |
| Voltage limiting | d/q PI outputs clamp independently | Define a bus-dependent vector magnitude limit and compatible anti-windup behavior |
| Angle | External electrical-angle input; Hall decoder is standalone | Calibrate phase order, direction, electrical offset and any interpolation |
| ADC | Raw sample inputs with offsets and scale | Implement acquisition, align samples to switching, and calibrate the complete analog path |
| Voltage protection | Top accepts an external `voltage_out_of_range` flag | Connect and calibrate voltage acquisition and range checking |
| PWM | Sine PWM style phase reconstruction; registered output comparisons | Validate full cycles, extreme duties, configuration changes and driver-level waveforms |
| Restart | Present faults and a retained latch inhibit run | Specify software acknowledgement, reset behavior and pending-output handling |
| Board | Historical wrapper timing and later Cora integration are distinct | Verify the actual part, pin map, voltage standards, clocking and full external timing |

Two important interpretation limits:

1. Passing the directed regression establishes the checks in those tests. It does not establish motor-loop stability, calibrated current limits, formal completeness or arbitrary streaming correctness.
2. FPGA computation rate and PWM frequency are different. Higher switching frequency can reduce current ripple but also increases switching losses. The project has not established a measured efficiency or cost advantage over another controller.

The [learning guide](https://spenchh.github.io/fpga-motor-control-lab/#/decisions) explains these tradeoffs, and the [study checkpoints](https://spenchh.github.io/fpga-motor-control-lab/#/study) turn them into reasoning questions.
