# Flight Controller Implementation Plan

**Last Updated**: 2026-03-01 — TASK-003 (USB-C Interface) completed

**Status**: TASK-001, TASK-002, and TASK-003 complete. MCU core (18 components, 11 asserts), power system (20 components, 5 asserts), and USB-C interface (10 components, 5 asserts) fully implemented with clean `ato build`. 21 total assertions passing. Remaining tasks: sensors, peripherals, wiring, constraints.

**Project State**: Foundation + USB complete — MCU, power, and USB modules implemented. 55 components total in BOM (29 unique). Build pipeline operational. Custom component patterns well-established for remaining ICs.

**Key Findings**:
- ~20 TODO comments remain (down from 43 — MCU, power, and USB TODOs resolved)
- 21/44 assert statements implemented (MCU + Power + USB modules)
- 3 voltage-level assertions (rail_5v, rail_3v3, v_adc_vbat) cannot be verified in atopile v0.2.69 — solver only handles passive component values, not computed voltages
- USB ground now connected (usb.gnd ~ power.gnd); remaining 15 modules still missing ground
- Most connector wiring incomplete
- No atopile packages available for custom ICs (BMI270, BMP390, W25Q128, AT7456E)
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

### TASK-004: Implement IMU BMI270
**Spec**: `specs/imu-bmi270.md`
**File**: `src/imu.ato` (lines 12-14)
**Current State**: SPI1 connections complete (PA5/PA6/PA7/PC4/PC5), component missing, ground missing
**Priority**: HIGH - Critical for flight control
**Dependencies**: TASK-001 (SPI1), TASK-002 (3.3V rail)

**Required Implementation**:
- BMI270 component with LGA-14 footprint (custom - no atopile package available)
- VDD decoupling: 100nF
- VDDIO decoupling: 100nF (or tie to VDD if using 3.3V for both)
- Optional: 10kΩ pull-up on CS line
- Fix missing ground connection: `imu.gnd ~ power.gnd` in tf405.ato

**Acceptance Criteria**:
- Component instantiated with correct footprint
- All 4 assert statements implemented:
  - `vdd within 1.71V to 3.6V`
  - `vddio within 1.2V to 3.6V`
  - `c_vdd.value within 80nF to 120nF`
  - `c_vddio.value within 80nF to 120nF`
- Ground connection added in tf405.ato
- SPI1 configuration documented (Mode 0, 10MHz max)
- `ato build` compiles without errors

**Notes**:
- Spec mentions separate VDD and VDDIO but current implementation only has single `vdd` pin - clarify if separate pins needed
- GYRO_1_ALIGN: CW270_DEG is firmware config, not hardware
- No BMI270 package available on packages.atopile.io - custom implementation required

---

### TASK-005: Implement Barometer BMP390
**Spec**: `specs/baro-bmp390.md`
**File**: `src/baro.ato` (lines 9-12)
**Current State**: I2C1 connections complete (PB8/PB9), component missing, ground missing
**Priority**: HIGH - Critical for altitude hold
**Dependencies**: TASK-001 (I2C1), TASK-002 (3.3V rail), TASK-006 (I2C bus pullups)

**Required Implementation**:
- BMP390 component with LGA-10 footprint (custom - no atopile package available)
- VDD decoupling: 100nF
- VDDIO decoupling: 100nF
- SDO pin configuration for I2C address selection (0x76 or 0x77)
- Fix missing ground connection: `baro.gnd ~ power.gnd` in tf405.ato

**Acceptance Criteria**:
- Component instantiated with correct footprint
- All 6 assert statements implemented:
  - `vdd within 1.7V to 3.6V`
  - `vddio within 1.2V to 3.6V`
  - `c_vdd.value within 80nF to 120nF`
  - `c_vddio.value within 80nF to 120nF`
  - `r_scl_pullup.value within 4.5kohm to 4.9kohm`
  - `r_sda_pullup.value within 4.5kohm to 4.9kohm`
- Ground connection added in tf405.ato
- I2C address documented
- `ato build` compiles without errors

**Notes**:
- I2C pullups should be bus-level (see TASK-006), not device-level
- Shares I2C1 with external magnetometer via GPS connector
- No BMP390 package available on packages.atopile.io - custom implementation required

---

### TASK-006: Implement I2C Bus Infrastructure
**Spec**: `specs/baro-bmp390.md` (line 13), general I2C requirements
**File**: Create new `src/i2c.ato` or implement in `tf405.ato`
**Current State**: Missing - no I2C bus-level components
**Priority**: HIGH - Blocks TASK-005 and GPS magnetometer support
**Dependencies**: TASK-002 (3.3V rail)

**Required Implementation**:
- **I2C1 Bus Pullups** (one set for entire bus):
  - SCL pullup: 4.7kΩ to 3.3V
  - SDA pullup: 4.7kΩ to 3.3V

- **GPS Connector I2C Routing**:
  - Connect `gps_conn.scl ~ mcu.pb8` (currently missing in tf405.ato)
  - Connect `gps_conn.sda ~ mcu.pb9` (currently missing in tf405.ato)

**Acceptance Criteria**:
- Pullup resistors instantiated at bus level (not per-device)
- Assert statements for resistor values (4.5kΩ to 4.9kΩ) implemented in TASK-005
- GPS connector I2C signals wired to MCU I2C1
- `ato build` compiles without errors

**Notes**:
- Pullups shared by BMP390 and external magnetometer
- Critical: One set of pullups per bus, not per device

---

### TASK-007: Implement Flash Memory W25Q128
**Spec**: `specs/flash-w25q128.md`
**File**: `src/flash.ato` (lines 11-13)
**Current State**: SPI3 connections complete (PC10/PC11/PB5/PB7), component missing, ground missing
**Priority**: MEDIUM - Needed for blackbox logging
**Dependencies**: TASK-001 (SPI3), TASK-002 (3.3V rail)

**Required Implementation**:
- W25Q128JVSIQ component with SOIC-8 footprint (custom - no atopile package available)
- VCC decoupling: 100nF
- /WP and /HOLD pins tied to VCC (direct or via 10kΩ pullups)
- Fix missing ground connection: `flash.gnd ~ power.gnd` in tf405.ato

**Acceptance Criteria**:
- Component instantiated with correct footprint
- All 2 assert statements implemented:
  - `vcc within 2.7V to 3.6V`
  - `c_vcc.value within 80nF to 120nF`
- Ground connection added in tf405.ato
- `ato build` compiles without errors

**Notes**:
- SPI3 pins correctly mapped: PC10 (SCK), PC11 (MISO), PB5 (MOSI), PB7 (CS)
- No W25Q128 package available on packages.atopile.io - custom implementation required

---

### TASK-008: Implement OSD AT7456E
**Spec**: `specs/osd-at7456e.md`
**File**: `src/osd.ato` (lines 14-17)
**Current State**: SPI2 connections complete (PB13/PB14/PB15/PB12), component and video path missing, ground missing
**Priority**: MEDIUM - Needed for on-screen display
**Dependencies**: TASK-001 (SPI2), TASK-002 (3.3V rail), TASK-010 (video connectors)

**Required Implementation**:
- AT7456E component with TQFP-28 footprint (custom - no atopile package available)
- DVDD decoupling: 100nF
- AVDD ferrite bead + 100nF (isolated analog supply)
- Video path connections:
  - VIN (pin 17) connected to `video_in`
  - VOUT (pin 22) connected to `video_out`
- Fix missing ground connection in tf405.ato

**Acceptance Criteria**:
- Component instantiated with correct footprint
- All 4 assert statements implemented:
  - `dvdd within 3.0V to 3.6V`
  - `avdd within 3.0V to 3.6V`
  - `c_dvdd.value within 80nF to 120nF`
  - `c_avdd.value within 80nF to 120nF`
- Video pins mapped to physical pins 17 and 22
- Ground connection added
- `ato build` compiles without errors

**Notes**:
- SPI2 pins correctly mapped: PB13 (SCK), PB14 (MISO), PB15 (MOSI), PB12 (CS)
- Ferrite bead on AVDD for analog isolation (tf405.ato line 49 acknowledges this)
- Video signal wiring done in TASK-010
- No AT7456E package available on packages.atopile.io - custom implementation required

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
- `imu.gnd ~ power.gnd`
- `baro.gnd ~ power.gnd`
- `flash.gnd ~ power.gnd`
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
- IMU: ~25% (wiring done, component missing)
- Barometer: ~5% (wiring done, component + bus pullups missing)
- Flash: ~40% (wiring done, component missing)
- OSD: ~30% (wiring done, component + video path missing)
- USB: **100%** (TASK-003 complete — 10 components, 5 asserts, ato build passes)
- Motor/ESC: ~20% (connector defined, not wired)
- UART/RX: ~20% (connectors defined, not wired)
- Video/Misc: ~30% (partial wiring, circuits missing)

**Component Package Availability**:
- Available on packages.atopile.io: ~10-15% (USB connectors, possibly some passives)
- Custom implementation required: ~85-90% (all custom ICs)
- Generic passives (Capacitor, Resistor) work with custom component defs + auto-selection

**Estimated Work Remaining**: ~70% of circuit implementation + ~65% of constraint validation

**Code Audit Results**:
- ~27 TODO comments remaining (down from 43)
- 1 commented-out connection (intentional: sbus_inv.uart_rx in tf405.ato)
- 16/44 assert statements implemented (MCU + Power modules; 3 voltage-level asserts not feasible in v0.2.69)
- 0 FIXME/HACK/PLACEHOLDER markers
- 1 connector definition incomplete (SpareConnector missing duplicate power pins)

---

## Critical Blockers

1. **Missing ground connections** - Systematic issue across all 16 modules (TASK-018)
2. **Most component internals are TODO stubs** - MCU and Power done, sensors/peripherals still pending
3. **No PCB stackup defined** - Blocks layout for impedance-critical signals (TASK-020)
4. **Missing I2C bus infrastructure** - Blocks barometer and GPS magnetometer (TASK-006)
5. **No atopile packages for custom ICs** - BMI270, BMP390, W25Q128, AT7456E need custom implementation

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
