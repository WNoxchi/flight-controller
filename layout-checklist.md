# TF405 PCB Layout Checklist

Reference design: Rotor Riot Brave F7 (37x37mm, 30x30mm mounting, 4-layer)
Board origin in KiCad: (100, 100) → (137, 137)
MCU (U4) center: (126, 126), body spans ~(121, 121) to (131, 131)

---

## General Layout Rules

1. **Decoupling caps**: Place as close as possible to the IC pin they serve. Via to GND plane directly from the cap's ground pad (shortest possible path).
2. **Crystal traces**: Keep under 10mm, with ground pour underneath. No vias under crystal footprint.
3. **IMU isolation**: 3mm clear zone around BMI270 — no copper pours, no high-current traces, no vias directly under the package.
4. **Barometer isolation**: BMP390 must be >=10mm from LMR43620 buck converters (thermal), >=5mm from board edge (airflow/pressure). No copper pour under the pressure port.
5. **Buck converter**: Input cap, output caps, and inductor must be within 5mm of LMR43620. Switching node (SW) trace keep-out >=0.5mm from analog signals. Thermal pad via array to L2 GND plane required.
6. **USB differential pair**: 0.5mm clearance on each side of D+/D-. No parallel traces within 1mm. Continuous GND plane underneath.
7. **Video traces** (VIN/VOUT on OSD): Treat as 75 ohm analog — keep short, avoid running parallel to digital/power traces. Ground pour underneath.
8. **Heat sources**: Buck converters (U6, U1 — LMR43620, heat dissipated via thermal pad), LDO (U7) generate heat. Keep sensitive analog (IMU, baro, ADC traces) away.
9. **Grounding**: All ground connections should reach the L2 ground plane via short vias. Avoid splitting the ground plane under sensitive components.

---

## MCU Pin Map (LQFP-64, U4 at 126,126)

```
                    TOP SIDE (pins 49-64)
                  <-- right to left -->
          pin64                    pin49
           VDD4    BOOT0(60)
     +--------------------------------------+
     |                                      |  pin48 VDD3
p1   |                                      |  pin47 VCAP2
i    |          U4 - STM32F405              |
n    |          center: (126,126)           |  Right side
s    |          body: 121->131              |  (pins 33-48)
     |                                      |  ^ bottom to top
L  5 | PH0                                 |
e  6 | PH1                                 |
f  7 | NRST                                |
t 13 | VDDA                                |
     +--------------------------------------+
          pin17                    pin32
               VDD1(19)  PB2(28)  VDD2
               VCAP1(31)
                 BOTTOM SIDE (pins 17-32)
                  <-- left to right -->
```

---

## Group 1: MCU Decoupling [PLACED]

All components placed around U4 perimeter. Each decoupling cap on same side as its pin.

| Ref | What | Pin | Side | Approx position |
|-----|------|-----|------|-----------------|
| C11 | VDD1 decoupling (100nF) | 19 | Bottom | Below MCU, left (~123, 133) |
| C12 | VDD2 decoupling (100nF) | 32 | Bottom | Below MCU, right (~130, 133) |
| C13 | VDD3 decoupling (100nF) | 48 | Right | Right of MCU, top (~133, 122) |
| C14 | VDD4 decoupling (100nF) | 64 | Top | Above MCU, left (~122, 119) |
| C9 | VCAP1 (2.2uF, 0603) | 31 | Bottom | Below MCU, right of center (~129, 133) |
| C10 | VCAP2 (2.2uF, 0603) | 47 | Right | Right of MCU, near top (~133, 123) |
| C15 | VDDA bulk (1uF) | 13 | Left | Left of MCU, lower area (~119, 128) |
| C16 | VDDA bypass (100nF) | 13 | Left | Next to C15 (~119, 128) |
| Y1 | 8MHz crystal | 5,6 | Left | Left of MCU, upper-mid (~118, 124) |
| C6 | HSE load cap (20pF) | 5 | Left | Flanking Y1, between crystal pad and GND |
| C7 | HSE load cap (20pF) | 6 | Left | Flanking Y1, between crystal pad and GND |
| R10 | NRST pullup (10k) | 7 | Left | Left of MCU, mid (~119, 125) |
| C8 | NRST debounce (100nF) | 7 | Left | Next to R10 |
| R8 | BOOT0 pulldown (10k) | 60 | Top | Above MCU, left-center (~124, 119) |
| R9 | BOOT1 pulldown (10k) | 28 | Bottom | Below MCU, center-right (~128, 133) |

---

## Group 2: IMU (U3 — BMI270) [PLACED]

Place near board center for minimal mechanical stress. Isolate from vibration, heat, and EMI.

| Ref | What | Placement note |
|-----|------|---------------|
| U3 | BMI270 (LGA-14, 3x2.5mm) | Near board center. 3mm clearance zone. No vias under package. Away from buck converters and board edge. |
| C4 | VDD decoupling (100nF) | Within 2mm of U3 VDD pin |
| C5 | VDDIO decoupling (100nF) | Within 2mm of U3 VDDIO pin |

**Critical constraints:**
- No copper pour directly under U3
- No high-current traces within 3mm
- SPI1 traces (PA5/PA6/PA7 + PC4 CS + PC5 EXTI) should be short and direct to MCU
- Keep >=10mm from LMR43620 buck converters (heat + switching noise)

---

## Group 3: OSD Support (around U5 — AT7456E, already placed) [PLACED]

U5 is a TSSOP-28 with pins on left (1-14) and right (15-28) sides.

| Ref | What | Place near | Notes |
|-----|------|-----------|-------|
| C17 | AVDD decoupling (100nF) | U5 pin 9 (left side) | Analog supply — short via to GND |
| C18 | DVDD decoupling (100nF) | U5 pin 25 (right side) | Digital supply |
| C19 | PVDD decoupling (100nF) | U5 pin 5 (left side) | Video driver supply |
| C20 | SAG comp cap (100nF) | U5 pin 4 (left side) | Sag compensation |
| C21 | Crystal load cap (15pF) | Y2 pad 1 | Between Y2 and GND, tight to crystal |
| C22 | Crystal load cap (15pF) | Y2 pad 2 | Between Y2 and GND, tight to crystal |
| FB1 | AVDD ferrite bead (0805) | Between 3.3V rail and U5 pin 9 | Isolates analog supply from digital noise |
| R11 | Reset pullup (10k) | U5 pin 11 (left side) | Active-low reset, pull to 3.3V |

**Critical constraints:**
- Video traces (VIN pin 8, VOUT pin 3) are analog 75 ohm — keep short, ground pour under
- Crystal Y2 traces to pins 22/23 under 10mm
- FB1 must be in series between 3.3V rail and AVDD pin — not a bypass component

---

## Group 4: Power — 5V Buck (U6 — LMR43620MB5RPER, fixed 5V) [PLACED]

| Ref | What | Placement note |
|-----|------|---------------|
| U6 | LMR43620 (VQFN-HR 2x2mm, 9-pad) | Near rear/ESC edge. Pin 9 (GND) vias to GND plane. |
| L1 | 2.2µH inductor (Würth MAPI-4020, 4x4mm) | Pad 1 to U6 pin 5 (SW), pad 2 is 5V output |
| C26 | VIN input cap 4.7µF/50V (0805) | Close to U6 pin 4 (VIN), next to C33 |
| C33 | VIN HF bypass 100nF (0402) | Closest to U6 pin 4 (VIN) — hottest loop cap |
| C25 | Bootstrap cap 100nF (0402) | Between U6 pin 6 (BOOT) and pin 5 (SW) |
| C43 | VCC bypass 1µF (0402) | Adjacent to U6 pin 7 (VCC) |
| C39 | Output cap 22µF (1206) | At L1 pad 2 (5V output), pad 1 to 5V, pad 2 to GND |
| C40 | Output cap 22µF (1206) | Adjacent to C39 |
| R27 | EN/UVLO divider top 430kΩ (0402) | Near U6 pin 3 (EN), one pad to VBAT |
| R16 | EN/UVLO divider bottom 100kΩ (0402) | Near U6 pin 3 (EN), other pad to GND |
| R30 | PGOOD pullup 100kΩ (0402) | Near U6 pin 2 (PGOOD), pullup to 5V rail |

---

## Group 5: Power — 5V VTX Buck (U1 — LMR43620MB5RPER, fixed 5V) [PLACED]

Identical topology to Group 4 (REV-009b: dual-5V, matching Brave F7).

| Ref | What | Placement note |
|-----|------|---------------|
| U1 | LMR43620 (VQFN-HR 2x2mm, 9-pad) | Near VTX connector side. Pin 9 (GND) vias to GND plane. |
| L2 | 2.2µH inductor (Würth MAPI-4020, 4x4mm) | Pad 1 to U1 pin 5 (SW), pad 2 is 5V VTX output |
| C27 | VIN input cap 4.7µF/50V (0805) | Close to U1 pin 4 (VIN), next to C28 |
| C28 | VIN HF bypass 100nF (0402) | Closest to U1 pin 4 (VIN) |
| C24 | Bootstrap cap 100nF (0402) | Between U1 pin 6 (BOOT) and pin 5 (SW) |
| C44 | VCC bypass 1µF (0402) | Adjacent to U1 pin 7 (VCC) |
| C37 | Output cap 22µF (1206) | At L2 pad 2 (5V VTX output), pad 1 to 5V, pad 2 to GND |
| C38 | Output cap 22µF (1206) | Adjacent to C37 |
| R14 | EN/UVLO divider top 430kΩ (0402) | Near U1 pin 3 (EN), one pad to VBAT |
| R12 | EN/UVLO divider bottom 100kΩ (0402) | Near U1 pin 3 (EN), other pad to GND |
| R15 | PGOOD pullup 100kΩ (0402) | Near U1 pin 2 (PGOOD), pullup to 5V VTX rail |

---

## Group 6: Power — LDO + PINIO (U7, Q2, Q4)

| Ref | What | Placement note |
|-----|------|---------------|
| U7 | AMS1117-3.3 (SOT-223) | Between 5V rail and 3.3V rail, near MCU side |
| C30 | LDO input cap (0805) | Tight to U7 input pin |
| C32 | LDO output cap (0805) | Tight to U7 output pin |
| C23 | 3.3V bulk tantalum | [PLACED] Near LDO output |
| Q2 | PINIO P-FET (SOT-23) | Near VTX power path |
| Q4 | PINIO N-FET level shifter (SOT-23) | Near Q2 and R17/R31 |
| R17 | PINIO gate resistor | Between MCU PB2 and Q4 gate |
| R31 | PINIO pullup (100k) | Near Q2 gate |

---

## Group 7: Power — Input + Sensing

| Ref | What | Placement note |
|-----|------|---------------|
| C41, C42 | VBAT bulk caps (1210) | [PLACED] Near ESC connector VBAT pin |
| C34 | VBAT ADC filter cap | Near voltage divider |
| R19 | VBAT divider top (100k) | Between VBAT and MCU PC2 |
| R18 | VBAT divider bottom (10k) | Between divider midpoint and GND |
| R13 | Current sense filter R (1k) | Near ESC connector CURR pin |
| C29 | Current sense filter C (100nF) | Next to R13, RC filter to MCU PC1 |
| D3 | USB power OR Schottky (SMA) | Near USB connector, between VBUS and 5V rail |
| C36 | USB VBUS cap | Near D3 / USB connector |

---

## Group 8: Flash (U10 — W25Q128, already placed)

| Ref | What | Placement note |
|-----|------|---------------|
| U10 | W25Q128 (SOIC-8) | [PLACED] Near MCU for short SPI3 traces |
| C3 | VCC decoupling (100nF) | Within 2mm of U10 VCC pin |
| R4 | HOLD pullup (10k) | Near U10 HOLD pin |
| R5 | WP pullup (10k) | Near U10 WP pin |

---

## Group 9: Barometer (U9 — BMP390, already placed)

| Ref | What | Placement note |
|-----|------|---------------|
| U9 | BMP390 (LGA-10, 2x2mm) | [PLACED] Must be >=10mm from buck converters, >=5mm from board edge |
| C1 | VDD decoupling (100nF) | Within 2mm of U9 VDD pin |
| C2 | VDDIO decoupling (100nF) | Within 2mm of U9 VDDIO pin |
| R1 | I2C SCL pullup (4.7k) | Near U9 or MCU I2C pins |
| R2 | I2C SDA pullup (4.7k) | Near R1 |

**Critical constraints:**
- No copper pour under pressure port (pin 3 area)
- Thermal isolation from power section is critical for altitude accuracy

---

## Group 10: USB (J6 — already placed)

| Ref | What | Placement note |
|-----|------|---------------|
| J6 | USB-C connector (HRO TYPE-C-31-M-12) | [PLACED] Board edge — needs footprint swap |
| U8 | USBLC6-2SC6 ESD (SOT-23-6) | Within 5mm of J6, before any other component on D+/D- |
| R24 | USB D- series (22 ohm) | Between U8 and MCU PA11 |
| R25 | USB D+ series (22 ohm) | Between U8 and MCU PA12 |
| R22 | CC1 pulldown (5.1k) | Near J6 CC1 pin |
| R23 | CC2 pulldown (5.1k) | Near J6 CC2 pin |
| C35 | Shield cap (4.7nF) | Near J6 shield pins |
| R26 | Shield resistor (1M) | Near C35 |
| C36 | VBUS cap (4.7uF) | Near J6 VBUS pin |

**Critical constraints:**
- D+/D- are a differential pair: 0.5mm clearance zone each side, matched length
- ESD protection (U8) must be the FIRST component on D+/D- after the connector
- Continuous GND plane under entire USB route

---

## Group 11: Misc Peripherals

| Ref | What | Placement note |
|-----|------|---------------|
| BZ1 | MLT-8530 buzzer (8.5x8.5mm) | Board edge, away from IMU (vibration source) |
| Q1 | Beeper N-FET (SOT-23) | Near BZ1 |
| R3 | Beeper gate resistor | Between MCU PB1 and Q1 gate |
| D1 | Status LED (0603) | Board edge, visible |
| R6 | LED current limit resistor | Near D1 |
| R7 | LED strip data resistor (330 ohm) | Near board edge LED pad |
| Q3 | SBUS inverter N-FET (SOT-23) | Near RX connector (J4) |
| R20 | SBUS gate resistor | Near Q3 |
| R21 | SBUS pullup | Near Q3 drain |

---

## Connector Placement Summary

| Ref | Connector | Edge | Status |
|-----|-----------|------|--------|
| J2 | ESC (8-pin) | Rear | PLACED |
| J4 | RX (4-pin) | Rear | PLACED |
| J6 | USB-C | Rear | PLACED |
| J3 | GPS (6-pin) | Right | PLACED |
| J7 | VTX (5-pin) | Rear | PLACED |
| J1 | Camera (5-pin) | Right | PLACED |
| J5 | Spare (6-pin) | Left | Unplaced — left edge |

---

## Placement Priority Order

1. ~~Group 1: MCU decoupling~~ [DONE]
2. ~~Group 2: IMU~~ [DONE]
3. ~~Group 3: OSD support~~ [DONE]
4. ~~Group 4: 5V buck~~ [DONE]
5. ~~Group 5: 5V VTX buck~~ [DONE]
6. Group 6: LDO + PINIO
7. Group 7: Power input + sensing
8. Group 8: Flash support
9. Group 9: Baro support
10. Group 10: USB support
11. Group 11: Misc peripherals
