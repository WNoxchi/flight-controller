# Flight Controller Implementation Plan

**Last Updated**: 2026-03-01 — TASK-021 (Physical Board Constraints) completed

**Status**: TASK-001 through TASK-021 + TASK-011A complete (all circuit implementation, validation, PCB stackup, and physical board constraints). MCU core (18 components, 11 asserts), power system (20 components, 5 asserts), USB-C interface (10 components, 5 asserts), IMU BMI270 (3 components, 2 asserts), Barometer BMP390 (5 components, 4 asserts), Flash W25Q128 (4 components, 1 assert), OSD AT7456E (10 components, 2 asserts), ESC/Motor wiring (signal routing only), Video path (signal routing only), UART connectors (all 3 wired + I2C1 GPS), SBUS inverter (3 components, 2 asserts), Status LED (2 components, 1 assert), Beeper (3 components, 1 assert), LED strip (1 component, 1 assert), Camera control (direct passthrough), PA4 breakout (direct passthrough), SpareConnector 6-pin definition, PCB layer stackup specification, and physical board constraints document fully implemented with clean `ato build`. 35 total assertions passing. All circuit tasks complete — only TASK-022 (weight budget) remains.

**Project State**: ALL circuit implementation and validation tasks complete — MCU, power, USB, IMU, baro, flash, OSD, SBUS inverter, status LED, beeper, LED strip, camera control, PA4 breakout implemented. All connectors fully wired and spec-compliant (ESC, RX, GPS, Spare [6-pin], Camera, VTX). 84 components total in BOM (41 unique). 35 assertions passing. Build pipeline operational. I2C1 bus fully wired with pullups + GPS connector. All SPI buses have their ICs instantiated (SPI1=BMI270, SPI2=AT7456E, SPI3=W25Q128). All 5 usable UARTs wired (UART1=RX/SBUS, UART2=GPS, UART3=Spare, UART4=ESC telem, UART5=SmartAudio). All ground connections added for connectors and misc modules. All GPIO breakouts complete (PA4 servo/detonator pad). Only TASK-022 (weight budget) remains.

**Key Findings**:
- 0 TODO comments remain (down from 43 — all TODOs resolved including camera control)
- 35/44 assert statements implemented (MCU + Power + USB + IMU + Baro + Flash + OSD + SBUS inverter + LED + Beeper + LED strip modules)
- 3 voltage-level assertions (rail_5v, rail_3v3, v_adc_vbat) cannot be verified in atopile v0.2.69 — solver only handles passive component values, not computed voltages
- All module grounds now connected (USB, IMU, baro, flash, OSD, ESC, camera, VTX, RX, GPS, spare, LED, beeper, LED strip, camera control, SBUS inverter)
- All connectors fully wired (ESC, RX, GPS, Spare, Camera, VTX)
- All 5 usable UARTs wired (UART1=RX/SBUS, UART2=GPS, UART3=Spare, UART4=ESC telem, UART5=SmartAudio)
- GPS connector includes I2C1 (SCL/SDA) for external magnetometer
- No atopile packages available for custom ICs (all custom-defined)
- SpareConnector fixed: all 6 pins defined (GND, 5V, TX3, RX3, 5V_2, GND_2)
- Buzzer_MLT8530 component: `designator_prefix = "BZ"`, `footprint = "Buzzer_Beeper:Buzzer_SMD_MLT-8530_8.5x8.5mm"`, mpn `MLT-8530`
- Power module exposes adc_vbat, adc_curr, pinio1, vbat_sw, usb_vbus, curr_in signals for top-level wiring
- atopile v0.2.69 supports alphanumeric pin names (`pin A4`) — useful for USB-C and other non-numeric pad names
- 2N7002 SOT-23 pinout: Gate(1), Source(2), Drain(3) — verified against ON Semi datasheet

---

## Priority 1: Foundation & Power (Blocking All Other Work)

### TASK-001: Implement MCU Core Component ✅ COMPLETE
**Spec**: `specs/mcu-core.md`
**File**: `src/mcu.ato`
**Completed**: 2026-03-01
**Priority**: CRITICAL - Blocks all peripheral implementations
**Dependencies**: None

**Implementation Summary**:
- STM32F405RGT6 custom component with LQFP-64 footprint, correct 64-pin mapping (verified against DS8597 Rev 9)
- 8MHz HSE crystal (ABM8-8.000MHZ-B2-T) with 20pF load caps on PH0/PH1 (pins 5/6)
- VCAP1/VCAP2: 2.2µF +/- 5% (pins 31/47)
- Per-VDD decoupling: 4x 100nF (LQFP-64 has 4 VDD pins: 19, 32, 48, 64)
- VDDA filtering: 1µF bulk + 100nF bypass on pin 13
- BOOT0 (pin 60): 10kΩ pulldown + tactile switch to 3.3V
- NRST (pin 7): 10kΩ pullup + 100nF debounce + tactile switch to GND
- PB2/BOOT1 (pin 28): 10kΩ pulldown (mandatory)
- SWD: PA13/PA14 exposed as module signals for board-level test pad routing
- All 11 assert constraints pass
- `ato build` passes cleanly

**Discoveries**:
- LQFP-64 has only 4 VDD pins (not 5 as initially assumed). Pin budget verified.
- VCAP caps need +/- 5% tolerance (not 10%) to fit within 2.0-2.4uF assertion range
- Generic Capacitor/Resistor components with `value` attribute and `designator_prefix` work for auto-part-selection in atopile v0.2.69

**Also Fixed (blockers for ato build)**:
- `ato.yaml`: Changed `requires-atopile: "^0.10.8"` to `ato-version: "0.2.69"` (config key name mismatch)
- `ato.yaml`: Changed `entry: tf405.ato:TF405` to `entry: src/tf405.ato:TF405` (path resolution)
- All `src/*.ato` files: Changed `X = new Electrical` to `signal X` (v0.2.69 uses `signal` keyword, not `new Electrical`)
- `src/tf405.ato`: Changed `from "src/X.ato"` to `from "X.ato"` (imports are relative to file location)

---

### TASK-002: Implement Power Distribution System ✅ COMPLETE
**Spec**: `specs/power.md`
**File**: `src/power.ato`
**Completed**: 2026-03-01
**Priority**: CRITICAL - Blocks all peripheral power connections
**Dependencies**: TASK-001 (MCU needs power)

**Implementation Summary**:
- **MP1584EN SOIC-8 buck converter**: custom 8-pin component, VBAT→5V/3A
  - Feedback divider: 210kΩ/40kΩ (datasheet-recommended for 5V, Vref=0.8V)
  - Bootstrap cap: 100nF (BST-to-SW), input cap: 22µF, output cap: 22µF
  - Inductor: 4.7µH/3A shielded (CDRH6D28HPNP-4R7NC)
  - SS34 Schottky catch diode on SW node
  - Frequency set: 100kΩ to GND (~300kHz switching)
  - Compensation: 100kΩ + 150pF series RC on COMP pin
  - EN tied to VIN for always-on operation
- **AMS1117-3.3 SOT-223 LDO**: 5V→3.3V, 10µF input + 22µF tantalum output
  - Tab (pin 4) electrically connected to VOUT — important for PCB layout
- **VBAT protection**: SMBJ26A TVS + 100µF/50V electrolytic bulk cap
- **Battery voltage divider**: 10kΩ/1kΩ (10:1), 100nF filter, → PC2 (ADC_VBAT)
- **Current sense**: 1kΩ + 100nF RC filter (fc ~1.6kHz), → PC1 (ADC_CURR)
- **PINIO1 P-FET**: AO3401A SOT-23 (G=pin1, S=pin2, D=pin3), 10kΩ gate resistor
  - Source=VBAT, Drain=VBAT_SW, Gate via 10k from PB2
- **USB power OR**: SS34 Schottky (VBUS→5V rail) + 4.7µF decoupling
- **Bulk decoupling**: 100µF electrolytic on 5V, 22µF tantalum on 3.3V
- 20 components total, 5 passing assert constraints
- `ato build` passes cleanly, all LCSC parts auto-resolved

**Assertions Implemented (5/8 spec constraints)**:
- ✅ `r_vbat_top.value within 9.9kohm to 10.1kohm`
- ✅ `r_vbat_bot.value within 990ohm to 1.01kohm`
- ✅ `r_curr_filter.value within 900ohm to 1.1kohm`
- ✅ `c_curr_filter.value within 80nF to 120nF`
- ✅ `r_pinio_gate.value within 9.9kohm to 10.1kohm`
- ⚠️ `rail_5v within 4.75V to 5.25V` — cannot verify: atopile v0.2.69 solver handles passive values only, not computed voltages
- ⚠️ `rail_3v3 within 3.2V to 3.4V` — same limitation
- ⚠️ `v_adc_vbat within 0V to 3.3V` — same limitation

**Top-level wiring added in tf405.ato**:
- `power.adc_vbat ~ mcu.pc2` (battery voltage sense)
- `power.adc_curr ~ mcu.pc1` (current sense)
- `power.pinio1 ~ mcu.pb2` (VTX power control)

**Module interface signals exposed for future wiring**:
- `power.vbat` — battery input (to be wired from ESC connector in TASK-009)
- `power.vbat_sw` — switched VBAT output (to be wired to VTX connector in TASK-010)
- `power.usb_vbus` — USB VBUS input (to be wired from USB module in TASK-003)
- `power.curr_in` — raw current sense input (to be wired from ESC connector in TASK-009)

**Discoveries**:
- MP1584EN pin 6 (FREQ) needs external resistor to set switching frequency — not mentioned in some datasheets
- MP1584EN pin 3 (COMP) needs series RC compensation network for loop stability
- AMS1117 SOT-223 tab is connected to VOUT (not GND) — PCB layout must route tab trace to output rail
- AO3401A SOT-23 pinout: pin1=Gate, pin2=Source, pin3=Drain
- atopile v0.2.69 cannot verify voltage-level assertions (only passive component values)

---

### TASK-003: Implement USB-C Interface ✅ COMPLETE
**Spec**: `specs/usb-c.md`
**File**: `src/usb.ato`
**Completed**: 2026-03-01
**Priority**: HIGH - Needed for programming and power OR circuit
**Dependencies**: TASK-002 (5V rail for Schottky diode)

**Implementation Summary**:
- **GCT USB4085-GF-A**: custom 16-pin component with alphanumeric pad names (A1-A12, B1-B12, S1)
  - 4 VBUS pads (A4, A9, B4, B9) tied to internal vbus_raw node
  - 4 GND pads (A1, A12, B1, B12) tied to system ground
  - D1+/D2+ shorted together, D1-/D2- shorted together (USB-C reversibility)
  - CC1 (A5) and CC2 (B5) exposed for pulldown resistors
  - SBU1/SBU2 left floating (unused in USB 2.0 device mode)
  - Shield (S1) grounded via RC network
- **CC1/CC2 pulldowns**: 2x 5.1kΩ +/- 1% to GND (UFP/sink identification)
- **USBLC6-2SC6 ESD protection**: SOT-23-6, I/O1 on D-, I/O2 on D+, VBUS on pin 4
  - Dual-pin per line (pins 1&2 and 5&6 internally shorted) for low inductance
- **Series resistors**: 2x 22Ω +/- 5% on D+/D- (USB 2.0 impedance matching)
- **VBUS decoupling**: 4.7µF +/- 10% on connector-side VBUS (before power OR Schottky)
- **Shield grounding**: 1MΩ || 4.7nF from shell to GND (DC bleeder + AC coupling)
- 10 components total, 5 passing assert constraints
- `ato build` passes cleanly, all LCSC parts auto-resolved

**Assertions Implemented (5/5 spec constraints)**:
- ✅ `r_cc1.value within 4.9kohm to 5.3kohm`
- ✅ `r_cc2.value within 4.9kohm to 5.3kohm`
- ✅ `r_dp.value within 20ohm to 24ohm`
- ✅ `r_dm.value within 20ohm to 24ohm`
- ✅ `c_vbus.value within 4.0uF to 5.5uF`

**Top-level wiring added/updated in tf405.ato**:
- `usb.dm ~ mcu.pa11` (USB D- to MCU, already existed)
- `usb.dp ~ mcu.pa12` (USB D+ to MCU, already existed)
- `usb.gnd ~ power.gnd` (new — USB ground)
- `usb.vbus ~ power.usb_vbus` (new — USB VBUS to power OR circuit)
- Removed `usb.rail_5v ~ power.rail_5v` (unused — USB doesn't need direct 5V)

**Discoveries**:
- atopile v0.2.69 supports alphanumeric pin names: `signal x ~ pin A4` works for USB-C pad names
- USBLC6-2SC6 pins 1&2 are internally connected (I/O1), pins 5&6 are internally connected (I/O2) — both pads must be wired to the same net for correct footprint mapping
- Power OR Schottky + bulk cap already exists in power.ato (Section 7) — USB module only needs connector-side VBUS decoupling
- GCT USB4085-GF-A KiCad footprint name: `USB_C_Receptacle_GCT_USB4085`

**Notes**:
- NDAA compliance: GCT (UK company, clean), USBLC6-2SC6 (ST, Franco-Italian, clean)
- 90Ω differential impedance requires PCB stackup definition (TASK-020)

---

## Priority 2: Sensors & Critical Peripherals

### TASK-004: Implement IMU BMI270 ✅ COMPLETE
**Spec**: `specs/imu-bmi270.md`
**File**: `src/imu.ato`
**Completed**: 2026-03-01
**Priority**: HIGH - Critical for flight control
**Dependencies**: TASK-001 (SPI1), TASK-002 (3.3V rail)

**Implementation Summary**:
- **BMI270 LGA-14 custom component**: full 14-pin mapping from Bosch datasheet BST-BMI270-DS000
  - Footprint: `Bosch_LGA-14_3x2.5mm_P0.5mm` (standard KiCad library)
  - Pin 1 (SDO) → SPI MISO, Pin 12 (CSB) → chip select, Pin 13 (SCx) → SPI clock, Pin 14 (SDx) → SPI MOSI
  - Pin 4 (INT1) → data-ready interrupt on PC5
  - Pins 2,3,9,10,11 (auxiliary OIS interface) left floating per datasheet
- **VDD decoupling**: 100nF +/- 10% on pin 8 (main analog+digital supply)
- **VDDIO decoupling**: 100nF +/- 10% on pin 5 (digital I/O supply)
  - Both VDD and VDDIO powered from same 3.3V rail (valid per datasheet: VDD 1.71–3.6V, VDDIO 1.2–3.6V)
- **Ground**: Both GND (pin 7) and GNDIO (pin 6) connected to system ground
- **Top-level wiring**: `imu.gnd ~ power.gnd` added in tf405.ato
- 3 components total (BMI270 + 2 decoupling caps), 2 passing assert constraints
- `ato build` passes cleanly, LCSC parts auto-resolved (C14663 for 100nF caps)

**Assertions Implemented (2/4 spec constraints)**:
- ✅ `c_vdd.value within 80nF to 120nF`
- ✅ `c_vddio.value within 80nF to 120nF`
- ⚠️ `vdd within 1.71V to 3.6V` — cannot verify: atopile v0.2.69 solver handles passive values only
- ⚠️ `vddio within 1.2V to 3.6V` — same limitation

**Discoveries**:
- BMI270 has separate GND (pin 7) and GNDIO (pin 6) — both must be connected to system ground
- CS pull-up resistor is optional per spec; MCU GPIO drives CS directly (active low) which is sufficient
- SPI Mode 0 (CPOL=0, CPHA=0), max 10MHz — firmware configuration, not enforced in hardware
- GYRO_1_ALIGN: CW270_DEG is firmware config, depends on physical PCB orientation

---

### TASK-005: Implement Barometer BMP390 ✅ COMPLETE
**Spec**: `specs/baro-bmp390.md`
**File**: `src/baro.ato`
**Completed**: 2026-03-01
**Priority**: HIGH - Critical for altitude hold
**Dependencies**: TASK-001 (I2C1), TASK-002 (3.3V rail)

**Implementation Summary**:
- **BMP390 LGA-10 custom component**: full 10-pin mapping from Bosch datasheet BST-BMP390-DS002
  - Footprint: `Bosch_LGA-10_2x2mm_P0.275x0.250mm` (standard KiCad library)
  - Pin 2 (SCK) → I2C SCL, Pin 4 (SDI) → I2C SDA
  - Pin 6 (CSB) tied to VDDIO → I2C mode (not SPI)
  - Pin 5 (SDO) tied to VDDIO → I2C address 0x77
  - Pin 7 (INT) left floating — Betaflight BMP388 driver uses polling
  - Pins 3, 8, 9 (three VSS pins) all connected to system ground
- **VDD decoupling**: 100nF +/- 10% on pin 10 (main analog supply)
- **VDDIO decoupling**: 100nF +/- 10% on pin 1 (digital I/O supply)
  - Both VDD and VDDIO powered from same 3.3V rail (valid per datasheet: VDD 1.7–3.6V, VDDIO 1.2–3.6V)
- **I2C bus pullups**: 2x 4.7kΩ +/- 1% to 3.3V on SCL and SDA
  - One set for the entire I2C1 bus (shared with external magnetometer on GPS connector)
- **Ground**: `baro.gnd ~ power.gnd` added in tf405.ato
- 5 components total (BMP390 + 2 decoupling caps + 2 pullup resistors), 4 passing assert constraints
- `ato build` passes cleanly, LCSC parts auto-resolved (C14663 for 100nF caps, C25900 for 4.7kΩ resistors)

**Assertions Implemented (4/6 spec constraints)**:
- ✅ `c_vdd.value within 80nF to 120nF`
- ✅ `c_vddio.value within 80nF to 120nF`
- ✅ `r_scl_pullup.value within 4.5kohm to 4.9kohm`
- ✅ `r_sda_pullup.value within 4.5kohm to 4.9kohm`
- ⚠️ `vdd within 1.7V to 3.6V` — cannot verify: atopile v0.2.69 solver handles passive values only
- ⚠️ `vddio within 1.2V to 3.6V` — same limitation

**Discoveries**:
- BMP390 LGA-10 has 3 VSS pins (3, 8, 9) — all must be connected to ground
- CSB pin must be tied high for I2C mode, low for SPI mode (not just chip select)
- SDO has internal pull-up for default 0x77 address, but explicit tie is more reliable
- BMP390 is register-compatible with BMP388 — uses same Betaflight driver
- I2C pullups placed in baro module as bus-level components (TASK-006 partially addressed)

**Notes**:
- NDAA compliance: Bosch (German company, clean)
- I2C bus pullups implemented here cover TASK-006 I2C1 pullup requirement

---

### TASK-006: Implement I2C Bus Infrastructure ✅ COMPLETE
**Spec**: `specs/baro-bmp390.md` (line 13), general I2C requirements
**File**: `src/baro.ato` (pullups), `src/tf405.ato` (GPS wiring)
**Completed**: 2026-03-01 (pullups in TASK-005, GPS I2C routing in TASK-011)
**Priority**: MEDIUM - GPS magnetometer support
**Dependencies**: TASK-002 (3.3V rail)

**Implementation Summary**:
- ✅ I2C1 bus pullups: 2x 4.7kΩ to 3.3V (in Baro_BMP390 module, shared bus)
- ✅ GPS connector I2C routing: `gps_conn.scl ~ mcu.pb8`, `gps_conn.sda ~ mcu.pb9` (done in TASK-011)
- ✅ Assert statements for pullup resistor values (in TASK-005)
- ✅ `ato build` compiles without errors

**Notes**:
- Pullups in baro module are shared by BMP390 and external magnetometer (same I2C1 bus)

---

### TASK-007: Implement Flash Memory W25Q128 ✅ COMPLETE
**Spec**: `specs/flash-w25q128.md`
**File**: `src/flash.ato`
**Completed**: 2026-03-01
**Priority**: MEDIUM - Needed for blackbox logging
**Dependencies**: TASK-001 (SPI3), TASK-002 (3.3V rail)

**Implementation Summary**:
- **W25Q128JVSIQ SOIC-8 custom component**: full 8-pin mapping from Winbond datasheet W25Q128JV Rev.I
  - Footprint: `Package_SO:SOIC-8_5.23x5.23mm_P1.27mm` (standard KiCad library)
  - Pin 1 (/CS) → chip select from MCU PB7, directly driven (active low)
  - Pin 2 (DO) → SPI MISO data output
  - Pin 5 (DI) → SPI MOSI data input
  - Pin 6 (CLK) → SPI clock input
  - Pin 4 (GND) → system ground
  - Pin 8 (VCC) → 3.3V supply
- **/WP pullup**: 10kΩ +/- 1% to VCC (disables write protection for full blackbox access)
- **/HOLD pullup**: 10kΩ +/- 1% to VCC (disables hold function, prevents communication pause)
- **VCC decoupling**: 100nF +/- 10% ceramic capacitor close to pin 8
- **Ground connection**: `flash.gnd ~ power.gnd` added in tf405.ato
- 4 components total (W25Q128JVSIQ + 1 decoupling cap + 2 pullup resistors), 1 passing assert constraint
- `ato build` passes cleanly, LCSC parts auto-resolved (C25804 for 10kΩ resistors, C14663 for 100nF cap)

**Assertions Implemented (1/2 spec constraints)**:
- ✅ `c_vcc.value within 80nF to 120nF`
- ⚠️ `vcc within 2.7V to 3.6V` — cannot verify: atopile v0.2.69 solver handles passive values only

**Discoveries**:
- W25Q128JVSIQ SOIC-8 standard pinout: /CS(1), DO(2), /WP(3), GND(4), DI(5), CLK(6), /HOLD(7), VCC(8)
- /CS has internal pullup per datasheet — no external pullup needed, MCU GPIO drives directly
- 10kΩ pullups chosen for /WP and /HOLD per spec recommendation (provides slight ESD current limiting vs direct VCC tie)
- Standard SPI Mode 0 or Mode 3, up to 133MHz — MCU SPI3 runs at ~21MHz (APB1=42MHz / prescaler)

**Notes**:
- NDAA compliance: Winbond (Taiwanese company, clean)
- SPI3 pins correctly mapped: PC10 (SCK), PC11 (MISO), PB5 (MOSI), PB7 (CS)

---

### TASK-008: Implement OSD AT7456E ✅ COMPLETE
**Spec**: `specs/osd-at7456e.md`
**File**: `src/osd.ato`
**Completed**: 2026-03-01
**Priority**: MEDIUM - Needed for on-screen display
**Dependencies**: TASK-001 (SPI2), TASK-002 (3.3V rail), TASK-010 (video connectors)

**Implementation Summary**:
- **AT7456E TSSOP-28-EP custom component**: full 28-pin mapping + exposed pad from MAX7456/AT7456E datasheet
  - Footprint: `Package_SO:TSSOP-28-1EP_4.4x9.7mm_P0.65mm` (standard KiCad library)
  - Pin 8 (VIN) → camera composite video input (NOT pin 17 as spec incorrectly stated)
  - Pin 3 (VOUT) → composited video output to VTX (NOT pin 22 as spec incorrectly stated)
  - Pin 18 (SCLK) → SPI clock, Pin 19 (SDIN) → MOSI, Pin 17 (SDOUT) → MISO, Pin 20 (CS) → chip select
  - Pin 25 (DVDD) → digital supply, Pin 9 (AVDD) → analog supply, Pin 5 (PVDD) → video driver supply
  - Three separate ground domains: DGND (24), AGND (10), PGND (6) — all to system ground
  - Exposed pad (pin 29) → AGND for thermal dissipation
- **DVDD decoupling**: 100nF +/- 10% to DGND (pin 24)
- **AVDD decoupling**: 100nF +/- 10% to AGND (pin 10), after ferrite bead
- **PVDD decoupling**: 100nF +/- 10% to PGND (pin 6)
- **Ferrite bead**: BLM21PG221SN1D (0805, 220Ω@100MHz) isolating AVDD from digital 3.3V rail
- **27MHz crystal**: ABM8-27.000MHZ-B2-T on CLKIN (pin 23) / XFB (pin 22) with 2x 15pF load caps
- **RESET pullup**: 10kΩ +/- 1% to DVDD (keeps IC in normal operation)
- **SAG compensation**: 100nF cap from SAG (pin 4) to VOUT per MAX7456 application circuit
- **Ground connection**: `osd.gnd ~ power.gnd` added in tf405.ato
- HSYNC (12), VSYNC (13), LOS (16), CLKOUT (21) left floating (unused in Betaflight)
- 10 components total (AT7456E + crystal + ferrite bead + reset pullup + 2 crystal caps + 4 decoupling/sag caps)
- 2 passing assert constraints
- `ato build` passes cleanly, LCSC parts auto-resolved (C14663 for 100nF caps, C1644 for 15pF caps)

**Assertions Implemented (2/4 spec constraints)**:
- ✅ `c_dvdd.value within 80nF to 120nF`
- ✅ `c_avdd.value within 80nF to 120nF`
- ⚠️ `dvdd within 3.0V to 3.6V` — cannot verify: atopile v0.2.69 solver handles passive values only
- ⚠️ `avdd within 3.0V to 3.6V` — same limitation

**Discoveries**:
- AT7456E package is TSSOP-28-EP (NOT TQFP-28 as spec header says). TQFP has leads on 4 sides; TSSOP has leads on 2 sides.
- Spec pin numbers were incorrect: spec said VIN=pin 17, VOUT=pin 22. Actual: VIN=pin 8, VOUT=pin 3. Pin 17=SDOUT (MISO), pin 22=XFB (crystal feedback).
- AT7456E (Chinese clone) operates at 3.3V on ALL supply pins including PVDD, unlike original MAX7456 which needs 5V on AVDD/PVDD.
- Three separate power domains (DVDD/DGND, AVDD/AGND, PVDD/PGND) + exposed pad. All grounds connect to system ground; star-ground handled in PCB layout.
- 27MHz crystal required for NTSC/PAL video timing reference (connected between CLKIN and XFB pins).
- FerriteBead component created (new pattern: `designator_prefix = "FB"`, 0805 size, BLM21PG221SN1D).

**Notes**:
- NDAA compliance: AT7456E by ZHONGKEWEI (Chinese company — may require review for NDAA)
- SPI2 pins correctly mapped: PB13 (SCK), PB14 (MISO), PB15 (MOSI), PB12 (CS)
- Video signal wiring (camera→OSD, OSD→VTX) done in TASK-010
- LCSC part: C82351 (AT7456E)

---

## Priority 3: Connectors & Peripheral Wiring

### TASK-009: Wire Motor Outputs and ESC Telemetry ✅ COMPLETE
**Spec**: `specs/motors-esc.md`
**Files**: `src/tf405.ato`, `src/connectors.ato`
**Completed**: 2026-03-01
**Priority**: HIGH - Critical for motor control
**Dependencies**: TASK-001 (TIM8 motor pins), TASK-002 (VBAT, current sense)

**Implementation Summary**:
- **Motor outputs**: 4x TIM8 channels wired from MCU to ESC connector
  - `mcu.pc6 ~ esc_conn.m1` (TIM8_CH1 → Motor 1)
  - `mcu.pc7 ~ esc_conn.m2` (TIM8_CH2 → Motor 2)
  - `mcu.pc8 ~ esc_conn.m3` (TIM8_CH3 → Motor 3)
  - `mcu.pc9 ~ esc_conn.m4` (TIM8_CH4 → Motor 4)
- **ESC telemetry**: `mcu.pa1 ~ esc_conn.telem` (UART4_RX, half-duplex)
- **Current sense**: `esc_conn.curr ~ power.curr_in` (feeds existing 1kΩ + 100nF RC filter → PC1 ADC)
- **ESC power**: `esc_conn.vbat ~ power.vbat` + `esc_conn.gnd ~ power.gnd`
- No new components added (pure signal routing in tf405.ato)
- `ato build` passes cleanly, all 30 existing assertions still passing

**Discoveries**:
- Current sense filter (1kΩ + 100nF RC, fc~1.6kHz) already implemented in power.ato — only needed to wire `esc_conn.curr ~ power.curr_in`
- ESC connector definition in connectors.ato already had all 8 signals correctly defined
- No new assertions needed — this task is pure wiring with no passive components

**Notes**:
- TIM8 → DMA2 stream assignments per DMA2 errata workaround (ES0206 §2.1.10)
- Timer/DMA configuration is firmware-level, not hardware

---

### TASK-010: Wire Video Signal Path ✅ COMPLETE
**Spec**: `specs/video-vtx-misc.md` (line 4)
**File**: `src/tf405.ato`
**Completed**: 2026-03-01
**Priority**: HIGH - Critical for FPV operation
**Dependencies**: TASK-008 (OSD implementation)

**Implementation Summary**:
- **Analog video chain**: Camera → AT7456E OSD overlay → VTX (does NOT pass through MCU)
  - `cam_conn.video_out ~ osd.video_in` — Camera composite video → OSD VIN (pin 8)
  - `osd.video_out ~ vtx_conn.video_in` — OSD composited VOUT (pin 3) → VTX
- **Camera power**: 5V regulated from buck converter + ground
  - `cam_conn.v5 ~ power.rail_5v`
  - `cam_conn.gnd ~ power.gnd`
- **VTX power**: switchable VBAT via PINIO1 P-FET (AO3401A)
  - `vtx_conn.vbat_sw ~ power.vbat_sw` — allows Betaflight pit mode / VTX power cycling
  - `vtx_conn.gnd ~ power.gnd`
- **SmartAudio**: `vtx_conn.smart_audio ~ mcu.pc12` (UART5_TX, single-wire VTX control)
- No new components added (pure signal routing in tf405.ato)
- `ato build` passes cleanly, all 30 existing assertions still passing

**Acceptance Criteria** (all met):
- ✅ Complete analog video path: Camera → OSD → VTX
- ✅ Power and ground connected to camera/VTX connectors
- ✅ SmartAudio UART5 connected
- ✅ `ato build` compiles without errors

**Notes**:
- Video does NOT pass through MCU (analog only)
- 75Ω impedance matching required (PCB layout constraint, not enforceable in .ato)
- No new assertions needed — this task is pure wiring with no passive components

---

### TASK-011: Wire UART Connectors and Receiver ✅ COMPLETE
**Spec**: `specs/uarts-receiver.md`
**Files**: `src/tf405.ato`, `src/misc.ato`
**Completed**: 2026-03-01
**Priority**: HIGH - Critical for RC receiver and GPS
**Dependencies**: TASK-001 (UART pins), TASK-002 (power rails), TASK-012 (SBUS inverter)

**Implementation Summary**:
- **RX Connector (UART1)**: Wired to MCU via SBUS inverter path
  - `rx_conn.tx ~ mcu.pa9` (UART1_TX for receiver telemetry return)
  - `rx_conn.rx ~ sbus_inv.sbus_in` (RX signal → inverter input via 1kΩ gate resistor)
  - `sbus_inv.uart_rx ~ mcu.pa10` (Inverter drain → UART1_RX)
  - Direct CRSF/ELRS path: solder bridge bypasses inverter (PCB layout decision)
  - Power: `rx_conn.v5 ~ power.rail_5v`, `rx_conn.gnd ~ power.gnd`
- **GPS Connector (UART2 + I2C1)**: Full GPS + magnetometer support
  - `gps_conn.tx ~ mcu.pa2` (UART2_TX), `gps_conn.rx ~ mcu.pa3` (UART2_RX)
  - `gps_conn.scl ~ mcu.pb8` (I2C1_SCL), `gps_conn.sda ~ mcu.pb9` (I2C1_SDA)
  - I2C1 bus pullups (4.7kΩ) already in baro module — shared bus
  - Power: `gps_conn.v5 ~ power.rail_5v`, `gps_conn.gnd ~ power.gnd`
- **Spare Connector (UART3)**: General-purpose UART
  - `spare_conn.tx ~ mcu.pb10` (UART3_TX), `spare_conn.rx ~ mcu.pb11` (UART3_RX)
  - Power: `spare_conn.v5 ~ power.rail_5v`, `spare_conn.gnd ~ power.gnd`
- **Ground connections added** for all misc modules (LED, beeper, LED strip, camera control)
- No new components (pure wiring); SBUS inverter components from TASK-012
- `ato build` passes cleanly, all 32 assertions passing

**Also completed as part of this task**:
- TASK-012 (SBUS inverter): implemented as prerequisite blocker
- TASK-006 (GPS I2C routing): GPS connector I2C1 SCL/SDA wired to MCU
- TASK-018 partial: all remaining ground connections added (LED, beeper, LED strip, cam_ctrl, sbus_inv, rx_conn, gps_conn, spare_conn)

**Discoveries**:
- In atopile, module instances must be created (`= new`) before their signals are referenced
- SBUS inverter permanently in signal path (RX connector → inverter → PA10); solder bridge for direct bypass is a PCB layout feature, not modeled in .ato
- GPS connector I2C shares bus with BMP390 — pullups in baro module serve both devices

---

### TASK-011A: Fix SpareConnector Pin Definition ✅ COMPLETE
**Spec**: `specs/uarts-receiver.md` (line 15-16)
**File**: `src/connectors.ato`, `src/tf405.ato`
**Completed**: 2026-03-01
**Priority**: LOW - Minor spec compliance issue
**Dependencies**: None

**Implementation Summary**:
- Added `v5_2` and `gnd_2` signals to SpareConnector module for duplicate power/ground pins
- Full 6-pin JST-SH mapping: GND(1), 5V(2), TX3(3), RX3(4), 5V(5), GND(6)
- Duplicate signals wired in tf405.ato: `spare_conn.v5_2 ~ power.rail_5v`, `spare_conn.gnd_2 ~ power.gnd`
- Comments document the purpose: higher current capacity and lower impedance return path
- `ato build` passes cleanly, 84 components, 35 assertions all passing

**Notes**:
- Duplicate power/ground pins are modeled as separate signals (`v5_2`, `gnd_2`) since
  atopile signals represent unique nets. Both are wired to the same power rails.
- Physical pin assignment (which footprint pad maps to which signal) handled at PCB layout

---

### TASK-012: Implement SBUS Inverter Circuit ✅ COMPLETE
**Spec**: `specs/uarts-receiver.md` (lines 15-21)
**File**: `src/misc.ato`
**Completed**: 2026-03-01 (implemented as part of TASK-011)
**Priority**: MEDIUM - Needed only for SBUS protocol receivers
**Dependencies**: TASK-002 (3.3V rail)

**Implementation Summary**:
- **2N7002 N-Channel MOSFET (SOT-23)**: Custom component definition with Gate(1)/Source(2)/Drain(3) pinout
- **Gate resistor**: 1kΩ +/- 1% (limits gate inrush, ESD protection)
- **Drain pullup**: 10kΩ +/- 1% to 3.3V (sets idle-high output, ~330µA when FET on)
- **Circuit**: SBUS_IN → 1kΩ → Gate, Source → GND, Drain → 10kΩ pullup to VDD → UART1_RX
- **Inversion**: When input high → FET on → drain low; When input low → FET off → drain high
- **Solder bridge**: PCB layout feature — not modeled in .ato; both direct and inverted paths terminate at PA10
- 3 components total (2N7002 + 2 resistors), 2 passing assert constraints
- `ato build` passes cleanly, LCSC parts auto-resolved (C21190 for 1kΩ, C25804 for 10kΩ)

**Assertions Implemented (2/2 spec constraints)**:
- ✅ `r_gate.value within 900ohm to 1.1kohm`
- ✅ `r_pullup.value within 9.9kohm to 10.1kohm`

**Discoveries**:
- 2N7002 SOT-23 pinout: Gate(1), Source(2), Drain(3) — verified against ON Semiconductor datasheet
- Common-source inverter topology is standard for SBUS on F405 boards (no internal UART inversion)
- SBUS runs at 100kbaud inverted — 10kΩ pullup provides adequate rise time

**Notes**:
- NDAA compliance: 2N7002 widely sourced (ON Semi, Nexperia — US/European companies, clean)

---

## Priority 4: Miscellaneous Peripherals & Polish

### TASK-013: Implement Status LED ✅ COMPLETE
**Spec**: `specs/video-vtx-misc.md` (line 1)
**File**: `src/misc.ato`
**Completed**: 2026-03-01
**Priority**: LOW - Nice to have for debugging
**Dependencies**: TASK-002 (3.3V rail)

**Implementation Summary**:
- **LED_0603 custom component**: green 0603 SMD LED (19-217/GHC-YR1S2/3T, Everlight)
  - Footprint: `LED_0603_1608Metric` (standard KiCad library)
  - Pin 1 (cathode), Pin 2 (anode)
- **Current limiting resistor**: 1kΩ +/- 1% (yields ~1.3mA @ 3.3V with Vf~2.0V green LED)
- **Active-low wiring**: VDD → 1kΩ → LED anode; LED cathode → GPIO (PB0)
  - GPIO sinks current when driven low → LED turns on
  - GPIO high → no current → LED off
- **Ground connection**: `led.gnd ~ power.gnd` already present in tf405.ato (added in TASK-011)
- 2 components total (LED + resistor), 1 passing assert constraint
- `ato build` passes cleanly, 33 total assertions passing

**Assertions Implemented (1/1 spec constraints)**:
- ✅ `r_led.value within 900ohm to 1.1kohm`

**Notes**:
- Top-level wiring already complete: `led.gpio ~ mcu.pb0`, `led.vdd ~ power.rail_3v3`, `led.gnd ~ power.gnd`
- NDAA compliance: Everlight (Taiwanese company, clean)

---

### TASK-014: Implement Beeper Circuit ✅ COMPLETE
**Spec**: `specs/video-vtx-misc.md` (line 2)
**File**: `src/misc.ato`
**Completed**: 2026-03-01
**Priority**: LOW - Nice to have for lost model alarm
**Dependencies**: TASK-002 (5V rail for buzzer)

**Implementation Summary**:
- **Buzzer_MLT8530 custom component**: SMD passive piezo buzzer (8.5x8.5x3mm)
  - Footprint: `Buzzer_Beeper:Buzzer_SMD_MLT-8530_8.5x8.5mm` (standard KiCad library)
  - LCSC: C94599, resonant freq 2.7kHz, 80dB SPL
  - Pin 1 (positive), Pin 2 (negative)
- **2N7002 N-FET low-side driver**: SOT-23 (already defined in misc.ato)
  - Common-source topology: FET switches buzzer ground path
  - 5V → buzzer+ → buzzer- → FET drain → GND
- **Gate resistor**: 10kΩ +/- 1% (limits gate inrush, ESD protection)
  - 10kΩ adequate since buzzer PWM is only ~4kHz (rise time not critical)
- **Top-level wiring**: `beeper.vdd ~ power.rail_5v` added in tf405.ato
  - `beeper.gpio ~ mcu.pb1` and `beeper.gnd ~ power.gnd` already present
- 3 components total (MLT-8530 + 2N7002 + 10kΩ resistor), 1 passing assert constraint
- `ato build` passes cleanly, 34 total assertions passing

**Assertions Implemented (1/1 spec constraints)**:
- ✅ `r_gate.value within 9.9kohm to 10.1kohm`

**Discoveries**:
- MLT-8530 is the standard passive buzzer on Betaflight FCs — compact (8.5mm), cheap (~$0.10), 80dB
- Buzzer coil resistance is 12±3Ω, drawing ~95mA at 5V — well within 2N7002's 200mA rating
- Betaflight firmware handles square-wave generation for passive buzzer (~4kHz tone)
- BEEPER_INVERTED = ON in Betaflight config (PB1 high → FET on → buzzer sounds)

**Notes**:
- NDAA compliance: MLT-8530 by Jiangsu Huaneng Electronics (Chinese company — may require NDAA review)
- No flyback diode needed: piezo buzzer is capacitive (not inductive like solenoid buzzers)

---

### TASK-015: Implement LED Strip Output ✅ COMPLETE
**Spec**: `specs/video-vtx-misc.md` (line 3)
**File**: `src/misc.ato`
**Completed**: 2026-03-01
**Priority**: LOW - Optional racing/night flying feature
**Dependencies**: TASK-002 (5V rail for WS2812)

**Implementation Summary**:
- **330Ω series resistor** on WS2812 data line (MCU GPIO → 330Ω → solder pad)
  - Dampens signal ringing from impedance mismatch between MCU GPIO (~40Ω) and LED strip cable
  - Standard value on WS2812 reference designs
  - LCSC C23138 (330Ω 0603, 1% tolerance)
- **Module signals**: `data` (MCU-side, PB6/TIM4_CH1), `pad` (solder pad output), `vdd` (5V), `gnd`
- **Top-level wiring**: already complete — `led_strip.data ~ mcu.pb6`, `led_strip.vdd ~ power.rail_5v`, `led_strip.gnd ~ power.gnd`
- 1 component (330Ω resistor), 1 passing assert constraint
- `ato build` passes cleanly, 35 total assertions passing

**Assertions Implemented (1/1 spec constraints)**:
- ✅ `r_data.value within 300ohm to 360ohm`

**Discoveries**:
- Ground connection was already added in TASK-011 (not missing as originally noted in plan)
- Module now exposes separate `data` (MCU input) and `pad` (connector output) signals to make the series resistor explicit in the signal path

**Notes**:
- PB6 is TIM4_CH1 for DMA-based WS2812 timing (firmware-level)
- No additional decoupling needed — 5V rail supplied directly to LED strip connector

---

### TASK-016: Implement Camera Control Output ✅ COMPLETE
**Spec**: `specs/video-vtx-misc.md` (line 6)
**File**: `src/misc.ato`
**Completed**: 2026-03-01
**Priority**: LOW - Optional OSD joystick emulation
**Dependencies**: None (just solder pad)

**Implementation Summary**:
- **CameraControl module**: PB3 GPIO → solder pad direct passthrough
  - `gpio` signal (MCU-side, PB3) connected directly to `pad` signal (solder pad output)
  - No passive components needed — camera OSD input is high-impedance
  - Betaflight camera control generates PWM-like pulse widths to emulate joystick commands
- **Top-level wiring** already complete: `cam_ctrl.gpio ~ mcu.pb3`, `cam_ctrl.gnd ~ power.gnd`
- 0 new components (pure signal routing), no assert constraints per spec
- `ato build` passes cleanly, 35 total assertions still passing

**Discoveries**:
- Ground connection was already present in tf405.ato (added in TASK-011), not missing as plan noted
- Camera control is a direct GPIO passthrough — no series resistor or protection needed since
  the cable is short (on-board solder pad to camera) and camera input is high-impedance

---

### TASK-017: Implement PA4 Servo/Detonator Pad ✅ COMPLETE
**Spec**: `specs/video-vtx-misc.md` (line 7)
**File**: `src/misc.ato`, `src/tf405.ato`
**Completed**: 2026-03-01
**Priority**: LOW - Optional servo/pyro channel
**Dependencies**: None

**Implementation Summary**:
- **PA4Breakout module**: PA4 GPIO → solder pad direct passthrough
  - `gpio` signal (MCU-side, PA4) connected directly to `pad` signal (solder pad output)
  - No passive components needed — servo signal is low-frequency PWM (~50Hz) or DC analog
  - PA4 is DAC_OUT1 (12-bit analog output) and TIM2_CH1 (PWM capable)
  - Betaflight uses this for servo output or pyro/detonator trigger
- **Top-level wiring**: `pa4_out.gpio ~ mcu.pa4`, `pa4_out.gnd ~ power.gnd`
- 0 new components (pure signal routing), no assert constraints per spec
- `ato build` passes cleanly, 35 total assertions still passing

**Discoveries**:
- Follows exact same pattern as CameraControl — direct GPIO-to-pad breakout
- Ground connection included for reference plane continuity on solder pad

---

## Priority 5: System-Wide Validation & Constraints

### TASK-018: Add All Missing Ground Connections ✅ COMPLETE
**Spec**: All module specs
**File**: `src/tf405.ato`
**Completed**: 2026-03-01 (incrementally across TASK-003 through TASK-011)
**Priority**: CRITICAL - Required for electrical continuity
**Dependencies**: TASK-002 (power system ground reference)

**Implementation Summary**:
All ground connections now present in tf405.ato:
- ✅ `imu.gnd ~ power.gnd` (TASK-004)
- ✅ `baro.gnd ~ power.gnd` (TASK-005)
- ✅ `flash.gnd ~ power.gnd` (TASK-007)
- ✅ `osd.gnd ~ power.gnd` (TASK-008)
- ✅ `usb.gnd ~ power.gnd` (TASK-003)
- ✅ `led.gnd ~ power.gnd` (TASK-011)
- ✅ `beeper.gnd ~ power.gnd` (TASK-011)
- ✅ `led_strip.gnd ~ power.gnd` (TASK-011)
- ✅ `cam_ctrl.gnd ~ power.gnd` (TASK-011)
- ✅ `sbus_inv.gnd ~ power.gnd` (TASK-011)
- ✅ `esc_conn.gnd ~ power.gnd` (TASK-009)
- ✅ `rx_conn.gnd ~ power.gnd` (TASK-011)
- ✅ `gps_conn.gnd ~ power.gnd` (TASK-011)
- ✅ `spare_conn.gnd ~ power.gnd` (TASK-011)
- ✅ `cam_conn.gnd ~ power.gnd` (TASK-010)
- ✅ `vtx_conn.gnd ~ power.gnd` (TASK-010)

---

### TASK-019: Implement All Assert Constraints ✅ COMPLETE
**Spec**: All module specs (lines marked "Assert Constraints")
**Files**: All `.ato` files
**Completed**: 2026-03-01 (incrementally across TASK-001 through TASK-015)
**Priority**: CRITICAL - Required for design validation
**Dependencies**: All component implementation tasks

**Implementation Summary**:
All feasible assert constraints were implemented incrementally across TASK-001 through TASK-015.

**35 active asserts passing** (all passive component value constraints):
- Power: 5 asserts (r_vbat_top, r_vbat_bot, r_curr_filter, c_curr_filter, r_pinio_gate)
- MCU: 11 asserts (c_hse1, c_hse2, c_vcap1, c_vcap2, c_vdd1, c_vdda_bulk, c_vdda_bypass, r_boot0, r_nrst, c_nrst, r_boot1)
- IMU: 2 asserts (c_vdd, c_vddio)
- Baro: 4 asserts (c_vdd, c_vddio, r_scl_pullup, r_sda_pullup)
- Flash: 1 assert (c_vcc)
- OSD: 2 asserts (c_dvdd, c_avdd)
- USB: 5 asserts (r_cc1, r_cc2, r_dp, r_dm, c_vbus)
- SBUS Inverter: 2 asserts (r_gate, r_pullup)
- Misc: 3 asserts (r_led, r_gate [beeper], r_data [LED strip])

**9 voltage-level asserts NOT implementable** in atopile v0.2.69 (commented out with explanation):
- Power: rail_5v, rail_3v3, v_adc_vbat (3)
- IMU: vdd, vddio (2)
- Baro: vdd, vddio (2)
- Flash: vcc (1)
- OSD: dvdd, avdd (2) — note: plan listed 4 OSD asserts but only 2 are voltage-level

The atopile v0.2.69 solver only handles passive component values (capacitance, resistance).
Voltage-level assertions would require a SPICE-like simulation engine, which is not available.
All 9 voltage asserts are preserved as comments in source files for documentation.

**Acceptance Criteria** (met):
- ✅ All 35 feasible assert statements implemented and passing
- ✅ 9 voltage-level asserts documented as comments (v0.2.69 limitation)
- ✅ `ato build` validates all constraints successfully

---

## Priority 6: PCB Constraints & Manufacturing (Non-Code)

### TASK-020: Define PCB Layer Stackup ✅ COMPLETE
**Spec**: `specs/board-constraints.md` (implied)
**File**: `specs/pcb-stackup.md` (new)
**Completed**: 2026-03-01
**Priority**: HIGH - Required for USB impedance, video signals, power distribution
**Dependencies**: None (documentation task)

**Implementation Summary**:
- **4-layer stackup**: L1 Signal (1oz) / L2 GND plane (0.5oz) / L3 Power plane (0.5oz) / L4 Signal (1oz)
- **Standard JLCPCB 4-layer process**: 1.6mm total thickness, 2116 prepreg (127µm, εr≈4.3), 800µm core
- **USB 2.0 differential**: 90Ω ±10%, 0.20mm traces / 0.15mm gap, microstrip over L2 GND
- **Video 75Ω single-ended**: 0.30mm traces, microstrip over L2 GND
- **Power trace sizing**: VBAT/motor ≥2mm or copper pour (30A burst), 5V ≥0.5mm (3A), 3.3V ≥0.25mm
- **Via specs**: 0.3mm drill standard, 0.4mm for power, stitching vias ≤3mm spacing
- **DRC rules**: 5 mil min trace/space (JLCPCB standard), ENIG surface finish recommended
- **Component placement guidelines**: MP1584EN near ESC connector, MCU center, IMU at center of mass, BMP390 away from heat/airflow
- **Thermal management**: Thermal vias under AMS1117-3.3 tab and AT7456E exposed pad
- **Impedance calculations**: Microstrip formulas verified for actual stackup dimensions
- **Layout checklist**: 11-item checklist for layout engineer

**Acceptance Criteria** (all met):
- ✅ PCB stackup document created (`specs/pcb-stackup.md`)
- ✅ Impedance calculations documented (USB 90Ω diff, video 75Ω SE)
- ✅ Manufacturer DFM rules specified (JLCPCB 4-layer standard)

**Notes**:
- This is NOT an atopile implementation task — purely documentation
- No longer blocks PCB layout phase
- Trace widths are approximations; must verify with manufacturer's actual stackup using field solver

---

### TASK-021: Define Physical Board Constraints ✅ COMPLETE
**Spec**: `specs/board-constraints.md` (lines 3-6)
**File**: `specs/board-mechanical.md` (new)
**Completed**: 2026-03-01
**Priority**: MEDIUM - Required for drone frame compatibility
**Dependencies**: None

**Implementation Summary**:
- **PCB outline**: 36.0 mm x 36.0 mm with 1.0 mm corner radii
- **Mounting holes**: 30.5 mm x 30.5 mm pattern, 3.2 mm (M3 clearance), 7.0 mm keep-out diameter
- **Mounting hole coordinates**: (2.75, 2.75), (33.25, 2.75), (2.75, 33.25), (33.25, 33.25) from bottom-left origin
- **Component height restrictions**: Documented per zone (top: 2.0-8.0 mm by area, bottom: 0-1.5 mm)
- **Tall component inventory**: USB-C (3.31 mm), JST-SH (4.25 mm), buzzer (3.0 mm), electrolytics (7.7 mm)
- **Connector placement**: Edge assignment map (rear=ESC/RX/USB, left=GPS/Spare, right=VTX/Camera, front=clear)
- **Solder pad placement**: SWD debug pads, GPIO breakout pads (LED strip, camera control, PA4), SBUS selection jumper
- **Keep-out zones**: Mounting holes (7.0 mm dia), IMU isolation (3.0 mm), baro thermal isolation (≥10 mm from buck), buck converter zone, USB differential pair (0.5 mm clearance)
- **Edge.Cuts geometry**: Full coordinate table for KiCad board outline (4 lines + 4 arcs)
- **Fiducial specification**: 3 asymmetric fiducials, 1.0 mm copper / 2.0 mm mask opening
- **Silkscreen markings**: Board name, version, pin labels, motor labels, polarity indicators, front arrow
- **Weight estimate**: ~6-8 g (bare board ~3.8 g + components ~2-4 g), within 8 g target

**Acceptance Criteria** (all met):
- ✅ Mechanical drawing/specification created (`specs/board-mechanical.md`)
- ✅ PCB outline with KiCad Edge.Cuts coordinates
- ✅ Mounting hole pattern with keep-out zones
- ✅ Component height restrictions documented
- ✅ Connector placement constraints defined
- ✅ Keep-out zones specified for all critical areas
- ✅ `ato build` still passes (no regressions — documentation task only)

**Notes**:
- This is NOT an atopile implementation task — purely documentation for PCB layout
- Complements TASK-020 (pcb-stackup.md) with physical/mechanical constraints
- Electrolytic caps (7.7 mm) may need replacement with ceramic alternatives for tight stacks

---

### TASK-022: Create Weight Budget
**Spec**: `specs/board-constraints.md` (line 6, target ≤8g)
**File**: Create new `WEIGHT_BUDGET.md`
**Current State**: Not tracked
**Priority**: LOW - Informational only
**Dependencies**: All component implementation tasks

**Required Documentation**:
- BOM with component masses
- PCB mass estimate
- Total assembly mass
- Margin to 8g target

**Acceptance Criteria**:
- Weight budget spreadsheet created
- All component masses documented

**Notes**:
- This is a tracking/verification task, not implementation

---

## Summary Statistics

**Total Tasks**: 23 (added TASK-011A for SpareConnector fix)
**Critical Tasks**: 4 (TASK-001, 002, 018, 019)
**High Priority**: 10 tasks
**Medium Priority**: 4 tasks
**Low Priority**: 5 tasks (includes TASK-011A)

**Current Completion Status by Module**:
- Power: **100%** (TASK-002 complete — 20 components, 5 asserts, ato build passes)
- MCU: **100%** (TASK-001 complete — 18 components, 11 asserts, ato build passes)
- IMU: **100%** (TASK-004 complete — 3 components, 2 asserts, ato build passes)
- Barometer: **100%** (TASK-005 complete — 5 components, 4 asserts, ato build passes)
- Flash: **100%** (TASK-007 complete — 4 components, 1 assert, ato build passes)
- OSD: **100%** (TASK-008 complete — 10 components, 2 asserts, ato build passes)
- USB: **100%** (TASK-003 complete — 10 components, 5 asserts, ato build passes)
- Motor/ESC: **100%** (TASK-009 complete — all 8 ESC pins wired, ato build passes)
- Video Path: **100%** (TASK-010 complete — Camera→OSD→VTX wired, SmartAudio on UART5, ato build passes)
- UART/RX: **100%** (TASK-011 complete — all 3 UART connectors + SBUS inverter + GPS I2C wired, ato build passes)
- SBUS Inverter: **100%** (TASK-012 complete — 3 components, 2 asserts, ato build passes)
- I2C Bus: **100%** (TASK-006 complete — pullups in baro, GPS I2C routing in TASK-011)
- Ground Connections: **100%** (TASK-018 complete — all 16 modules grounded)
- Misc: **100%** (LED + beeper + LED strip + camera control + PA4 breakout all complete)

**Component Package Availability**:
- Available on packages.atopile.io: ~10-15% (USB connectors, possibly some passives)
- Custom implementation required: ~85-90% (all custom ICs)
- Generic passives (Capacitor, Resistor) work with custom component defs + auto-selection

**Estimated Work Remaining**: ~10% of circuit implementation (3 misc peripherals) + PCB specs (documentation only)

**Code Audit Results**:
- 0 TODO comments remaining (all resolved)
- 0 commented-out connections (sbus_inv.uart_rx now active)
- 35/44 assert statements implemented (MCU + Power + USB + IMU + Baro + Flash + OSD + SBUS inverter + LED + Beeper + LED strip; 8 voltage-level asserts not feasible in v0.2.69)
- 0 FIXME/HACK/PLACEHOLDER markers
- 0 connector definitions incomplete (SpareConnector fixed in TASK-011A)

---

## Critical Blockers

1. ~~**Missing ground connections**~~ ✅ RESOLVED (TASK-018 complete — all 16 modules grounded)
2. ~~**Misc peripheral stubs remain**~~ ✅ RESOLVED (all misc peripherals complete including TASK-017 PA4 breakout)
3. ~~**No PCB stackup defined**~~ ✅ RESOLVED (TASK-020 complete — `specs/pcb-stackup.md` with 4-layer stackup, impedance calculations, DFM rules)
4. ~~**GPS connector I2C routing missing**~~ ✅ RESOLVED (TASK-006 complete via TASK-011)
5. ~~**Connector wiring incomplete**~~ ✅ RESOLVED (all connectors now fully wired)

---

## Next Steps

**Recommended Implementation Order**:

1. **Week 1**: TASK-001, TASK-002 (MCU + Power foundation)
2. **Week 2**: TASK-003, TASK-018, TASK-006 (USB, grounds, I2C infrastructure)
3. **Week 3**: TASK-004, TASK-005, TASK-007, TASK-008 (All sensors)
4. **Week 4**: TASK-009, TASK-010, TASK-011 (Wiring: motors, video, UARTs)
5. **Week 5**: TASK-012 to TASK-017 (Misc peripherals)
6. **Week 6**: TASK-019 (All assert constraints - CRITICAL)
7. **Week 7**: TASK-020, TASK-021 (PCB specs for layout)
8. **Week 8**: First `ato build` validation, debug, iterate

**Build Validation Strategy**:
- After TASK-002: First `ato build` attempt (expect power module errors)
- After TASK-008: Second build (expect all core modules to parse)
- After TASK-017: Third build (expect full netlist generation)
- After TASK-019: Final validation (all constraints checked)

---

## Notes for Implementation

- **Check https://packages.atopile.io** before creating custom component definitions (but expect to create custom implementations for all major ICs)
- All specs exist and are comprehensive - use them as authoritative source
- The DMA2 errata workaround (TIM8 for motors) is correctly architected
- Current codebase is a well-structured skeleton - implementation is methodical, not exploratory
- No spec inconsistencies found - specs are internally consistent and complete
- Subagent analysis confirms all TODO comments are accurate and complete

---

## Verification Log

**2026-03-01 - Comprehensive Gap Analysis via 14 Parallel Subagents:**

Executed thorough verification using parallel Sonnet-level subagents to analyze each specification against implementation:

**Subagents Deployed:**
1. MCU core (specs/mcu-core.md vs src/mcu.ato) - VERIFIED
2. Power system (specs/power.md vs src/power.ato) - VERIFIED
3. IMU BMI270 (specs/imu-bmi270.md vs src/imu.ato) - VERIFIED
4. Barometer BMP390 (specs/baro-bmp390.md vs src/baro.ato) - VERIFIED
5. Flash W25Q128 (specs/flash-w25q128.md vs src/flash.ato) - VERIFIED
6. OSD AT7456E (specs/osd-at7456e.md vs src/osd.ato) - VERIFIED
7. USB-C (specs/usb-c.md vs src/usb.ato) - VERIFIED
8. Motors/ESC (specs/motors-esc.md vs src/*.ato) - VERIFIED
9. UARTs/Receiver (specs/uarts-receiver.md vs src/*.ato) - VERIFIED
10. Video/VTX/Misc (specs/video-vtx-misc.md vs src/misc.ato) - VERIFIED
11. Top-level wiring analysis (src/tf405.ato) - VERIFIED
12. TODO/FIXME/HACK/PLACEHOLDER search (all src/*.ato) - VERIFIED
13. Assert statement count (all src/*.ato vs all specs/*.md) - VERIFIED
14. Connector implementations (src/connectors.ato vs specs) - VERIFIED

**Key Verification Results:**
- ✅ TODO count: 43 confirmed (1 less than previously estimated)
- ✅ Assert statements: 0/44 confirmed (exact requirement verified from specs)
- ✅ Ground connections: 0/16+ confirmed missing
- ✅ FIXME/HACK/PLACEHOLDER: 0 confirmed (clean codebase)
- ✅ Connector implementations: 5/6 complete, SpareConnector incomplete (added TASK-011A)
- ✅ All existing plan tasks verified accurate - no regeneration needed
- ✅ Implementation percentages validated across all modules

**Findings:**
- Existing plan is remarkably accurate and current
- Only minor update needed: SpareConnector missing duplicate power pins
- All task descriptions match actual code state
- All spec requirements correctly captured in plan
- No hidden implementations discovered
- No spec inconsistencies found

**Search Strategy Validation:**
Each subagent used minimum 3 search strategies (grep exact name, grep related terms, file tree search) before concluding anything was missing. No false negatives detected.

**Conclusion:** Plan remains valid and accurate. Incremental update applied (corrected TODO count from 44→43, corrected MCU assert count from 13→11, added TASK-011A for SpareConnector, updated verification metadata).
