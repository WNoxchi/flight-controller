# Spec: STM32F405RGT6 MCU Core

## Overview
The MCU is the central component. STM32F405RGT6 in LQFP-64 package, 168MHz Cortex-M4, 1MB Flash, 192KB RAM.

## Requirements
- 8MHz HSE crystal oscillator on PH0/PH1 (pins 12/13) with 20pF load caps
- VCAP1 and VCAP2 pins require 2.2µF ceramic caps each (internal regulator)
- 100nF decoupling on each VDD pin, placed as close as possible
- 1µF + 100nF on VDDA (analog supply, extra filtering)
- BOOT0 pin: 10kΩ pull-down to GND, tactile button to 3.3V for DFU mode
- Optional 100nF debounce cap in parallel with BOOT0 pull-down
- NRST pin: 10kΩ external pull-up to 3.3V, 100nF debounce cap, tactile button to GND
- PB2/BOOT1 hazard: 10kΩ pull-down on PB2 mandatory (prevents SRAM boot)
- SWD debug: PA13 (SWDIO), PA14 (SWCLK) broken out to test pads with GND and 3.3V
- No LSE crystal (PC14/PC15 freed as spare GPIO)
- HSE crystal: 3.2x2.5mm SMD, e.g. ABM8-8.000MHZ-B2-T, ±20ppm
- Layout: crystal traces < 10mm, ground pour under crystal, no vias under footprint

## Interfaces Exposed
- 3x SPI buses (SPI1, SPI2, SPI3)
- 1x I2C bus (I2C1)
- 5x usable UARTs (USART1-3, UART4-5; USART6 conflicts with motors)
- 3x ADC channels on ADC3
- 4x motor timer outputs on TIM8 (PC6-PC9)
- USB 2.0 FS on PA11/PA12
- Misc GPIO: PB0 (LED), PB1 (beeper), PB3 (camera control), PB6 (LED strip)
- PB2 (PINIO1 via P-FET)
- PA4 (servo/detonator solder pad, DAC capable)

## Assert Constraints
These should be validated in atopile with `assert` statements:
```
# HSE crystal load caps
assert c_hse1.value within 15pF to 22pF
assert c_hse2.value within 15pF to 22pF

# VCAP internal regulator caps (required by datasheet)
assert c_vcap1.value within 2.0uF to 2.4uF
assert c_vcap2.value within 2.0uF to 2.4uF

# Per-VDD decoupling
assert c_vdd.value within 80nF to 120nF

# VDDA filtering
assert c_vdda_bulk.value within 0.9uF to 1.1uF
assert c_vdda_bypass.value within 80nF to 120nF

# BOOT0 pull-down (ensures boot from flash by default)
assert r_boot0.value within 9.9kohm to 10.1kohm

# NRST pull-up and debounce
assert r_nrst.value within 9.9kohm to 10.1kohm
assert c_nrst.value within 80nF to 120nF

# PB2/BOOT1 pull-down (mandatory — prevents SRAM boot trap)
assert r_boot1.value within 9.9kohm to 10.1kohm
```

## Pin Budget
39 of 51 available GPIO pins allocated. ~12 spare.
