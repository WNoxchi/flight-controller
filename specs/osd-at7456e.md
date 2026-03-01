# Spec: OSD — AT7456E on SPI2

## Overview
AT7456E analog video OSD chip on SPI2. Overlays text on composite video signal.

## Connections
- SPI2_SCK: PB13, SPI2_MISO: PB14, SPI2_MOSI: PB15
- Chip Select: PB12 (MAX7456_CS)

## Circuit
- DVDD: 3.3V with 100nF decoupling
- AVDD: 3.3V through ferrite bead with 100nF decoupling (isolated analog supply)
- VIN (pin 17): Camera composite video in (direct, not through MCU)
- VOUT (pin 22): Composited video out to VTX
- Video path does NOT pass through MCU — SPI is control only
