# Spec: Power Architecture

## Overview
2-6S LiPo input (7.4-25.2V) with buck to 5V, LDO to 3.3V, USB power OR.

## 5V Buck Regulator (MP1584EN)
- Input: 4.5-28V, Output: 5V, Max 3A, 1.5MHz switching, SOIC-8
- External components: 22µF/50V input cap, 22µF/16V output cap, 4.7µH/3A shielded inductor, 100nF bootstrap cap, feedback resistor divider
- Feeds: GPS, receiver, camera, LED strip, buzzer, USB VBUS out, 3.3V LDO input

## 3.3V LDO (AMS1117-3.3)
- Input: 5V, Output: 3.3V, SOT-223
- Peak current ~193mA (well under 1A rating)
- External: 10µF input cap, 22µF tantalum output cap (stability)
- Power dissipation: (5.0-3.3V) × 0.2A = 0.34W — trivial for SOT-223
- Feeds: STM32F405, BMI270, BMP390, AT7456E, W25Q128, I2C/SPI pullups

## VBAT Input Protection
- TVS diode: SMBJ26A, clamp ~29V
- 100µF/50V electrolytic bulk cap near battery pads

## Battery Voltage Sensing
- Resistor divider: 10kΩ top / 1kΩ bottom (10:1 ratio)
- 25.2V → 2.29V at ADC pin (safe for 3.3V ADC)
- 100nF filter cap across bottom resistor
- Connected to PC2 (ADC_VBAT)

## Current Sensing
- From ESC current sensor analog output
- RC filter: 1kΩ + 100nF
- Connected to PC1 (ADC_CURR)

## RSSI Analog Input
- Optional, from receiver
- Connected to PC0 (ADC_RSSI)

## USB-C Power OR
- Schottky diode (SS34) from USB VBUS to 5V rail
- Prevents backfeed from BEC into USB host
- 4.7µF ceramic on VBUS after Schottky
- FC runs on USB power alone for configuration

## PINIO1 Switchable VBAT
- PB2 drives AO3401A P-FET (SOT-23, Vds=-30V, Id=-4A)
- 10kΩ gate resistor
- Source: VBAT, Drain: VTX connector VBAT_SW
- Provides VTX pit mode control

## Decoupling Strategy
- Each VDD pin: 100nF ceramic (close to pin)
- VDDA: 1µF + 100nF
- VCAP1/VCAP2: 2.2µF ceramic each
- Per-chip 100nF on BMI270, BMP390, AT7456E, W25Q128
- AT7456E AVDD: 100nF + ferrite bead (isolated analog supply)
- 5V bulk: 100µF electrolytic near BEC
- 3.3V bulk: 22µF tantalum near LDO
