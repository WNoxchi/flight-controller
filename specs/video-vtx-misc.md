# Spec: Analog Video Path and VTX Interface

## Video Path
Camera composite video → AT7456E VIN (pin 17) → OSD overlay → VOUT (pin 22) → VTX.
Video does NOT pass through MCU.

## Camera Connector (3-pin JST-SH 1.0)
| Pin | Signal | Notes           |
|-----|--------|-----------------|
| 1   | GND    |                 |
| 2   | 5V     | Camera power    |
| 3   | VOUT   | Video out (post-OSD) |

## VTX Connector (4-pin JST-SH 1.0)
| Pin | Signal  | Notes                              |
|-----|---------|------------------------------------|
| 1   | GND     |                                    |
| 2   | VBAT_SW | Switchable VBAT via PINIO1         |
| 3   | VIDEO   | Composite video in (from OSD out)  |
| 4   | SA      | SmartAudio control (UART5_TX, PC12)|

## Misc GPIO
- LED0: PB0 (status LED, active low)
- BEEPER: PB1 (inverted, drives N-FET to buzzer)
- LED_STRIP: PB6 (WS2812 data, TIM4_CH1)
- CAMERA_CONTROL: PB3 (Betaflight camera OSD joystick)
- PINIO1: PB2 (switchable VBAT, see power spec)
- PA4: servo/detonator solder pad (DAC capable, TIM2 or GPIO)
