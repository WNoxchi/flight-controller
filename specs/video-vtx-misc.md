# Spec: Analog Video Path and VTX Interface

## Video Path
Camera composite video → AT7456E VIN (pin 17) → OSD overlay → VOUT (pin 22) → VTX.
Video does NOT pass through MCU.

## Camera Connector (5-pin JST-SH 1.0)
| Pin | Signal | Notes           |
|-----|--------|-----------------|
| 1   | GND    |                 |
| 2   | 5V     | Camera power    |
| 3   | VI     | Video in from camera |
| 4   | CC     | Camera control (PB3, Betaflight OSD joystick) |
| 5   | GND    | Extra ground    |

## VTX Connector (5-pin JST-SH 1.0)
| Pin | Signal  | Notes                              |
|-----|---------|------------------------------------|
| 1   | 10V     | Regulated 10V BEC, switchable via PINIO1 |
| 2   | GND     |                                    |
| 3   | VIDEO   | Composite video out (from OSD out) |
| 4   | RX      | UART5_RX (PD2) — VTX control RX   |
| 5   | TX      | UART5_TX (PC12) — SmartAudio / VTX control TX |

## Misc GPIO
- LED0: PB0 (status LED, active low)
- BEEPER: PB1 (inverted, drives N-FET to buzzer)
- LED_STRIP: PB6 (WS2812 data, TIM4_CH1)
- CAMERA_CONTROL: PB3 (Betaflight camera OSD joystick)
- PINIO1: PB2 (switchable 10V VTX rail, see power spec)
- PA4: general-purpose signal output for communicating with peripherals (GPIO/DAC)

## Assert Constraints
```
# LED current limiting resistor (3.3V supply, ~1.5mA target)
assert r_led.value within 900ohm to 1.1kohm

# LED strip data line series resistor
assert r_led_strip.value within 300ohm to 360ohm
```
