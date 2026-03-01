# Future Revisions

Items identified during review that need addressing in future iterations.
Reference design: Brave F7 flight controller.

## Known Divergences from Brave F7 Reference

The Brave F7 is a reference, not a clone target. Key intentional differences:

- **MCU**: Brave F7 uses STM32F722RET6; this design uses STM32F405RGT6
- **Input voltage**: Brave F7 supports 3-8S (up to 33.6V); this design targets 2-6S (up to 25.2V)
- **BEC**: Brave F7 has 10V/2A + 5V/3A dual BEC; this design has 5V/3A only (MP1584EN, 28V max input)
- **Board size**: Brave F7 is 37x37mm / 30x30mm mounting; this design is 36x36mm / 30.5x30.5mm
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
