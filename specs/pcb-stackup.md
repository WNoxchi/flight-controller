# Spec: PCB Layer Stackup and Manufacturing Constraints

## Overview
4-layer PCB stackup optimized for a 36mm x 36mm flight controller with mixed-signal
constraints: USB 2.0 differential pairs (90Ω), analog composite video (75Ω), high-current
battery/motor traces, and dense digital routing. Targets standard JLCPCB/PCBWay 4-layer
process for cost-effective prototyping.

## Layer Stackup

| Layer | Name     | Type    | Copper Weight | Purpose                                    |
|-------|----------|---------|---------------|--------------------------------------------|
| L1    | Top      | Signal  | 1 oz (35µm)  | Components, USB D+/D-, video, SPI, UART    |
| L2    | Inner 1  | Ground  | 0.5 oz (18µm)| Continuous GND plane (reference for L1)     |
| L3    | Inner 2  | Power   | 0.5 oz (18µm)| 3.3V fill, 5V fill, VBAT pour zones        |
| L4    | Bottom   | Signal  | 1 oz (35µm)  | Routing overflow, thermal pads, test points |

### Layer Thickness (Standard JLCPCB 4-layer)
```
L1 (Top copper)     :  35 µm  (1 oz)
Prepreg 2116        : 127 µm  (FR4, εr ≈ 4.3)
L2 (GND plane)      :  18 µm  (0.5 oz)
Core                : 800 µm  (FR4, εr ≈ 4.5)
L3 (Power plane)    :  18 µm  (0.5 oz)
Prepreg 2116        : 127 µm  (FR4, εr ≈ 4.3)
L4 (Bottom copper)  :  35 µm  (1 oz)
```
**Total board thickness**: ~1.6 mm (standard)

### Rationale
- **L2 as continuous GND**: Provides unbroken reference plane directly beneath L1 signal
  traces. Critical for USB 2.0 differential impedance, video signal integrity, and SPI
  clock return paths. GND plane must NOT be split — use a single contiguous copper pour.
- **L3 as power**: Distributes 3.3V, 5V, and VBAT as copper fills/zones. Splits are
  acceptable on the power layer (each rail gets its own zone). VBAT zone sized for
  motor current (up to 120A burst across 4 motors).
- **1 oz outer layers**: Supports higher current on battery input traces and motor output
  pads. Also provides better thermal dissipation for MP1584EN and AMS1117-3.3.
- **0.5 oz inner layers**: Standard for planes. Adequate for power distribution since
  L3 power zones carry distributed current, not concentrated traces.

## Impedance Targets

### USB 2.0 Full-Speed Differential Pair (D+/D-)
- **Target**: 90Ω ±10% differential impedance
- **Routing layer**: L1 (Top) over L2 (GND plane)
- **Trace width**: ~0.20 mm (8 mil) each line
- **Trace spacing**: ~0.15 mm (6 mil) gap between D+ and D-
- **Pair-to-pair clearance**: ≥0.5 mm (20 mil) from other signals
- **Length matching**: ±0.25 mm (±10 mil) between D+ and D-
- **Max length**: Keep under 50 mm (USB FS is forgiving, but shorter is better)
- **Notes**: 22Ω series resistors (in USB module) are placed close to MCU pads.
  Route as tightly-coupled differential pair from MCU PA11/PA12 to USB-C connector.
  Avoid vias in the differential pair. No reference plane breaks under the pair.

### Analog Video (Composite, 75Ω)
- **Target**: 75Ω ±10% single-ended impedance
- **Routing layer**: L1 (Top) over L2 (GND plane)
- **Trace width**: ~0.30 mm (12 mil)
- **Clearance**: ≥0.5 mm (20 mil) from digital signals
- **Segments**:
  - Camera connector → AT7456E VIN (pin 8): short, direct route
  - AT7456E VOUT (pin 3) → VTX connector: short, direct route
- **Notes**: Video signals are low-frequency (~6 MHz bandwidth for NTSC/PAL) so
  impedance matching is less critical than for high-speed digital. However, maintaining
  75Ω prevents ghosting and ringing artifacts. Keep traces short and direct. No vias
  in the video path if possible. GND plane must be continuous under video traces.

### SPI Buses (Digital, Non-Impedance-Controlled)
- **SPI1 (BMI270 IMU)**: Route on L1 directly, keep traces ≤25 mm. MISO/MOSI/SCK
  as a bus group with ≥0.15 mm spacing. CS trace can route independently.
  Clock rate up to 10 MHz — no impedance control needed, but keep return path clean.
- **SPI2 (AT7456E OSD)**: Similar constraints. Clock up to 10 MHz.
- **SPI3 (W25Q128 Flash)**: Clock up to ~21 MHz. Keep traces short and grouped.
  Route on L1 or L4 with continuous GND reference.

### I2C Bus (Digital, Non-Impedance-Controlled)
- **I2C1 (BMP390 + GPS magnetometer)**: Standard 100/400 kHz. No impedance control.
  4.7kΩ pullups to 3.3V already in baro module. Keep SDA/SCL traces ≤100 mm total
  bus length (including GPS connector cable).

## Trace Width and Current Capacity

### Power Traces (Minimum Widths)

| Net         | Max Current | Min Trace Width | Recommended Width | Layer |
|-------------|-------------|-----------------|-------------------|-------|
| VBAT input  | 30A burst   | 2.0 mm          | 3.0 mm or copper pour | L1/L3 |
| 5V rail     | 3A          | 0.5 mm          | 1.0 mm            | L1/L3 |
| 3.3V rail   | 0.5A        | 0.25 mm         | 0.5 mm            | L1/L3 |
| Motor M1-M4 | 30A burst   | 2.0 mm          | 3.0 mm or copper pour | L1    |
| GND return  | 30A burst   | Plane (L2)      | Full plane         | L2    |

**Current capacity reference (1 oz copper, outer layer, 10°C rise)**:
- 0.25 mm (10 mil): ~0.5A
- 0.50 mm (20 mil): ~1.2A
- 1.00 mm (40 mil): ~2.5A
- 2.00 mm (80 mil): ~5A (traces) or use copper pour for >5A

### Signal Traces

| Signal Type              | Trace Width | Spacing  |
|--------------------------|-------------|----------|
| General digital (GPIO)   | 0.15 mm     | 0.15 mm  |
| USB D+/D- (differential) | 0.20 mm     | 0.15 mm  |
| Video (75Ω)              | 0.30 mm     | 0.50 mm  |
| SPI clock/data           | 0.15 mm     | 0.15 mm  |
| I2C SDA/SCL              | 0.15 mm     | 0.15 mm  |
| UART TX/RX               | 0.15 mm     | 0.15 mm  |
| Analog (ADC inputs)      | 0.20 mm     | 0.30 mm  |

## Via Specifications

### Standard Signal Via
- **Drill diameter**: 0.3 mm (12 mil)
- **Annular ring**: 0.15 mm (6 mil) — pad diameter 0.6 mm
- **Use**: General signal routing, power connections ≤1A

### Power Via
- **Drill diameter**: 0.4 mm (16 mil)
- **Annular ring**: 0.20 mm (8 mil) — pad diameter 0.8 mm
- **Use**: Power rail connections (5V, 3.3V, VBAT) where copper pour stitching needed
- **Thermal relief**: Use for connections to L2 GND plane and L3 power zones

### Via Stitching (GND Plane)
- **Purpose**: Connect L1/L4 GND copper fills to L2 GND plane
- **Drill diameter**: 0.3 mm
- **Spacing**: ≤3 mm between stitching vias around board perimeter and near
  high-frequency circuits (USB, SPI1/IMU, OSD crystal)
- **Dense stitching zones**: Around USB connector, IMU, and OSD chip

### Via Restrictions
- **No vias** in USB D+/D- differential pair
- **No vias** in analog video traces (camera→OSD, OSD→VTX) if possible
- **Avoid vias** under QFP/TSSOP IC packages (risk of solder wicking)
- **Thermal vias**: Required under AMS1117-3.3 (SOT-223 tab pad → L2 GND via L3 power
  plane) and AT7456E exposed pad (TSSOP-28-EP → AGND). Use 5-7 vias in a grid
  pattern, 0.3 mm drill, within the thermal pad area.

## Design Rules Summary (DRC)

| Parameter                    | Value     | Notes                          |
|------------------------------|-----------|--------------------------------|
| Minimum trace width          | 0.127 mm  | 5 mil (JLCPCB standard)       |
| Minimum trace spacing        | 0.127 mm  | 5 mil                         |
| Minimum via drill            | 0.3 mm    | JLCPCB 4-layer minimum        |
| Minimum via annular ring     | 0.127 mm  | 5 mil                         |
| Minimum pad-to-pad clearance | 0.127 mm  | 5 mil                         |
| Minimum solder mask opening  | 0.05 mm   | Solder mask dam width          |
| Board edge clearance         | 0.3 mm    | Components and copper          |
| Drill-to-copper clearance    | 0.2 mm    | Via drill to adjacent trace    |
| Minimum silkscreen width     | 0.15 mm   | For readable text              |
| Minimum silkscreen height    | 0.8 mm    | For readable text              |

## Copper Pour and Fill Strategy

### L1 (Top) Copper Pour
- GND fill on unused areas (improves EMI, thermal dissipation)
- Keep clearance from impedance-controlled traces (USB, video)
- Stitch to L2 GND plane with vias every ≤3 mm

### L2 (GND Plane)
- **Must be continuous** — no splits, no routing on this layer
- Single GND net covers entire board area
- Thermal relief connections for through-hole and thermal vias
- This is the impedance reference for all L1 controlled-impedance traces

### L3 (Power Plane)
- Split into zones: 3.3V, 5V, VBAT
- Zone boundaries should not run under impedance-controlled traces on L1
  (creates reference discontinuity — but L2 GND is the primary reference, so
  L3 splits have minimal impact)
- VBAT zone: largest area, near ESC connector side of board
- 5V zone: near MP1584EN output and downstream consumers
- 3.3V zone: near AMS1117-3.3 output and MCU/sensors

### L4 (Bottom) Copper Pour
- GND fill on unused areas
- Stitch to L2 GND plane with vias

## Component Placement Guidelines

### Critical Placement Rules
1. **MP1584EN (buck converter)**: Place near board edge, close to ESC connector.
   Input cap, output cap, and catch diode within 5 mm of IC. Inductor directly
   adjacent. Switching node (SW) trace as short as possible — this is the highest
   dV/dt node on the board.
2. **AMS1117-3.3 (LDO)**: Place near MCU. Input cap and output cap within 5 mm.
   Thermal pad on L1 with vias to L2 GND for heat spreading.
3. **STM32F405RGT6 (MCU)**: Center of board. Decoupling caps within 3 mm of each
   VDD pin. HSE crystal within 10 mm of PH0/PH1.
4. **BMI270 (IMU)**: Place at board center or as close to center of mass as possible.
   Minimize distance to MCU SPI1 pins. Mechanical stress isolation (away from
   mounting holes and board edges). Decoupling caps within 2 mm.
5. **BMP390 (barometer)**: Keep away from airflow, prop wash, and heat sources.
   Consider foam/gel cover for pressure port isolation. Place away from MP1584EN.
6. **AT7456E (OSD)**: Place near video connectors (camera and VTX) to minimize
   analog video trace length. 27 MHz crystal within 5 mm. Ferrite bead between
   digital 3.3V and AVDD within 3 mm.
7. **W25Q128 (flash)**: Place near MCU SPI3 pins. No special placement constraints.
8. **USB-C connector**: Board edge. Route D+/D- as short differential pair to MCU.
9. **Connectors**: All JST-SH connectors at board edges. ESC connector on one side,
   other connectors distributed around remaining edges.

### Thermal Management
- MP1584EN: ~85% efficiency at 2A → ~0.35W dissipation. Copper pour around IC helps.
- AMS1117-3.3: ~0.34W at 200 mA. SOT-223 tab is VOUT (not GND) — connect tab to
  output copper pour. Use thermal vias under tab if needed for additional cooling.
- AT7456E: Minimal power dissipation. Exposed pad connects to AGND for thermal and
  electrical reasons.

## Manufacturing Notes

### Target Manufacturer
- **Prototype**: JLCPCB 4-layer (standard stackup, 1.6 mm, ENIG or HASL finish)
- **Surface finish**: ENIG recommended (better for fine-pitch LQFP-64, TSSOP-28-EP,
  LGA-14, LGA-10 soldering)
- **Solder mask**: Green (standard) or matte black (aesthetic, slightly higher cost)
- **Board thickness**: 1.6 mm ± 0.1 mm

### Assembly Notes
- All components are SMD — single-side assembly preferred (L1/Top)
- JST-SH connectors may require hand soldering or bottom-side placement
- LQFP-64 (MCU), TSSOP-28-EP (OSD), LGA-14 (IMU), LGA-10 (Baro) all require
  solder paste stencil and reflow
- BGA/QFN packages: None used (all packages have visible/accessible leads)

### Panelization
- 36 mm × 36 mm board fits well in 2×5 or 2×4 panel
- V-score or tab-route for depaneling
- Add fiducials (3× minimum) for pick-and-place alignment

## Impedance Calculation Reference

### Microstrip (L1 over L2 GND)
Using standard microstrip formula with:
- εr = 4.3 (2116 prepreg)
- h = 127 µm (prepreg thickness L1-to-L2)
- t = 35 µm (1 oz copper)

**Single-ended 75Ω** (video):
- w ≈ 0.30 mm (12 mil) → Z₀ ≈ 74Ω ✓

**Differential 90Ω** (USB D+/D-):
- w ≈ 0.20 mm (8 mil), s ≈ 0.15 mm (6 mil) → Zdiff ≈ 89Ω ✓

These values are approximations. Final trace widths must be verified with the
manufacturer's actual stackup data using a field solver (e.g., Saturn PCB Toolkit,
KiCad's built-in calculator, or Si9000). Request the manufacturer's stackup
specifications before finalizing impedance-controlled traces.

## Checklist for Layout Engineer

- [ ] Verify stackup with manufacturer before routing impedance-controlled traces
- [ ] Run impedance calculation with actual εr and layer thickness values
- [ ] Ensure L2 GND plane has NO cuts under USB or video traces
- [ ] Place all decoupling caps within specified distance of IC power pins
- [ ] Route USB D+/D- as differential pair, length-matched within 0.25 mm
- [ ] Route video traces at 75Ω, keep separate from digital signals
- [ ] Size VBAT and motor traces for 30A burst (≥2 mm or copper pour)
- [ ] Add thermal vias under AMS1117-3.3 tab and AT7456E exposed pad
- [ ] Stitch GND vias around board perimeter and near high-frequency ICs
- [ ] Verify all mounting holes clear copper with ≥0.5 mm annular clearance
- [ ] Add 3+ fiducials for SMT assembly alignment
