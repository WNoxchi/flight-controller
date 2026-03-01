# Spec: Motors and ESC Interface

## Overview
4 motor outputs on TIM8 channels 1-4 using PWM DShot (not bitbanged, due to DMA2 errata).

## Motor Pin Mapping
| Motor  | Pin | Timer    | AF  | DMA Stream   |
|--------|-----|----------|-----|--------------|
| MOTOR1 | PC6 | TIM8_CH1 | AF3 | DMA2_St2_Ch7 |
| MOTOR2 | PC7 | TIM8_CH2 | AF3 | DMA2_St3_Ch7 |
| MOTOR3 | PC8 | TIM8_CH3 | AF3 | DMA2_St4_Ch7 |
| MOTOR4 | PC9 | TIM8_CH4 | AF3 | DMA2_St7_Ch7 |

## ESC Connector (8-pin JST-SH 1.0)
| Pin | Signal | Notes                      |
|-----|--------|----------------------------|
| 1   | GND    |                            |
| 2   | VBAT   | Battery voltage passthrough |
| 3   | CURR   | Current sensor analog (PC1) |
| 4   | M1     | Motor 1 (PC6)              |
| 5   | M2     | Motor 2 (PC7)              |
| 6   | M3     | Motor 3 (PC8)              |
| 7   | M4     | Motor 4 (PC9)              |
| 8   | TELEM  | ESC telemetry (UART4_RX, PA1) |
