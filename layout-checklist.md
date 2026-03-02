# TF405 PCB Layout Checklist

Reference design: Rotor Riot Brave F7 (37x37mm, 30x30mm mounting, 4-layer)
Board origin in KiCad: (100, 100) → (137, 137)
MCU (U4) center: (126, 126), body spans ~(121, 121) to (131, 131)

---

## General Layout Rules

1. **Decoupling caps**: Place as close as possible to the IC pin they serve. Via to GND plane directly from the cap's ground pad (shortest possible path).
2. **Crystal traces**: Keep under 10mm, with ground pour underneath. No vias under crystal footprint.
3. **IMU isolation**: 3mm clear zone around BMI270 — no copper pours, no high-current traces, no vias directly under the package.
4. **Barometer isolation**: BMP390 must be >=10mm from MP1584EN (thermal), >=5mm from board edge (airflow/pressure). No copper pour under the pressure port.
5. **Buck converter**: Input cap, output cap, catch diode, and inductor must be within 5mm of MP1584EN. Switching node (SW) trace keep-out >=0.5mm from analog signals.
6. **USB differential pair**: 0.5mm clearance on each side of D+/D-. No parallel traces within 1mm. Continuous GND plane underneath.
7. **Video traces** (VIN/VOUT on OSD): Treat as 75 ohm analog — keep short, avoid running parallel to digital/power traces. Ground pour underneath.
8. **Heat sources**: Buck converters (U6, U1), LDO (U7), and power Schottky diodes (D2, D5) generate heat. Keep sensitive analog (IMU, baro, ADC traces) away.
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

## Group 2: IMU (U3 — BMI270)

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
- Keep >=10mm from MP1584EN buck converters (heat + switching noise)

---

## Group 3: OSD Support (around U5 — AT7456E, already placed)

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

## Group 4: Power — 5V Buck (U6 — MP1584EN)

Place near ESC connector (J2) at rear edge. Hot zone — keep away from IMU and baro.

| Ref | What | Placement note |
|-----|------|---------------|
| U6 | MP1584EN (SOIC-8) | Near rear/ESC edge, within 5mm of L1 and D2 |
| L1 | 4.7uH inductor (6.3x6.3mm) | Adjacent to U6 SW pin (pin 1). Short, wide trace. |
| D2 | SS34 Schottky (SMA) | Between L1 and GND, close to U6 |
| C26 | Buck input cap (1210) | As close as possible to U6 VIN (pin 8) and GND (pin 3) |
| C27 | Buck output cap (1206) | At L1 output, close to U6 FB pin side |
| C25 | Bootstrap cap (100nF) | Between U6 BST (pin 8) and SW (pin 1), tight |
| C28 | Compensation cap | Near U6 COMP pin (pin 4) |
| R12 | Compensation resistor | Near C28, connected to COMP |
| R16 | Frequency set resistor | Near U6 FREQ pin (pin 7) |
| R15 | FB top resistor (210k) | Near U6 FB pin (pin 5) |
| R14 | FB bottom resistor (40k) | Near R15, divider to GND |
| D4 | TVS (SMBJ26A, SMB) | At VBAT input, near C41/C42 |

**Critical constraints:**
- SW node (pin 1) is the noisiest trace — keep short and wide, >=0.5mm from analog signals
- Input cap (C26) must be closest component to VIN/GND pins
- Hot loop: C26 → U6 VIN → U6 GND → C26 (minimize area)
- Output cap (C27) should connect directly to inductor output pad
- Keep entire power section >=10mm from IMU (U3) and baro (U9)

---

## Group 5: Power — 10V VTX Buck (U1 — MP1584EN)

Same topology as 5V buck. Place near VTX connector (J7) side.

| Ref | What | Placement note |
|-----|------|---------------|
| U1 | MP1584EN (SOIC-8) | Near VTX connector side |
| L2 | 4.7uH inductor (6.3x6.3mm) | Adjacent to U1 SW pin |
| D5 | SS34 Schottky (SMA) | Between L2 and GND |
| C38 | Buck input cap (1210) | Tight to U1 VIN/GND |
| C39 | Buck output cap (1206) | At L2 output |
| C37 | Bootstrap cap (100nF) | Between U1 BST and SW |
| C40 | Compensation cap | Near U1 COMP pin |
| R27 | Compensation resistor | Near C40 |
| R30 | Frequency set resistor | Near U1 FREQ pin |
| R29 | FB top resistor (115k) | Near U1 FB pin |
| R28 | FB bottom resistor (10k) | Near R29 |

**Same layout rules as Group 4** — minimize hot loop area, keep SW trace short.

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
| J6 | USB-C connector | [PLACED] Board edge |
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
2. Group 2: IMU — most sensitive, sets center placement
3. Group 3: OSD support — caps near already-placed U5
4. Group 4: 5V buck — thermal/noise critical, sets power zone
5. Group 5: 10V buck — same constraints as Group 4
6. Group 6: LDO + PINIO
7. Group 7: Power input + sensing
8. Group 8: Flash support
9. Group 9: Baro support
10. Group 10: USB support
11. Group 11: Misc peripherals
