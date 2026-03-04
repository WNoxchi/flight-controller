# TF405 Weight Budget

**Target**: ≤ 8.0 g assembled (reference: Brave F7 = 8 g)
**Last Updated**: 2026-03-03 (REV-009)

## 1. Bare PCB

| Parameter         | Value                                 |
|-------------------|---------------------------------------|
| Dimensions        | 37.0 mm x 37.0 mm                    |
| Layer count       | 4 (per pcb-stackup.md)               |
| Thickness         | 1.6 mm                                |
| Material          | FR4 (density ~1.85 g/cm³)            |
| Copper weight     | 1 oz outer / 0.5 oz inner            |
| Mounting holes    | 4x 3.2 mm (removes ~32 mm² material) |
| Corner radii      | 1.0 mm (removes ~0.9 mm² per corner) |
| Board area        | 37 x 37 = 1,369 mm² (≈13.69 cm²)    |
| Effective area    | ~1,333 mm² (after holes + corners)    |
| Board volume      | 13.33 cm² x 0.16 cm = 2.13 cm³       |
| **Bare PCB mass** | **~3.9 g**                            |

*Note: FR4 with copper layers weighs slightly more than pure FR4. The 3.7 g estimate accounts
for 4-layer copper (avg ~35 µm equivalent) and solder mask/silkscreen. JLCPCB 4-layer
boards of this size typically weigh 3.5–4.0 g.*

---

## 2. Component BOM with Masses

Component designators and LCSC part numbers are from actual `ato build` output. Masses are
from datasheet specifications where available, or engineering estimates based on package
dimensions. The atopile solver auto-selects LCSC parts — actual packages may differ from
what the schematic spec implies (e.g., 100 µF "electrolytic" resolved to 3528 tantalum).

### 2.1 Integrated Circuits (ICs)

| Designator | Component | Package | Qty | Unit (g) | Total (g) | Module |
|------------|-----------|---------|-----|----------|-----------|--------|
| U3 | STM32F405RGT6 | LQFP-64 10x10mm | 1 | 0.350 | 0.350 | mcu |
| U1 | LMR43620 (10V VTX BEC) | VQFN-HR 2.1x2.1mm | 1 | 0.015 | 0.015 | power |
| U6 | LMR43620 (5V BEC) | VQFN-HR 2.1x2.1mm | 1 | 0.015 | 0.015 | power |
| U2 | AMS1117-3.3 | SOT-223-3 | 1 | 0.120 | 0.120 | power |
| U4 | BMI270 | LGA-14 3x2.5mm | 1 | 0.025 | 0.025 | imu |
| U7 | BMP390 | LGA-10 2x2mm | 1 | 0.015 | 0.015 | baro |
| U10 | W25Q128JVSIQ | SOIC-8 5.23x5.23mm | 1 | 0.075 | 0.075 | flash |
| U5 | AT7456E | TSSOP-28-EP 4.4x9.7mm | 1 | 0.150 | 0.150 | osd |
| U8 | USBLC6-2SC6 | SOT-23-6 | 1 | 0.016 | 0.016 | usb |
| | **IC Subtotal** | | **9** | | **0.781** | |

### 2.2 Discrete Semiconductors

| Designator | Component | Package | Qty | Unit (g) | Total (g) | Module |
|------------|-----------|---------|-----|----------|-----------|--------|
| D1 | SMBJ26A (TVS) | SMB | 1 | 0.093 | 0.093 | power |
| D3 | SS34 (USB power OR) | SMA | 1 | 0.045 | 0.045 | power |
| D4 | LED 19-217/GHC-YR1S2/3T | 0603 | 1 | 0.002 | 0.002 | misc |
| Q1 | AO3401A (PINIO1 P-FET) | SOT-23 | 1 | 0.008 | 0.008 | power |
| Q2 | 2N7002 (beeper driver) | SOT-23 | 1 | 0.008 | 0.008 | misc |
| Q3 | 2N7002 (SBUS inverter) | SOT-23 | 1 | 0.008 | 0.008 | misc |
| | **Discrete Subtotal** | | **6** | | **0.164** | |

### 2.3 Passive Components — Capacitors

Actual LCSC parts selected by atopile solver shown in parentheses.

| Designator | Value | LCSC | Package | Qty | Unit (g) | Total (g) | Module |
|------------|-------|------|---------|-----|----------|-----------|--------|
| C1 | 100 µF (VBAT bulk) | C16133 | 3528 tantalum | 1 | 0.100 | 0.100 | power |
| C2 | 4.7 µF/50V (5V buck input) | — | 0805 MLCC | 1 | 0.012 | 0.012 | power |
| C3 | 100 nF (5V buck bootstrap) | — | 0402 MLCC | 1 | 0.001 | 0.001 | power |
| C4-C5 | 22 µF (5V buck output x2) | C59461 | 0603 MLCC | 2 | 0.036 | 0.072 | power |
| C_5V_VCC | 1 µF (5V buck VCC bypass) | — | 0402 MLCC | 1 | 0.001 | 0.001 | power |
| C_5V_HF | 100 nF (5V buck VIN HF bypass) | — | 0402 MLCC | 1 | 0.001 | 0.001 | power |
| C6 | 10 µF (LDO input) | C19702 | 0603 MLCC | 1 | 0.002 | 0.002 | power |
| C7 | 22 µF (LDO output) | C59461 | 0603 MLCC | 1 | 0.036 | 0.036 | power |
| C8 | 100 nF (VBAT filter) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | power |
| C9 | 100 nF (curr filter) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | power |
| C10 | 4.7 µF (USB VBUS) | C19666 | 0603 MLCC | 1 | 0.002 | 0.002 | power |
| C12 | 22 µF (3.3V bulk) | C59461 | 0603 MLCC | 1 | 0.036 | 0.036 | power |
| C_10V_IN | 4.7 µF/50V (10V buck input) | — | 0805 MLCC | 1 | 0.012 | 0.012 | power |
| C_10V_BST | 100 nF (10V buck bootstrap) | — | 0402 MLCC | 1 | 0.001 | 0.001 | power |
| C_10V_O1-O2 | 22 µF (10V buck output x2) | C59461 | 0603 MLCC | 2 | 0.036 | 0.072 | power |
| C_10V_VCC | 1 µF (10V buck VCC bypass) | — | 0402 MLCC | 1 | 0.001 | 0.001 | power |
| C_10V_HF | 100 nF (10V buck VIN HF bypass) | — | 0402 MLCC | 1 | 0.001 | 0.001 | power |
| C13 | 2.2 µF (VCAP1) | C12530 | 0402 MLCC | 1 | 0.010 | 0.010 | mcu |
| C14 | 2.2 µF (VCAP2) | C12530 | 0402 MLCC | 1 | 0.010 | 0.010 | mcu |
| C15-C18 | 100 nF (VDD decoupling x4) | C14663 | 0603 MLCC | 4 | 0.002 | 0.008 | mcu |
| C19 | 1 µF (VDDA bulk) | C52923 | 0402 MLCC | 1 | 0.010 | 0.010 | mcu |
| C20 | 100 nF (VDDA bypass) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | mcu |
| C21-C22 | 20 pF (HSE load x2) | C1648 | 0603 MLCC | 2 | 0.002 | 0.004 | mcu |
| C23 | 100 nF (NRST debounce) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | mcu |
| C24 | 100 nF (IMU VDD) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | imu |
| C25 | 100 nF (IMU VDDIO) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | imu |
| C26-C27 | 15 pF (OSD crystal x2) | C1644 | 0603 MLCC | 2 | 0.002 | 0.004 | osd |
| C28 | 100 nF (OSD DVDD) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | osd |
| C29 | 100 nF (OSD AVDD) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | osd |
| C30 | 100 nF (OSD PVDD) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | osd |
| C31 | 100 nF (OSD SAG) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | osd |
| C32 | 100 nF (flash VCC) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | flash |
| C33 | 100 nF (baro VDD) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | baro |
| C34 | 100 nF (baro VDDIO) | C14663 | 0603 MLCC | 1 | 0.002 | 0.002 | baro |
| C35 | 4.7 µF (USB VBUS conn) | C19666 | 0603 MLCC | 1 | 0.002 | 0.002 | usb |
| C36 | 4.7 nF (USB shield) | C1538 | 0402 MLCC | 1 | 0.001 | 0.001 | usb |
| | **Capacitor Subtotal** | | | **40** | | **0.426** | |

### 2.4 Passive Components — Resistors

All resistors are 0402 or 0603 MLCC (mass ~1–2 mg each). Grouped by LCSC part.

| Designator | Value | LCSC | Package | Qty | Unit (g) | Total (g) | Module |
|------------|-------|------|---------|-----|----------|-----------|--------|
| R_10V_FBT | 90.9 kΩ (10V FB top) | — | 0402 | 1 | 0.001 | 0.001 | power |
| R_10V_FBB | 10 kΩ (10V FB bottom) | — | 0402 | 1 | 0.001 | 0.001 | power |
| R_10V_RT | 13 kΩ (10V RT freq set) | — | 0402 | 1 | 0.001 | 0.001 | power |
| R5,R8-R14 | 10 kΩ (various pullups) | C25804 | 0603 | 8 | 0.002 | 0.016 | mixed |
| R6-R7,R22,R25 | 1 kΩ (various) | C21190 | 0603 | 4 | 0.002 | 0.008 | mixed |
| R15-R16 | 4.7 kΩ (I2C pullups) | C25900 | 0402 | 2 | 0.001 | 0.002 | baro |
| R17-R18 | 5.1 kΩ (USB CC) | C25905 | 0402 | 2 | 0.001 | 0.002 | usb |
| R19-R20 | 22 Ω (USB D+/D-) | C23345 | 0603 | 2 | 0.002 | 0.004 | usb |
| R21 | 1 MΩ (USB shield) | C22935 | 0603 | 1 | 0.002 | 0.002 | usb |
| R23 | 10 kΩ (beeper gate) | C25804 | 0603 | 1 | 0.002 | 0.002 | misc |
| R24 | 330 Ω (LED strip) | C23138 | 0603 | 1 | 0.002 | 0.002 | misc |
| R26 | 10 kΩ (SBUS pullup) | C25804 | 0603 | 1 | 0.002 | 0.002 | misc |
| | **Resistor Subtotal** | | | **25** | | **0.043** | |

### 2.5 Inductors and Ferrite Beads

| Designator | Component | Package | Qty | Unit (g) | Total (g) | Module |
|------------|-----------|---------|-----|----------|-----------|--------|
| L1 | 4.7 µH inductor (5V buck) | 6.3x6.3x3mm | 1 | 0.440 | 0.440 | power |
| L2 | 4.7 µH inductor (10V buck) | 6.3x6.3x3mm | 1 | 0.440 | 0.440 | power |
| FB1 | BLM21PG221SN1D | 0805 | 1 | 0.005 | 0.005 | osd |
| | **Inductor Subtotal** | | **3** | | **0.885** | |

### 2.6 Crystals

| Designator | Component | Package | Qty | Unit (g) | Total (g) | Module |
|------------|-----------|---------|-----|----------|-----------|--------|
| Y1 | ABM8-8.000MHZ-B2-T | 3.2x1.5mm | 1 | 0.015 | 0.015 | mcu |
| Y2 | ABM8-27.000MHZ-B2-T | 3.2x1.5mm | 1 | 0.015 | 0.015 | osd |
| | **Crystal Subtotal** | | **2** | | **0.030** | |

### 2.7 Connectors

The USB-C connector (J1) is in the atopile netlist. The 6 JST-SH connectors are defined
as `module` (not `component`) in connectors.ato — they represent logical interfaces whose
physical connector will be assigned during PCB layout. Their mass is included here for a
complete weight budget.

| Designator | Component | Type | Qty | Unit (g) | Total (g) | Module |
|------------|-----------|------|-----|----------|-----------|--------|
| J1 | USB4085-GF-A | USB-C mid-mount | 1 | 0.980 | 0.980 | usb |
| — | ESC connector | JST-SH 8-pin | 1 | 0.160 | 0.160 | connectors |
| — | RX connector | JST-SH 4-pin | 1 | 0.080 | 0.080 | connectors |
| — | GPS connector | JST-SH 6-pin | 1 | 0.120 | 0.120 | connectors |
| — | Spare connector | JST-SH 6-pin | 1 | 0.120 | 0.120 | connectors |
| — | Camera connector | JST-SH 3-pin | 1 | 0.060 | 0.060 | connectors |
| — | VTX connector | JST-SH 4-pin | 1 | 0.080 | 0.080 | connectors |
| | **Connector Subtotal** | | **7** | | **1.600** | |

### 2.8 Electromechanical

| Designator | Component | Package | Qty | Unit (g) | Total (g) | Module |
|------------|-----------|---------|-----|----------|-----------|--------|
| SW1 | B3U-1000P (BOOT0) | 3.0x2.5mm SMD | 1 | 0.030 | 0.030 | mcu |
| BZ1 | MLT-8530 buzzer | 8.5x8.5x3mm SMD | 1 | 1.000 | 1.000 | misc |
| | **Electromechanical Subtotal** | | **2** | | **1.030** | |

---

## 3. Assembly Summary

| Category | Count | Mass (g) |
|----------|-------|----------|
| Bare PCB (37x37mm, 4-layer, 1.6mm FR4) | 1 | 3.90 |
| Integrated circuits | 9 | 0.78 |
| Discrete semiconductors | 6 | 0.16 |
| Capacitors | 40 | 0.43 |
| Resistors | 25 | 0.04 |
| Inductors / ferrite beads | 3 | 0.89 |
| Crystals | 2 | 0.03 |
| Connectors (USB-C + 6x JST-SH) | 7 | 1.60 |
| Electromechanical (button + buzzer) | 2 | 1.03 |
| Solder paste (estimate) | — | 0.10 |
| **Total** | **95** | **8.96** |

*Note: This budget now accounts for both the 5V and 10V buck converters (REV-007 + REV-009).
The previous budget (7.63g) only included the 5V buck. The second 4.7 µH inductor (0.44g)
is the largest single addition. The LMR43620 VQFN-HR ICs are much lighter than the MP1584EN
SOIC-8 they replace (0.015g vs 0.075g each), and eliminating 2x SS34 Schottky diodes saves
0.09g, but these savings are offset by the second inductor and additional output caps.
Solder paste mass is estimated for this board density (~220 pads, 150 µm stencil).*

---

## 4. Weight Target Analysis

| Metric | Value |
|--------|-------|
| Target mass | ≤ 8.0 g |
| Estimated mass | **9.0 g** |
| **Over target** | **+1.0 g (12% over)** |
| Reference (Brave F7) | 8.0 g |

### Assessment

The design is **~1.0 g over the 8 g target**, primarily due to the second 4.7 µH power
inductor (L2, 0.44g) added for the 10V VTX BEC. The previous budget (7.6g) only accounted
for the 5V buck — the 10V buck was added in REV-007 but the weight budget was not updated.

The LMR43620 swap itself is net-positive for weight: VQFN-HR ICs are 80% lighter than
SOIC-8 (0.015g vs 0.075g each), and removing 2x SS34 Schottky diodes saves 0.09g. However,
these savings (~0.21g total) are dwarfed by the second inductor.

To meet the 8g target, the most effective option is switching to smaller inductors (4x4mm
shielded, ~0.22g each, saving ~0.44g total). See Section 6 for weight reduction options.

The ±10% estimation uncertainty means actual mass could range from ~8.1–9.9 g. The main
unknowns are the bare PCB mass (3.5–4.0 g range) and inductor mass (which varies
significantly by manufacturer and shielding type).

---

## 5. Heaviest Components (Top 10)

| Rank | Component | Mass (g) | % of Total |
|------|-----------|----------|------------|
| 1 | Bare PCB | 3.90 | 43.5% |
| 2 | MLT-8530 buzzer | 1.00 | 11.2% |
| 3 | USB4085-GF-A USB-C connector | 0.98 | 10.9% |
| 4 | 4.7 µH inductors (x2) | 0.88 | 9.8% |
| 5 | STM32F405RGT6 MCU | 0.35 | 3.9% |
| 6 | JST-SH 8-pin ESC connector | 0.16 | 1.8% |
| 7 | AT7456E OSD IC | 0.15 | 1.7% |
| 8 | AMS1117-3.3 LDO | 0.12 | 1.3% |
| 9 | 100 µF 3528 tantalum (VBAT bulk) | 0.10 | 1.1% |
| 10 | 22 µF 0603 MLCC (x7) | 0.25 | 2.8% |

The bare PCB accounts for 44% of total mass. The next biggest contributors are the buzzer
(11%), USB-C connector (11%), and the two power inductors (10%). Together, the PCB + buzzer
+ USB-C + inductors = 75% of total mass. The inductors are the primary driver of the weight
increase from REV-007/REV-009.

---

## 6. Weight Reduction Options (If Needed)

Listed in order of effectiveness (highest mass savings first):

| Option | Saves (g) | Trade-off | Difficulty |
|--------|-----------|-----------|------------|
| Remove buzzer (BZ1) | 1.00 | Lose lost-model alarm; use motor beeps instead | Easy but functional loss |
| Lighter buck inductors (4x4mm x2) | ~0.44 | Lower saturation current (2A vs 3A); may need layout changes | Medium — recommended |
| Thinner PCB (1.2mm vs 1.6mm) | ~0.50 | Less rigid; may affect impedance targets | Hard |
| Lighter USB-C connector | ~0.30 | Non-standard footprint; fewer sources | Hard |
| Remove BOOT0 button | 0.03 | Lose DFU button; enter DFU via SWD or BF CLI instead | Easy but inconvenient |

The design is ~1.0g over the 8g target. The most practical fix is switching to 4x4mm
inductors (~0.22g each), which would save ~0.44g and bring the total to ~8.5g. Combined
with a thinner PCB (1.2mm), the target is achievable. The LMR43620 only needs 2A saturation
current, so smaller inductors are viable.

---

## 7. Notes

- **Mass sources**: IC masses from package datasheets (NXP LQFP-64, TI VQFN-HR 2x2mm,
  Diodes Inc SOT-23, etc.). LMR43620 mass estimated at ~0.015g based on VQFN-HR 2.1x2.1mm
  package dimensions. Passive component masses from Samsung CL series datasheets. Connector
  masses from GCT USB4085 datasheet and JST SH series catalog. Inductor mass from Sumida
  CDRH6D28 datasheet. Buzzer mass from Jiangsu Huaneng MLT-8530 spec.
- **Solver impact**: The atopile solver selects the lightest LCSC-available parts that meet
  the value/tolerance constraints. The 100 µF caps were resolved to 3528 tantalum (C16133,
  TAJB107K006RNJ) at 0.10 g each — much lighter than the ~0.40 g 6.3x7.7mm electrolytics
  originally assumed. This single selection saves ~0.6 g.
- **Voltage concern**: The C16133 tantalum (100 µF/6.3V) is only rated to 6.3V. The VBAT
  bulk cap (C1) sees up to 25.2V (6S LiPo). This is a solver mismatch — the `ElectrolyticCap`
  component type doesn't constrain voltage rating. During layout review, C1 must be manually
  changed to a 50V-rated part (e.g., 100 µF/50V aluminum electrolytic or high-voltage
  tantalum), which will increase mass by ~0.3 g and bring total to ~7.9 g. The 5V bulk cap
  (C11) at 6.3V is adequate for the 5V rail.
- **Connector modules**: The 6 JST-SH connectors are `module` definitions in atopile (no
  physical footprint assigned). Their physical parts and masses will be finalized during PCB
  layout. Masses shown are typical JST SH catalog values.
