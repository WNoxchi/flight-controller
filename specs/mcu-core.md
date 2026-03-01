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

## Pin Budget
39 of 51 available GPIO pins allocated. ~12 spare.
