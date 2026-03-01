# Spec: USB-C Interface

## Overview
USB 2.0 Full-Speed device-only (UFP/sink) for DFU flashing and Betaflight configurator.

## Connections
- USB_DM: PA11, USB_DP: PA12
- STM32F405 has internal 1.5kΩ pull-up on D+ (no external needed)

## Circuit
- USB-C connector: 16-pin mid-mount SMD (GCT USB4085-GF-A or equiv)
- 2x 5.1kΩ resistors on CC1, CC2 to GND (UFP/sink identification)
- ESD protection: USBLC6-2SC6 (ST) dual-line TVS on D+/D-
- 22Ω series resistors on D+ and D- (impedance matching)
- Schottky diode (SS34) from VBUS to 5V rail (power OR with BEC)
- Shield to GND via 1MΩ ∥ 4.7nF

## NDAA
- USBLC6-2SC6: STMicroelectronics (Franco-Italian, clean)
- GCT connector: UK company (clean)
