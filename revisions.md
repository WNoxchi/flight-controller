# Future Revisions

Items identified during review that need addressing in future iterations.
Reference design: Brave F7 flight controller.

## Known Divergences from Brave F7 Reference

The Brave F7 is a reference, not a clone target. Key intentional differences:

- **MCU**: Brave F7 uses STM32F722RET6; this design uses STM32F405RGT6
- **Input voltage**: Brave F7 supports 3-8S (up to 33.6V); this design targets 2-6S (up to 25.2V)
- **BEC**: Brave F7 has 5V/3A + 10V/2A BEC; this design uses 5V/2A (LMR43620MB5RPER fixed) + 10V/2A VTX (LMR43620RNXTRPER adjustable), both TI, synchronous, 36V max input, NDAA-compliant
- **Board size**: Brave F7 is 37x37mm / 30x30mm mounting; this design matches at 37x37mm / 30x30mm
- **Flash**: Brave F7 has 16Mbit; this design has 128Mbit (W25Q128)
- **UARTs**: Brave F7 has 6; this design has 5 (F405 limitation)

## REV-001: Specify JST connector types for all connectors

**Status**: Fixed — JST-SH components defined, footprint library prefixes added

Added physical JST-SH 1.0mm SMD connector components (SM0xB-SRSS-TB) with
KiCad footprints, MPNs, and pin mappings to `src/connectors.ato`. Also fixed
all footprint identifiers across the project to use proper KiCad library
prefixes (e.g. `Package_QFP:LQFP-64_10x10mm_P0.5mm`).

Remaining: some custom footprints (buzzer MLT-8530, etc.) need `.kicad_mod`
files created in `layouts/default/lib.pretty/` before `ato build` can
complete the PCB update step. See REV-004.

## REV-004: Create missing custom KiCad footprints

**Priority**: High — blocks PCB generation via `ato build`

Several components use footprint names that don't exist in KiCad 9's standard
libraries. These need custom `.kicad_mod` files in `layouts/default/lib.pretty/`:

- `Buzzer_SMD_MLT-8530_8.5x8.5mm` (Buzzer_Beeper library has no match)
- Verify all other footprints resolve against KiCad 9 libraries
- BMP390 stub (`Bosch_LGA-10_2x2mm_P0.275x0.250mm`) already created but
  needs proper pad geometry from datasheet

The design netlist compiles and passes all assertions — this only affects
the final PCB file generation step.

## REV-006: Camera connector upgraded to 5-pin (matches Brave F7)

**Status**: Fixed

Changed CameraConnector from 3-pin to 5-pin JST-SH (SM05B-SRSS-TB) to match
the Brave F7 reference layout. New pinout: GND(1), 5V(2), VI(3), CC(4), GND(5).
Camera Control (PB3) now routes through the connector instead of a standalone
solder pad. The `CameraControl` passthrough module in misc.ato is no longer
instantiated in TF405. Spec `video-vtx-misc.md` updated accordingly.

## REV-005: Add footprints to all passive components

**Status**: Fixed

Generic `Resistor` and `Capacitor` components had no footprint assignments,
causing 62 components to be excluded from the KiCad PCB. Added default 0402
footprints, with overrides for larger caps (0603/0805/1206). Replaced generic
`ElectrolyticCap` with pinned components (`Cap_100uF_35V`, `Cap_22uF_10V_Tant`).
Board outline (36x36mm, 1mm corner radii) added to PCB file.

## REV-009: Replace MP1584EN buck converters with TI LMR43620 (NDAA compliance)

**Status**: Fixed

Replaced both MP1584EN (MPS, China-origin, SOIC-8) buck converters with TI LMR43620
(VQFN-HR 2x2mm) for NDAA/non-Chinese-origin compliance. Key changes:

- **5V BEC**: LMR43620MB5RPER (fixed 5V output, MODE/SYNC pin variant). No feedback
  divider needed — internal fixed output eliminates 2 resistors.
- **VTX BEC**: Originally LMR43620RNXTRPER (adjustable 10V), updated to LMR43620MB5RPER
  (fixed 5V) in REV-009b.
- **Synchronous topology**: Internal high-side and low-side FETs eliminate the external
  SS34 Schottky catch diode for each buck (2x SS34 removed; one SS34 remains for USB
  power OR).
- **Internal compensation**: No external COMP network needed — removes compensation cap
  and compensation resistor per buck.
- **Package**: SOIC-8 (3.9×4.9mm) → VQFN-HR (2.1×2.1mm) — 77% smaller footprint area.
  9-pad footprint (TI RPE0009B) with 4 L-shaped corner pads and exposed thermal pad.
- **New passives per buck**: 1µF VCC bypass cap (0402), 100nF VIN HF bypass cap (0402).
- **Input caps**: Changed from 22µF/35V 1210 to 4.7µF/50V 0805 per buck.
- **Output caps**: Doubled to 2× 22µF per buck (was 1×). Separate 5V bulk caps (2× 22µF
  1206) removed — output caps now provide sufficient bulk capacitance.
- **Current rating**: 2A max (vs 3A for MP1584EN) — sufficient for drone loads.
- **Files modified**: `src/power.ato`, `specs/power.md`, `WEIGHT_BUDGET.md`,
  `layout-checklist.md`.

## REV-010: Revert VTX BEC from 5V fixed to 10V adjustable

**Status**: Fixed

Reverted VTX BEC from fixed 5V (LMR43620MB5RPER) to adjustable 10V (LMR43620RNXTRPER),
matching the Brave F7 reference board's 10V VTX output. REV-009b incorrectly assumed
dual-5V topology. Key changes:

- **VTX BEC**: LMR43620MB5RPER (fixed 5V) → LMR43620RNXTRPER (adjustable, RT variant).
  Pin 1 is now RT (frequency set) instead of MODE/SYNC.
- **RT resistor**: 13kΩ to GND on pin 1 sets switching frequency to ~1MHz.
- **FB divider**: 90.9kΩ top + 10kΩ bottom → Vout = 1.0V × (1 + 90.9k/10k) = 10.09V.
  Replaces direct FB-to-output tie used by fixed variant.
- **PINIO1**: Now switches 10V instead of 5V; AO3401A P-FET rated -30V Vds handles 10V
  Vgs with margin. Gate pullup referenced to 10V VTX rail.
- **VTX connector**: Pin 1 now labeled 10V (was 5V). Signal renamed v5→v10.
- **New components**: 3x 0402 resistors (r_rt_vtx 13kΩ, r_fb_vtx_top 90.9kΩ, r_fb_vtx_bot 10kΩ).
- **Files modified**: `src/power.ato`, `src/connectors.ato`, `src/tf405.ato`,
  `specs/power.md`, `layout-checklist.md`.

## REV-009b: Align buck design with Brave F7 dual-5V topology

**Status**: Fixed

Changed VTX BEC from adjustable 10V (LMR43620RNXTRPER) to fixed 5V (LMR43620MB5RPER),
matching the Brave F7 dual-5V architecture. Both bucks now use the same fixed 5V part. Key changes:

- **VTX BEC**: LMR43620RNXTRPER (adjustable) → LMR43620MB5RPER (fixed 5V). Removed RT
  resistor (13kΩ) and feedback divider (90.9kΩ/10kΩ) — no longer needed for fixed variant.
- **EN/UVLO dividers**: Added 430kΩ/100kΩ divider on EN pin for both bucks. Sets UVLO
  threshold at ~6.47V rising (~5.5V falling via 3.4µA internal hysteresis current),
  protecting against operating on critically low battery.
- **PGOOD pullups**: Added 100kΩ pullup to output rail on both bucks.
- **Inductors**: 4.7µH → 2.2µH (Würth MAPI-4020, 74438356022, 4mm) — matches TI's 1MHz/5V
  recommendation and Brave F7 inductor specs.
- **PINIO1**: Now switches 5V instead of 10V; P-FET gate pullup referenced to 5V VTX rail.
- **Files modified**: `src/power.ato`, `src/connectors.ato`, `src/tf405.ato`.

## REV-008: Single smaller boot button (Omron B3U-1000P)

**Status**: Fixed

Replaced two TL3342F160QG tactile switches (3.5x3.5mm each) with a single Omron
B3U-1000P (3.0x2.5x1.6mm) for the BOOT0/DFU button, matching the Brave F7 reference
design. Key changes:

- **NRST button removed**: Reset circuit retains 10k pullup and 100nF debounce cap
  for proper operation; reset via power-cycle or SWD instead of dedicated button.
- **Button component updated**: Footprint changed from `SW_SPST_TL3342` to
  `SW_SPST_B3U-1000P`, MPN changed to `B3U-1000P`.
- **Weight savings**: ~0.21g (two TL3342 at 0.24g total replaced by one B3U at 0.03g).
- **Board space**: Frees ~12mm² from removed NRST button; remaining boot button
  footprint is 55% smaller (7.5mm² vs 12.25mm²).
- **Files modified**: `src/mcu.ato`, `specs/mcu-core.md`, `specs/board-mechanical.md`,
  `WEIGHT_BUDGET.md`.

## REV-007: Add VTX BEC and upgrade VTX connector to 5-pin

**Status**: Fixed (superseded by REV-009/009b for BEC component)

Added dedicated VTX BEC (originally 10V MP1584EN, later replaced — see REV-009/009b)
for VTX power, matching the Brave F7 reference design. Key changes:

- **VTX BEC**: Originally MP1584EN with 115kΩ/10kΩ feedback divider (Vout = 10.0V).
  Later replaced by TI LMR43620 in REV-009, then changed to fixed 5V in REV-009b.
- **PINIO1 redesign**: Added 2N7002 N-FET level shifter for proper P-FET gate
  drive. 3.3V PB2 cannot directly switch a P-FET — the N-FET inverts and
  level-shifts the control signal. 100kΩ pullup holds P-FET OFF by default
  (VTX off at power-on, safer than always-on).
- **VTX connector**: Upgraded from 4-pin to 5-pin JST-SH (SM05B-SRSS-TB).
  New pinout: 5V(1), GND(2), VIDEO(3), UART5_RX(4), UART5_TX(5).
  Full UART5 enables bidirectional VTX control (IRC Tramp, SmartAudio v2.1).
- **UART5_RX (PD2)**: Now connected to VTX connector pin 4. Previously unused.

## REV-002: ESC telemetry UART assignment — UART4 vs UART5

**Priority**: Low — firmware-configurable, but should match reference

Current design routes ESC telemetry to **UART4_RX (PA1)**.
Brave F7 reference uses **UART5 RX** for ESC telemetry.

Brave F7 ESC connector pinout: ESC1, ESC2, ESC3, ESC4, UART5_RX, ADC_CRNT, GND, VIN

Current spec ESC connector pinout: M1, M2, M3, M4, TELEM(UART4_RX), CURR, GND, VBAT

This is a firmware-level UART assignment choice and doesn't affect hardware correctness,
but matching the Brave F7 pinout would simplify firmware porting. Evaluate whether
UART4 or UART5 is better for ESC telemetry given the rest of the pin budget
(UART5_TX=PC12 is currently assigned to SmartAudio).

## REV-003: VBAT bulk cap voltage rating (fixed)

**Status**: Fixed in this revision

The atopile solver picked a 6.3V tantalum (C16133) for the VBAT bulk cap — unsafe
on a 6S input (25.2V). Replaced `c_vbat_bulk` and `c_buck_in` with voltage-rated
components using pinned MPNs (35V electrolytic and 50V MLCC respectively).
