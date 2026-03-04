# Spec: Power Architecture

## Overview
2-6S LiPo input (7.4-25.2V) with buck to 5V, LDO to 3.3V, USB power OR.

## 5V Buck Regulator (TI LMR43620MB5RPER — fixed 5V)
- Input: 4.5-36V, Output: 5V fixed, Max 2A, synchronous, internally compensated, VQFN-HR 2x2mm (9-pad)
- Fixed output — no feedback divider needed (FB pin connected internally)
- External components: 4.7µF/50V input cap (0805), 100nF VIN HF bypass cap (0402), 1µF VCC bypass cap (0402), 100nF bootstrap cap (0402), 2.2µH/2A shielded inductor (Würth MAPI-4020, 74438356022, 4mm), 2x 22µF output caps
- No external Schottky catch diode (synchronous — internal low-side FET)
- No external compensation network (internally compensated)
- MODE/SYNC pin: tied to VIN for forced-PWM mode
- EN/UVLO divider: 430kΩ / 100kΩ — UVLO threshold ~6.47V rising, ~5.5V falling (3.4µA hysteresis current)
- PGOOD: 100kΩ pullup to output rail (open-drain, indicates output in regulation)
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

## 5V VTX BEC (TI LMR43620MB5RPER — fixed 5V)
- Input: VBAT (4.5-36V), Output: 5V fixed/2A, synchronous, internally compensated, VQFN-HR 2x2mm (9-pad)
- Fixed output — no feedback divider needed (FB pin connected internally)
- MODE/SYNC pin: tied to VIN for forced-PWM mode
- EN/UVLO divider: 430kΩ / 100kΩ — UVLO threshold ~6.47V rising, ~5.5V falling (3.4µA hysteresis current)
- PGOOD: 100kΩ pullup to output rail (open-drain, indicates output in regulation)
- PINIO1 P-FET switches output to VTX connector
- Dedicated power for analog VTX — matches Brave F7 dual-5V topology
- External components: 4.7µF/50V input cap (0805), 100nF VIN HF bypass cap (0402), 1µF VCC bypass cap (0402), 100nF bootstrap cap (0402), 2.2µH/2A shielded inductor (Würth MAPI-4020, 74438356022, 4mm), 2x 22µF output caps
- No external Schottky catch diode (synchronous — internal low-side FET)
- No external compensation network (internally compensated)

## PINIO1 Switchable 5V VTX (N-FET + P-FET level-shifted)
- N-FET (2N7002): gate driven by PB2 via 10kΩ, source to GND
- P-FET (AO3401A): source=5V VTX rail, drain=VTX connector, gate driven by N-FET drain
- 100kΩ pullup from P-FET gate to 5V VTX rail (default OFF)
- PB2 HIGH → N-FET ON → P-FET gate low → VTX powered
- PB2 LOW (default, BOOT1 pulldown) → N-FET OFF → P-FET gate high → VTX off
- Provides VTX pit mode control

## Decoupling Strategy
- Each VDD pin: 100nF ceramic (close to pin)
- VDDA: 1µF + 100nF
- VCAP1/VCAP2: 2.2µF ceramic each
- Per-chip 100nF on BMI270, BMP390, AT7456E, W25Q128
- AT7456E AVDD: 100nF + ferrite bead (isolated analog supply)
- 5V bulk: 2x 22µF MLCC output caps on 5V buck (no separate bulk cap needed)
- 3.3V bulk: 22µF tantalum near LDO

## Assert Constraints
These should be validated in atopile with `assert` statements:
```
# 5V buck output
assert rail_5v within 4.75V to 5.25V

# 3.3V LDO output
assert rail_3v3 within 3.2V to 3.4V

# Battery voltage divider (10:1 ratio)
assert r_vbat_top.value within 9.9kohm to 10.1kohm
assert r_vbat_bot.value within 990ohm to 1.01kohm
# ADC pin voltage at max 6S input (25.2V) must not exceed 3.3V
assert v_adc_vbat within 0V to 3.3V

# Current sense filter
assert r_curr_filter.value within 900ohm to 1.1kohm
assert c_curr_filter.value within 80nF to 120nF

# PINIO1 gate resistor
assert r_pinio_gate.value within 9.9kohm to 10.1kohm
```
