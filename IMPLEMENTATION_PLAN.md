# Flight Controller Implementation Plan

**Last Updated**: 2026-03-01 — TASK-008 (OSD AT7456E) completed

**Status**: TASK-001, TASK-002, TASK-003, TASK-004, TASK-005, TASK-007, and TASK-008 complete. MCU core (18 components, 11 asserts), power system (20 components, 5 asserts), USB-C interface (10 components, 5 asserts), IMU BMI270 (3 components, 2 asserts), Barometer BMP390 (5 components, 4 asserts), Flash W25Q128 (4 components, 1 assert), and OSD AT7456E (10 components, 2 asserts) fully implemented with clean `ato build`. 30 total assertions passing. Remaining tasks: connectors, wiring, misc peripherals.

**Project State**: Foundation + USB + Sensors + Flash + OSD complete — MCU, power, USB, IMU, baro, flash, and OSD modules implemented. 75 components total in BOM (37 unique). Build pipeline operational. I2C1 bus fully wired with pullups. All SPI buses have their ICs instantiated (SPI1=BMI270, SPI2=AT7456E, SPI3=W25Q128). Custom component patterns well-established for remaining tasks.

**Key Findings**:
- ~6 TODO comments remain (down from 43 — MCU, power, USB, IMU, baro, flash, and OSD TODOs resolved)
- 30/44 assert statements implemented (MCU + Power + USB + IMU + Baro + Flash + OSD modules)
- 3 voltage-level assertions (rail_5v, rail_3v3, v_adc_vbat) cannot be verified in atopile v0.2.69 — solver only handles passive component values, not computed voltages
- USB, IMU, baro, flash, and OSD grounds now connected; remaining 11 modules still missing ground
- Most connector wiring incomplete
- No atopile packages available for custom ICs (all custom-defined)
- SpareConnector incomplete: missing duplicate power pins per spec (should be 6-pin, only 4 signals defined)
- Power module exposes adc_vbat, adc_curr, pinio1, vbat_sw, usb_vbus, curr_in signals for top-level wiring
- atopile v0.2.69 supports alphanumeric pin names (`pin A4`) — useful for USB-C and other non-numeric pad names

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

### TASK-006: Implement I2C Bus Infrastructure (PARTIALLY COMPLETE)
**Spec**: `specs/baro-bmp390.md` (line 13), general I2C requirements
**File**: `src/baro.ato` (pullups), `src/tf405.ato` (GPS wiring)
**Current State**: I2C1 pullups implemented in baro module (TASK-005). GPS connector I2C routing still missing.
**Priority**: MEDIUM - GPS magnetometer support remaining
**Dependencies**: TASK-002 (3.3V rail)

**Remaining Implementation**:
- ~~I2C1 Bus Pullups~~ ✅ (done in TASK-005, inside Baro_BMP390 module)
- **GPS Connector I2C Routing** (still needed):
  - Connect `gps_conn.scl ~ mcu.pb8` (currently missing in tf405.ato)
  - Connect `gps_conn.sda ~ mcu.pb9` (currently missing in tf405.ato)

**Acceptance Criteria**:
- ✅ Pullup resistors instantiated (in baro module, bus-level)
- ✅ Assert statements for resistor values implemented in TASK-005
- GPS connector I2C signals wired to MCU I2C1
- `ato build` compiles without errors

**Notes**:
- Pullups in baro module are shared by BMP390 and external magnetometer (same bus)
- GPS connector wiring can be done in TASK-011 (UART connectors) since GPS also needs UART2

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

### TASK-009: Wire Motor Outputs and ESC Telemetry
**Spec**: `specs/motors-esc.md`
**Files**: `src/tf405.ato`, `src/connectors.ato`
**Current State**: ESC connector defined, motor pins defined, but NOT WIRED
**Priority**: HIGH - Critical for motor control
**Dependencies**: TASK-001 (TIM8 motor pins), TASK-002 (VBAT, current sense)

**Required Implementation**:
- Wire motor outputs in tf405.ato:
  - `mcu.pc6 ~ esc_conn.m1` (TIM8_CH1)
  - `mcu.pc7 ~ esc_conn.m2` (TIM8_CH2)
  - `mcu.pc8 ~ esc_conn.m3` (TIM8_CH3)
  - `mcu.pc9 ~ esc_conn.m4` (TIM8_CH4)

- Wire ESC telemetry:
  - `mcu.pa1 ~ esc_conn.telem` (UART4_RX)

- Wire current sense:
  - `esc_conn.curr ~ [current sense filter] ~ mcu.pc1` (implemented in TASK-002)

- Wire ESC power:
  - Uncomment/fix line 30 in tf405.ato: `power.vbat ~ esc_conn.vbat`
  - Add ground: `power.gnd ~ esc_conn.gnd`

**Acceptance Criteria**:
- All 4 motor outputs wired
- Telemetry UART wired
- Current sense path connected
- Power and ground connected
- `ato build` compiles without errors

**Notes**:
- TIM8 → DMA2 stream assignments per DMA2 errata workaround (ES0206 §2.1.10)
- Timer/DMA configuration is firmware-level, not hardware

---

### TASK-010: Wire Video Signal Path
**Spec**: `specs/video-vtx-misc.md` (line 4)
**File**: `src/tf405.ato`
**Current State**: Camera, OSD, VTX modules defined but video path NOT WIRED
**Priority**: HIGH - Critical for FPV operation
**Dependencies**: TASK-008 (OSD implementation)

**Required Implementation**:
- Wire camera to OSD:
  - `cam_conn.video_out ~ osd.video_in`

- Wire OSD to VTX:
  - `osd.video_out ~ vtx_conn.video_in`

- Wire camera/VTX power:
  - `cam_conn.v5 ~ power.rail_5v`
  - `cam_conn.gnd ~ power.gnd`
  - `vtx_conn.smart_audio ~ mcu.pc12` (UART5_TX)
  - VTX power needs PINIO1 switchable VBAT (see TASK-002)

**Acceptance Criteria**:
- Complete analog video path: Camera → OSD → VTX
- Power and ground connected to camera/VTX connectors
- SmartAudio UART5 connected
- `ato build` compiles without errors

**Notes**:
- Video does NOT pass through MCU (analog only)
- 75Ω impedance matching required (PCB layout constraint, not enforceable in .ato)

---

### TASK-011: Wire UART Connectors and Receiver
**Spec**: `specs/uarts-receiver.md`
**Files**: `src/tf405.ato`, `src/misc.ato`
**Current State**: Connectors defined, SBUS inverter stubbed, NO WIRING
**Priority**: HIGH - Critical for RC receiver and GPS
**Dependencies**: TASK-001 (UART pins), TASK-002 (power rails), TASK-012 (SBUS inverter)

**Required Implementation**:
- **RX Connector (UART1)**:
  - `rx_conn.rx1 ~ sbus_inv.sbus_in` (if using SBUS)
  - `sbus_inv.uart_rx ~ mcu.pa10` (uncomment line 100 in tf405.ato)
  - For direct CRSF/ELRS: `rx_conn.rx1 ~ mcu.pa10` (via solder bridge)
  - `rx_conn.tx1 ~ mcu.pa9`
  - `rx_conn.v5 ~ power.rail_5v`
  - `rx_conn.gnd ~ power.gnd`

- **GPS Connector (UART2 + I2C1)**:
  - `gps_conn.tx2 ~ mcu.pa2` (UART2_TX)
  - `gps_conn.rx2 ~ mcu.pa3` (UART2_RX)
  - I2C wiring done in TASK-006
  - `gps_conn.v5 ~ power.rail_5v`
  - `gps_conn.gnd ~ power.gnd`

- **Spare Connector (UART3)**:
  - `spare_conn.tx3 ~ mcu.pb10` (UART3_TX)
  - `spare_conn.rx3 ~ mcu.pb11` (UART3_RX)
  - `spare_conn.v5 ~ power.rail_5v`
  - `spare_conn.gnd ~ power.gnd`

- **VTX SmartAudio (UART5)** - already in TASK-010

**Acceptance Criteria**:
- All UART connectors wired to MCU
- Power and ground connected to all connectors
- SBUS inverter path configured (after TASK-012)
- `ato build` compiles without errors

**Notes**:
- UART4 (ESC telemetry) wired in TASK-009
- Solder bridge for SBUS vs direct selection (implemented in TASK-012)

---

### TASK-011A: Fix SpareConnector Pin Definition
**Spec**: `specs/uarts-receiver.md` (line 15-16)
**File**: `src/connectors.ato` (lines 31-36)
**Current State**: Only 4 signals defined, missing duplicate power pins
**Priority**: LOW - Minor spec compliance issue
**Dependencies**: None

**Required Implementation**:
- Add duplicate 5V pin (pin 5 per spec)
- Add duplicate GND pin (pin 6 per spec)
- Current: GND, 5V, TX3, RX3
- Should be: GND (pin 1), 5V (pin 2), TX3 (pin 3), RX3 (pin 4), 5V (pin 5), GND (pin 6)
- Alternatively: Document that duplicate pins are handled at connector level

**Acceptance Criteria**:
- SpareConnector matches 6-pin spec pinout
- Or add comment explaining duplicate power pin handling
- `ato build` compiles without errors

**Notes**:
- This is a minor issue - connector will function with current 4-signal definition
- Duplicate power/ground pins provide redundancy for higher current capacity

---

### TASK-012: Implement SBUS Inverter Circuit
**Spec**: `specs/uarts-receiver.md` (lines 7-8)
**File**: `src/misc.ato` (lines 31-33)
**Current State**: Module stub exists, circuit missing, power connected
**Priority**: MEDIUM - Needed only for SBUS protocol receivers
**Dependencies**: TASK-002 (3.3V rail)

**Required Implementation**:
- 2N7002 N-FET inverter circuit
- Gate resistor: 1kΩ from SBUS input
- Drain pull-up: 10kΩ to 3.3V
- Solder bridge for SBUS vs direct (CRSF/ELRS) selection

**Acceptance Criteria**:
- All components instantiated
- All 2 assert statements implemented:
  - `r_sbus_gate.value within 900ohm to 1.1kohm`
  - `r_sbus_pullup.value within 9.9kohm to 10.1kohm`
- Solder bridge mechanism defined
- `ato build` compiles without errors

**Notes**:
- Only needed for SBUS receivers; CRSF/ELRS use direct connection
- Alternative: Make this optional via solder bridge only, no component population for CRSF users

---

## Priority 4: Miscellaneous Peripherals & Polish

### TASK-013: Implement Status LED
**Spec**: `specs/video-vtx-misc.md` (line 1)
**File**: `src/misc.ato` (line 8)
**Current State**: Module stub, GPIO connected (PB0), power connected, ground missing
**Priority**: LOW - Nice to have for debugging
**Dependencies**: TASK-002 (3.3V rail)

**Required Implementation**:
- LED component (standard 0603 or 0805 SMD)
- Current limiting resistor: 1kΩ (for ~1.5mA @ 3.3V)
- Fix missing ground connection: `led.gnd ~ power.gnd` in tf405.ato

**Acceptance Criteria**:
- LED and resistor instantiated
- Assert statement for resistor value:
  - `r_led.value within 900ohm to 1.1kohm`
- Ground connection added
- `ato build` compiles without errors

**Notes**:
- Already wired in tf405.ato lines 84-86 (GPIO and power)

---

### TASK-014: Implement Beeper Circuit
**Spec**: `specs/video-vtx-misc.md` (line 2)
**File**: `src/misc.ato` (line 13)
**Current State**: Module stub, GPIO connected (PB1), ground missing
**Priority**: LOW - Nice to have for lost model alarm
**Dependencies**: TASK-002 (5V rail for buzzer)

**Required Implementation**:
- 2N7002 N-FET gate driver
- Gate resistor: 10kΩ from PB1
- Passive buzzer on 5V rail (drain of FET)
- Fix missing ground connection: `beeper.gnd ~ power.gnd` in tf405.ato

**Acceptance Criteria**:
- N-FET and resistor instantiated
- Buzzer component defined
- Ground connection added
- `ato build` compiles without errors

**Notes**:
- Already wired in tf405.ato lines 88-89 (GPIO only)

---

### TASK-015: Implement LED Strip Output
**Spec**: `specs/video-vtx-misc.md` (line 3)
**File**: `src/misc.ato` (line 19)
**Current State**: Module stub, GPIO and power connected (PB6), ground missing
**Priority**: LOW - Optional racing/night flying feature
**Dependencies**: TASK-002 (5V rail for WS2812)

**Required Implementation**:
- Series resistor: 330Ω on data line
- Fix missing ground connection: `led_strip.gnd ~ power.gnd` in tf405.ato

**Acceptance Criteria**:
- Resistor instantiated
- Assert statement for resistor value:
  - `r_led_strip.value within 300ohm to 360ohm`
- Ground connection added
- `ato build` compiles without errors

**Notes**:
- Already wired in tf405.ato lines 91-93 (GPIO and power)
- PB6 is TIM4_CH1 for WS2812 timing (firmware-level)

---

### TASK-016: Implement Camera Control Output
**Spec**: `specs/video-vtx-misc.md` (line 6)
**File**: `src/misc.ato` (line 24)
**Current State**: Module stub, GPIO connected (PB3), ground missing
**Priority**: LOW - Optional OSD joystick emulation
**Dependencies**: None (just solder pad)

**Required Implementation**:
- Simple solder pad breakout for PB3
- Fix missing ground connection: `cam_ctrl.gnd ~ power.gnd` in tf405.ato

**Acceptance Criteria**:
- Test pad component defined
- Ground connection added
- `ato build` compiles without errors

**Notes**:
- Already wired in tf405.ato lines 95-96 (GPIO only)

---

### TASK-017: Implement PA4 Servo/Detonator Pad
**Spec**: `specs/video-vtx-misc.md` (line 7)
**File**: `src/mcu.ato` (line 73), needs breakout
**Current State**: Pin defined, no connector or breakout
**Priority**: LOW - Optional servo/pyro channel
**Dependencies**: None

**Required Implementation**:
- Solder pad or small connector for PA4 breakout
- Optional pull-down or protection diode depending on use case

**Acceptance Criteria**:
- Test pad or connector component defined
- Wired in tf405.ato
- `ato build` compiles without errors

**Notes**:
- PA4 is DAC-capable (TIM2_CH1 or DAC_OUT1)

---

## Priority 5: System-Wide Validation & Constraints

### TASK-018: Add All Missing Ground Connections
**Spec**: All module specs
**File**: `src/tf405.ato`
**Current State**: Systematic pattern - all peripheral modules declare `gnd` pins but don't connect them
**Priority**: CRITICAL - Required for electrical continuity
**Dependencies**: TASK-002 (power system ground reference)

**Required Implementation**:
Add ground connections in tf405.ato for all modules:
- ~~`imu.gnd ~ power.gnd`~~ (done in TASK-004)
- ~~`baro.gnd ~ power.gnd`~~ (done in TASK-005)
- ~~`flash.gnd ~ power.gnd`~~ (done in TASK-007)
- `osd.gnd ~ power.gnd`
- `usb.gnd ~ power.gnd`
- `led.gnd ~ power.gnd`
- `beeper.gnd ~ power.gnd`
- `led_strip.gnd ~ power.gnd`
- `cam_ctrl.gnd ~ power.gnd`
- `sbus_inv.gnd ~ power.gnd`
- `esc_conn.gnd ~ power.gnd`
- `rx_conn.gnd ~ power.gnd`
- `gps_conn.gnd ~ power.gnd`
- `spare_conn.gnd ~ power.gnd`
- `cam_conn.gnd ~ power.gnd`
- `vtx_conn.gnd ~ power.gnd`

**Acceptance Criteria**:
- All module ground pins connected to system ground
- `ato build` compiles without errors

**Notes**:
- Ground may be implicitly handled by atopile framework, but explicit connections are clearer

---

### TASK-019: Implement All Assert Constraints
**Spec**: All module specs (lines marked "Assert Constraints")
**Files**: All `.ato` files
**Current State**: ZERO assert statements in entire codebase (0/44+ implemented)
**Priority**: CRITICAL - Required for design validation
**Dependencies**: All component implementation tasks

**Required Implementation** (Total: 44+ assertions):

**Power System (9 asserts)** - `src/power.ato`:
- `rail_5v within 4.75V to 5.25V`
- `rail_3v3 within 3.2V to 3.4V`
- `r_vbat_top.value within 9.9kohm to 10.1kohm`
- `r_vbat_bot.value within 990ohm to 1.01kohm`
- `v_adc_vbat within 0V to 3.3V`
- `r_curr_filter.value within 900ohm to 1.1kohm`
- `c_curr_filter.value within 80nF to 120nF`
- `r_pinio_gate.value within 9.9kohm to 10.1kohm`

**MCU (13 asserts)** - `src/mcu.ato`:
- `c_hse1.value within 15pF to 22pF`
- `c_hse2.value within 15pF to 22pF`
- `c_vcap1.value within 2.0uF to 2.4uF`
- `c_vcap2.value within 2.0uF to 2.4uF`
- `c_vdd.value within 80nF to 120nF`
- `c_vdda_bulk.value within 0.9uF to 1.1uF`
- `c_vdda_bypass.value within 80nF to 120nF`
- `r_boot0.value within 9.9kohm to 10.1kohm`
- `r_nrst.value within 9.9kohm to 10.1kohm`
- `c_nrst.value within 80nF to 120nF`
- `r_boot1.value within 9.9kohm to 10.1kohm`

**IMU (4 asserts)** - `src/imu.ato`:
- `vdd within 1.71V to 3.6V`
- `vddio within 1.2V to 3.6V`
- `c_vdd.value within 80nF to 120nF`
- `c_vddio.value within 80nF to 120nF`

**Barometer (6 asserts)** - `src/baro.ato`:
- `vdd within 1.7V to 3.6V`
- `vddio within 1.2V to 3.6V`
- `c_vdd.value within 80nF to 120nF`
- `c_vddio.value within 80nF to 120nF`
- `r_scl_pullup.value within 4.5kohm to 4.9kohm`
- `r_sda_pullup.value within 4.5kohm to 4.9kohm`

**Flash (2 asserts)** - `src/flash.ato`:
- `vcc within 2.7V to 3.6V`
- `c_vcc.value within 80nF to 120nF`

**OSD (4 asserts)** - `src/osd.ato`:
- `dvdd within 3.0V to 3.6V`
- `avdd within 3.0V to 3.6V`
- `c_dvdd.value within 80nF to 120nF`
- `c_avdd.value within 80nF to 120nF`

**USB (5 asserts)** - `src/usb.ato`:
- `r_cc1.value within 4.9kohm to 5.3kohm`
- `r_cc2.value within 4.9kohm to 5.3kohm`
- `r_dp.value within 20ohm to 24ohm`
- `r_dm.value within 20ohm to 24ohm`
- `c_vbus.value within 4.0uF to 5.5uF`

**SBUS Inverter (2 asserts)** - `src/misc.ato`:
- `r_sbus_gate.value within 900ohm to 1.1kohm`
- `r_sbus_pullup.value within 9.9kohm to 10.1kohm`

**Misc (3 asserts)** - `src/misc.ato`:
- `r_led.value within 900ohm to 1.1kohm`
- `r_led_strip.value within 300ohm to 360ohm`

**Acceptance Criteria**:
- All 44+ assert statements implemented
- `ato build` validates all constraints successfully

**Notes**:
- This is the SINGLE MOST CRITICAL gap in the current implementation
- Without asserts, design validation is impossible

---

## Priority 6: PCB Constraints & Manufacturing (Non-Code)

### TASK-020: Define PCB Layer Stackup
**Spec**: `specs/board-constraints.md` (implied, currently missing)
**File**: Create new `specs/pcb-stackup.md`
**Current State**: Completely undefined
**Priority**: HIGH - Required for USB impedance, video signals, power distribution
**Dependencies**: None (documentation task)

**Required Specification**:
- Layer count (recommend 4-layer: Sig/GND/PWR/Sig)
- Copper weight (recommend 1oz outer, 0.5oz inner)
- Prepreg thickness
- Core thickness
- Target impedances:
  - USB D+/D-: 90Ω differential
  - Video signals: 75Ω single-ended
- Minimum trace/space rules
- Via specifications

**Acceptance Criteria**:
- PCB stackup document created
- Impedance calculations documented
- Manufacturer DFM rules specified

**Notes**:
- This is NOT an atopile implementation task - purely documentation
- Blocks PCB layout phase

---

### TASK-021: Define Physical Board Constraints
**Spec**: `specs/board-constraints.md` (lines 3-6)
**File**: Update existing spec or create mechanical drawing
**Current State**: Documented but not enforced
**Priority**: MEDIUM - Required for drone frame compatibility
**Dependencies**: None

**Required Specification**:
- PCB outline: 36mm x 36mm
- Mounting holes: 30.5mm x 30.5mm M3 pattern
- Component height restrictions (if any)
- Connector placement constraints
- Keep-out zones

**Acceptance Criteria**:
- Mechanical drawing created (DXF or similar)
- PCB outline constraint file for layout tool

**Notes**:
- Cannot be enforced in atopile .ato files
- Required for PCB layout phase

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
- Motor/ESC: ~20% (connector defined, not wired)
- UART/RX: ~20% (connectors defined, not wired)
- Video/Misc: ~30% (partial wiring, circuits missing)

**Component Package Availability**:
- Available on packages.atopile.io: ~10-15% (USB connectors, possibly some passives)
- Custom implementation required: ~85-90% (all custom ICs)
- Generic passives (Capacitor, Resistor) work with custom component defs + auto-selection

**Estimated Work Remaining**: ~50% of circuit implementation + ~50% of constraint validation

**Code Audit Results**:
- ~6 TODO comments remaining (down from 43)
- 1 commented-out connection (intentional: sbus_inv.uart_rx in tf405.ato)
- 30/44 assert statements implemented (MCU + Power + USB + IMU + Baro + Flash + OSD modules; 8 voltage-level asserts not feasible in v0.2.69)
- 0 FIXME/HACK/PLACEHOLDER markers
- 1 connector definition incomplete (SpareConnector missing duplicate power pins)

---

## Critical Blockers

1. **Missing ground connections** - Systematic issue across 12 remaining modules (TASK-018)
2. **Misc peripheral stubs remain** - LED, beeper, LED strip, camera control, SBUS inverter still TODO
3. **No PCB stackup defined** - Blocks layout for impedance-critical signals (TASK-020)
4. **GPS connector I2C routing missing** - GPS magnetometer I2C1 wiring needed (remaining TASK-006)
5. **Connector wiring incomplete** - ESC, RX, GPS, spare, camera, VTX connectors not wired

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
