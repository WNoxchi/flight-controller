# Spec: Physical Board Constraints and Mechanical Drawing

## Overview
36mm x 36mm flight controller PCB with standard 30.5mm M3 mounting pattern, designed to
fit standard whoop/mini quad FC mounting stacks. All dimensions in millimeters unless noted.

## PCB Outline
- **Shape**: Square, 36.0 mm x 36.0 mm
- **Corner radius**: 1.0 mm (rounded corners to prevent snag/stress concentration)
- **Board thickness**: 1.6 mm (standard 4-layer, per pcb-stackup.md)
- **PCB material**: FR4

## Mounting Holes

### Pattern
- **Spacing**: 30.5 mm x 30.5 mm center-to-center (standard FPV FC mount pattern)
- **Hole diameter**: 3.2 mm (M3 clearance with 0.1 mm tolerance margin)
- **Hole positions** (origin = board center at 18.0, 18.0):
  - Top-left:     ( 2.75,  2.75)  — 2.75 mm from each board edge
  - Top-right:    (33.25,  2.75)
  - Bottom-left:  ( 2.75, 33.25)
  - Bottom-right: (33.25, 33.25)
- **Copper clearance**: 0.5 mm annular keep-out around each hole (no copper within 2.1 mm
  of hole center) to prevent shorts from M3 hardware and vibration damper grommets
- **Solder mask**: Pull back solder mask 0.15 mm from hole edge (expose FR4 ring)

### Mounting Notes
- Holes are plated (optional) — non-plated is acceptable since no electrical connection
- Soft-mount grommets (M3 silicone) recommended for vibration isolation (standard on
  FC stacks, not a PCB design constraint)
- Stack height between boards: 5–7 mm typical (M3 nylon standoffs)

## Component Height Restrictions

### Top Side (L1) — Primary component side
| Zone                    | Max Height | Reason                                          |
|-------------------------|------------|-------------------------------------------------|
| Center (IMU area)       | 2.0 mm     | IMU must be lowest point for foam cover          |
| Under stack area        | 8.0 mm     | Limited by stack spacing (ESC board above)       |
| Board edge (connectors) | 6.0 mm     | JST-SH connectors are ~4.25 mm tall             |
| General components      | 3.0 mm     | Standard SMD clearance                           |

### Bottom Side (L4) — Minimal components
| Zone                    | Max Height | Reason                                          |
|-------------------------|------------|-------------------------------------------------|
| Under mounting holes    | 0.0 mm     | Must be flat for standoff/grommet contact        |
| General                 | 1.5 mm     | Limited by standoff gap to frame                 |
| Center avoid zone       | 0.5 mm     | Frame posts or standoffs may contact here        |

### Tall Components Inventory
| Component               | Package         | Height (mm) | Placement Side |
|-------------------------|-----------------|-------------|----------------|
| USB-C (USB4085-GF-A)   | Mid-mount       | 3.31        | Top (L1)       |
| JST-SH connectors (x6) | Through-hole    | 4.25        | Top (L1) edge  |
| MLT-8530 buzzer         | SMD 8.5x8.5     | 3.0         | Top (L1)       |
| BOOT0 button (x1)      | SMD 3.0x2.5     | 1.6         | Top (L1)       |
| Electrolytic caps (x2)  | SMD 6.3x7.7     | 7.7         | Top (L1)       |
| Buck inductor           | SMD 6.3x6.3     | 3.0         | Top (L1)       |
| All other SMD           | Various         | ≤1.5        | Top (L1)       |

**Critical note**: The 100µF/50V electrolytic capacitors (battery bulk, 5V bulk) are the
tallest components at ~7.7 mm. These must be placed where stack clearance permits, or
replaced with lower-profile ceramic alternatives (e.g., 2x 47µF 0805 MLCCs in parallel)
if height is constrained by the specific frame/stack configuration.

## Connector Placement

### Edge Assignment
Connectors must be placed at board edges with pads facing outward for cable routing.
Recommended edge assignment based on typical quad frame geometry:

```
                    FRONT (props facing forward)
              ┌─────────────────────────────────┐
              │  ○                           ○  │
              │   (mounting)     (mounting)      │
      GPS     │                                 │  VTX
      Spare   │         ┌─────────┐             │  Camera
    (LEFT)    │         │  MCU    │             │  (RIGHT)
              │         │ (center)│             │
              │         └─────────┘             │
              │                                 │
              │   (mounting)     (mounting)      │
              │  ○                           ○  │
              └─────────────────────────────────┘
                REAR (toward ESC/battery)
                    ESC (8-pin, centered)
                    RX (4-pin)
                    USB-C (centered or offset)
```

### Connector Edge Rules
| Edge   | Connectors                        | Rationale                              |
|--------|-----------------------------------|----------------------------------------|
| Rear   | ESC (8-pin), RX (4-pin), USB-C    | ESC cable routes to rear arms; RX near ESC; USB accessible |
| Left   | GPS (6-pin), Spare (6-pin)        | GPS cable routes up; spare accessible   |
| Right  | VTX (4-pin), Camera (3-pin)       | Video cables route to frame-mounted cam/VTX |
| Front  | (none — reserved for airflow)     | Props face forward, minimize drag on cables |

### Connector Spacing
- Minimum 2.0 mm between adjacent connector footprints (solder pad to solder pad)
- Minimum 1.0 mm from connector pads to board edge
- USB-C connector is mid-mount (extends ~1.5 mm beyond board edge for plug access)
- JST-SH connectors: bottom-entry (cable exits parallel to board plane) preferred
  for stack compatibility; side-entry acceptable if height allows

## Solder Pad Placement

### Test/Debug Pads (top or bottom side)
| Pad     | Signal     | Minimum Size | Notes                                |
|---------|------------|--------------|--------------------------------------|
| SWDIO   | PA13       | 1.0 x 2.0   | SWD debug — accessible with pogo pins |
| SWCLK   | PA14       | 1.0 x 2.0   | SWD debug                             |
| GND     | Ground     | 1.0 x 2.0   | SWD reference                         |
| 3V3     | 3.3V rail  | 1.0 x 2.0   | SWD power check                       |
| NRST    | Reset      | 1.0 x 2.0   | SWD reset                             |

### GPIO Breakout Pads (top side, board edge)
| Pad     | Signal     | Minimum Size | Notes                                |
|---------|------------|--------------|--------------------------------------|
| LED     | PB6 (data) | 1.5 x 2.5   | WS2812 LED strip data (after 330Ω)   |
| LED 5V  | 5V rail    | 1.5 x 2.5   | LED strip power                       |
| LED GND | Ground     | 1.5 x 2.5   | LED strip return                      |
| CAM     | PB3        | 1.0 x 2.0   | Camera control OSD joystick           |
| PA4     | PA4        | 1.0 x 2.0   | Servo/detonator (DAC/PWM)             |

### SBUS Selection Pads (top side, near RX connector)
- Three-pad solder bridge: center pad = PA10 (UART1_RX), outer pads = direct RX and
  inverter output
- Pad size: 0.8 x 1.5 mm each, 0.3 mm gap between pads
- Default: center bridged to direct RX (CRSF/ELRS); cut and bridge to inverter for SBUS

## Keep-Out Zones

### Mounting Hole Keep-Outs
- 3.5 mm radius (7.0 mm diameter) clear zone around each mounting hole center
- No components, vias, or traces within this zone
- Allows for M3 washer (6.0 mm OD) + clearance

### IMU Isolation Zone
- 3.0 mm clear zone around BMI270 footprint (no copper pours, no high-current traces)
- No vias directly under IMU package (prevents solder wicking, mechanical stress)
- Keep decoupling caps within 2 mm but outside thermal-sensitive zone

### Barometer Isolation Zone
- BMP390 must be ≥10 mm from MP1584EN (thermal isolation from buck converter)
- BMP390 must be ≥5 mm from board edge (airflow/pressure isolation)
- No copper pour directly under BMP390 pressure port (pin 3 area)

### Buck Converter Zone
- MP1584EN switching node (SW, pin 1) trace keep-out: ≥0.5 mm from all sensitive
  analog signals (ADC, video, crystal)
- Input cap, output cap, catch diode, and inductor must be within 5 mm of MP1584EN
- This zone should be at the board edge near the ESC connector

### USB Differential Pair
- 0.5 mm clearance zone on each side of USB D+/D- differential pair
- No parallel traces within 1.0 mm of the pair
- GND plane must be continuous under entire USB route (no L2 splits)

## Board Edge Clearance
- **Components**: 0.3 mm minimum from component body to board edge
- **Copper**: 0.3 mm minimum from copper to board edge
- **Silkscreen**: 0.5 mm minimum from silkscreen to board edge
- **USB-C overhang**: Connector body extends up to 1.5 mm past board edge (by design)

## Fiducials and Markings

### Fiducial Marks
- 3 fiducials minimum (asymmetric placement for rotation detection)
- Fiducial diameter: 1.0 mm copper circle, 2.0 mm solder mask opening
- Placement: 3 corners (not the 4th — asymmetry ensures correct orientation)
- Must be on L1 (top) side for pick-and-place alignment

### Silkscreen Markings
- Board name: "TF405" (top side)
- Version number (e.g., "v1.0")
- Pin 1 indicators on all ICs (dot or triangle)
- Connector pin labels (pin 1 marked)
- Motor output labels: M1, M2, M3, M4
- UART labels: RX1/TX1, RX2/TX2, etc.
- Solder pad labels: LED, CAM, PA4, SBUS
- SWD pad labels
- Polarity indicators on electrolytic caps and diodes
- "FRONT" or arrow indicating quad nose direction (for gyro alignment)

## Mechanical Drawing Summary

```
    36.0 mm
  ├──────────────────────────┤

  ┌──────────────────────────┐ ─┬─
  │ ●                     ●  │  │
  │  ╲ R=1.0              ╱  │  │
  │                          │  │
  │   ⊕               ⊕     │  │  36.0 mm
  │   2.75    30.5    33.25  │  │
  │                          │  │
  │        [  MCU  ]         │  │
  │                          │  │
  │   ⊕               ⊕     │  │
  │                          │  │
  │ ●                     ●  │  │
  └──────────────────────────┘ ─┴─

  ⊕ = M3 mounting hole (3.2mm dia)
  ● = 1.0mm corner radius
  Origin (0,0) = bottom-left corner
  Mounting hole centers at (2.75, 2.75), (33.25, 2.75),
                           (2.75, 33.25), (33.25, 33.25)
```

## DXF Export Specification
For KiCad Edge.Cuts layer, the board outline consists of:
- 4 straight line segments connecting corner arc endpoints
- 4 arcs (90-degree, 1.0 mm radius) at each corner
- Board origin (0,0) at bottom-left corner

### Edge.Cuts Coordinates (counter-clockwise from bottom-left)
| Segment | Start (x, y)  | End (x, y)    | Type      |
|---------|---------------|----------------|-----------|
| Bottom  | (1.0, 0.0)    | (35.0, 0.0)   | Line      |
| Arc BR  | (35.0, 0.0)   | (36.0, 1.0)   | Arc R=1.0 |
| Right   | (36.0, 1.0)   | (36.0, 35.0)  | Line      |
| Arc TR  | (36.0, 35.0)  | (35.0, 36.0)  | Arc R=1.0 |
| Top     | (35.0, 36.0)  | (1.0, 36.0)   | Line      |
| Arc TL  | (1.0, 36.0)   | (0.0, 35.0)   | Arc R=1.0 |
| Left    | (0.0, 35.0)   | (0.0, 1.0)    | Line      |
| Arc BL  | (0.0, 1.0)    | (1.0, 0.0)    | Arc R=1.0 |

### Mounting Hole Coordinates (origin = bottom-left corner)
| Hole | Center (x, y) | Diameter | Copper Keep-Out |
|------|---------------|----------|-----------------|
| BL   | (2.75, 2.75)  | 3.2 mm   | 7.0 mm dia      |
| BR   | (33.25, 2.75) | 3.2 mm   | 7.0 mm dia      |
| TL   | (2.75, 33.25) | 3.2 mm   | 7.0 mm dia      |
| TR   | (33.25, 33.25)| 3.2 mm   | 7.0 mm dia      |

## Weight Budget Relevance
The 36x36mm 4-layer 1.6mm FR4 PCB (bare) weighs approximately:
- Board area: 36 x 36 = 1,296 mm² = 12.96 cm²
- FR4 density: ~1.85 g/cm³
- Board volume: 12.96 cm² x 0.16 cm = 2.07 cm³
- Bare board weight: ~3.8 g
- Components add ~2-4 g (depending on connector/capacitor choices)
- **Estimated total: 6-8 g** (within 8g target per board-constraints.md)
