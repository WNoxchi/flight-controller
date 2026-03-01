# Spec: Blackbox Flash — W25Q128JVSIQ on SPI3

## Overview
128Mbit SPI NOR flash for blackbox flight data logging.

## Connections
- SPI3_SCK: PC10, SPI3_MISO: PC11, SPI3_MOSI: PB5
- Chip Select: PB7 (FLASH_CS)

## Circuit
- VCC: 3.3V with 100nF decoupling (close to chip)
- /WP and /HOLD pins tied to VCC through 10kΩ pullups (or direct to VCC)
- Standard SPI mode, up to 133MHz clock (run at MCU SPI3 speed)

## Assert Constraints
```
# W25Q128 supply voltage (datasheet: 2.7–3.6V)
assert vcc within 2.7V to 3.6V

# Decoupling cap
assert c_vcc.value within 80nF to 120nF
```
