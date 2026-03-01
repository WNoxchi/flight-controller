# Spec: UARTs and Receiver Interface

## Overview
5 usable hardware UARTs. USART6 conflicts with motor pins (not usable).

## UART Allocation
| UART   | Function         | TX Pin | RX Pin | Connector       |
|--------|------------------|--------|--------|-----------------|
| USART1 | Serial RX (Receiver) | PA9  | PA10   | RX connector    |
| USART2 | GPS              | PA2    | PA3    | GPS connector   |
| USART3 | Spare/MSP        | PB10   | PB11   | Spare connector |
| UART4  | ESC Telemetry    | PA0    | PA1    | ESC connector   |
| UART5  | SmartAudio VTX   | PC12   | PD2    | Solder pad      |

## SBUS Hardware Inverter (F405-Specific)
STM32F405 lacks hardware UART inversion. SBUS requires external N-FET inverter.
- N-channel MOSFET: 2N7002 (SOT-23)
- SBUS RX → 1kΩ → gate, 10kΩ pullup on drain to 3.3V, drain → UART1_RX (PA10)
- Source → GND
- Separate SBUS solder pad routes through inverter; main RX pad bypasses it
- Default: non-inverted (CRSF/ELRS). Solder bridge to select SBUS vs direct.

## Connectors
- RX connector: 4-pin JST-SH 1.0 (GND, 5V, RX1, TX1)
- GPS connector: 6-pin JST-SH 1.0 (GND, 5V, TX2, RX2, SCL, SDA)
- Spare connector: 6-pin JST-SH 1.0 (GND, 5V, TX3, RX3, 5V, GND)
