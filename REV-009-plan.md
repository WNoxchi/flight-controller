# REV-009: Replace MP1584EN with TI LMR43620 (NDAA Compliance)

## Motivation

The Brave F7 reference design uses TI LMR43620 buck converters (confirmed via TI
part marking lookup: "2MB5" = LMR43620MB5RPER). TI fabricates in Dallas, TX
(DFAB/RFAB) and other US fabs, making these components NDAA-compliant. MPS
(MP1584EN manufacturer) is fabless with primary operations in China.

## LMR43620 Pinout (CORRECT — from TI datasheet SNVSBY5B, Table 6-1)

**Top view** (looking down at chip with pin 1 indicator dot at top-left):
```
              pin9(GND)  pin8(VOUT/FB)
         ┌──────────────────────┐
  pin1   │ RT/MODE              │
  pin2   │ PGOOD    LMR43620   │  pin7  VCC
  pin3   │ EN/UVLO             │  pin6  BOOT
         └──────────────────────┘
              pin4(VIN)   pin5(SW)
```

**Pin table:**
| Pin | Name | Function |
|-----|------|----------|
| 1 | RT (or MODE/SYNC) | Switching frequency set resistor to GND (RT variant) / Mode select (MODE variant) |
| 2 | PGOOD | Open-drain power good output (pullup to VOUT or leave floating) |
| 3 | EN/UVLO | Enable input — has internal pullup to VIN; tie to VIN for always-on |
| 4 | VIN | Power input (3–36V) |
| 5 | SW | Switch node — connect to inductor |
| 6 | BOOT | Bootstrap — 100nF cap from BOOT to SW |
| 7 | VCC | Internal 3.3V LDO output — 1uF bypass cap to GND |
| 8 | VOUT/FB | Output sense (fixed variant: tie to VOUT) or feedback divider tap (adjustable) |
| 9 | GND | Power ground — largest pad, primary thermal path |
| A1–A4 | Anchor | 4 corner pads for solder reliability — connect to GND |

## Physical Pad Arrangement (bottom view / PCB footprint view)

```
    anchor  ┌─── pin9(GND,large) ── pin8(FB) ───┐  anchor
     (A1)   │                                     │  (A2)
            │                                     │
   pin1(RT) │         2.0 x 2.0 mm               │ pin7(VCC)
  pin2(PG)  │            body                     │ pin6(BOOT)
  pin3(EN)  │                                     │
            │                                     │
     (A3)   └─── pin4(VIN) ──── pin5(SW) ────────┘  (A4)
              anchor                           anchor
```

**Pad count by side:**
- Top: 4 pads (anchor_TL, GND, FB, anchor_TR)
- Bottom: 4 pads (anchor_BL, VIN, SW, anchor_BR)
- Left: 3 pads (RT, PGOOD, EN)
- Right: 2 pads (VCC, BOOT)
- **Total: 13 pads** — matches Brave F7 physical observation

**NOTE:** This is a HotRod (flip-chip) QFN. There is NO separate large exposed
thermal pad on the bottom. Heat dissipates through pin 9 (GND), which is the
largest functional pad. The 4 corner anchors are for mechanical solder reliability.

## Key Differences: MP1584EN vs LMR43620

| Feature | MP1584EN | LMR43620 |
|---------|----------|----------|
| Topology | Asynchronous (external Schottky) | **Synchronous** (no external diode) |
| Compensation | External RC on COMP pin | **Internal** (no COMP pin) |
| Package | SOIC-8 (3.9x4.9mm) | **VQFN-HR 2x2mm** (75% smaller) |
| Pad count | 8 | **13** (9 functional + 4 anchor) |
| Input range | 4.5–28V | 3–36V (42V transient) |
| Max current | 3A | 2A |
| VREF | 0.8V | **1.0V** |
| Frequency control | FREQ pin (resistor to GND) | RT pin or MODE/SYNC pin (variant-dependent) |
| Extra features | — | VCC (internal LDO), PGOOD output |
| Fixed output variants | No | Yes (5V, 3.3V) |

## Part Selection

### 5V BEC (replaces `buck` / U6)
- **Part**: LMR43620MB5RPER (fixed 5V, MODE/SYNC variant, 1MHz internal)
- **TI marking**: "2MB5" — confirmed match to Brave F7
- **LCSC**: C22438086 (~$2.36)
- No feedback divider needed — VOUT/FB (pin 8) connects directly to 5V output
- Pin 7 is MODE/SYNC: tie to GND for forced-PWM, or float for PFM (light-load efficiency)

### 10V VTX BEC (replaces `buck_10v` / U1)
- **Part**: LMR43620RNXTRPER (adjustable output, RT variant)
- **Sourcing**: TI direct / Mouser / DigiKey (~$0.93 from TI)
- Pin 7 is RT: resistor to GND sets switching frequency
- Feedback divider (1.0V reference):
  - RFBT = 90.9kohm, RFBB = 10kohm
  - VOUT = 1.0V × (1 + 90.9/10) = **10.09V**
  - Parallel check: 90.9k || 10k = 9.01kohm (within datasheet 5k–10k range)

**Note:** Verify the second Brave F7 chip marking — if it also says "2MB5", both
Brave F7 bucks may be fixed 5V with a different 10V approach. If it says "2R5" or
"2MNX", it's the adjustable variant.

## Component Changes Summary

### Per 5V Buck — Components REMOVED (6 parts)
| Current ref | Component | Reason removed |
|-------------|-----------|----------------|
| d_buck (D2) | SS34 Schottky catch diode | Synchronous — internal low-side FET |
| r_comp | 100kohm compensation R | Internally compensated |
| c_comp | 150pF compensation C | Internally compensated |
| r_freq | 100kohm frequency set R | MODE/SYNC variant has no RT resistor |
| r_fb_top | 210kohm FB top | Fixed 5V — no divider needed |
| r_fb_bot | 40kohm FB bottom | Fixed 5V — no divider needed |

### Per 5V Buck — Components ADDED (2 parts)
| New ref | Component | Value | Package | Purpose |
|---------|-----------|-------|---------|---------|
| c_vcc | VCC bypass cap | 1uF | 0402 | Internal LDO bypass (pin 7 → GND) |
| c_in_bypass | VIN HF bypass | 100nF, 50V | 0402 | High-frequency input bypass |

### Per 10V Buck — Components REMOVED (4 parts)
| Current ref | Component | Reason removed |
|-------------|-----------|----------------|
| d_buck_10v (D5) | SS34 Schottky catch diode | Synchronous |
| r_comp_10v | 100kohm compensation R | Internally compensated |
| c_comp_10v | 150pF compensation C | Internally compensated |
| r_freq_10v | 100kohm frequency set R | Replaced by r_rt_10v (different value) |

### Per 10V Buck — Components CHANGED
| Ref | Old → New | Notes |
|-----|-----------|-------|
| r_fb_10v_top | 115kohm → 90.9kohm | VREF changed 0.8V → 1.0V |
| r_fb_10v_bot | 10kohm → 10kohm | Same value (coincidence) |

### Per 10V Buck — Components ADDED (3 parts)
| New ref | Component | Value | Package | Purpose |
|---------|-----------|-------|---------|---------|
| c_vcc_10v | VCC bypass cap | 1uF | 0402 | Internal LDO bypass |
| c_in_10v_bypass | VIN HF bypass | 100nF, 50V | 0402 | High-frequency input bypass |
| r_rt_10v | RT resistor | ~13kohm | 0402 | Sets ~1MHz switching frequency |

### Both Bucks — Components CHANGED
| Ref | Old → New | Notes |
|-----|-----------|-------|
| IC | MP1584EN (SOIC-8) → LMR43620 (VQFN-HR 2x2mm) | Completely different footprint & pinout |
| c_bst | 100nF BST→SW → 100nF BOOT→SW | Same value, pin name change (pin 8→6) |
| c_buck_in | 22uF/35V (1210) → 4.7uF/50V (0805) | Smaller primary input cap |
| c_buck_out | 1× 22uF → 2× 22uF | Add second output cap for transient response |

### Net BOM Impact
| Metric | Before (MP1584EN ×2) | After (LMR43620 ×2) | Delta |
|--------|----------------------|----------------------|-------|
| Buck ICs | 2× SOIC-8 | 2× VQFN-HR 2×2mm | Much smaller |
| Schottky diodes | 2× SS34 (SMA) | 0 | **−2 parts** |
| Compensation RC | 4 (2R + 2C) | 0 | **−4 parts** |
| FB divider resistors | 4 (2 per buck) | 2 (10V only) | **−2 parts** |
| Freq/RT resistors | 2 | 1 (10V only) | **−1 part** |
| VCC bypass caps | 0 | 2 | +2 parts |
| VIN bypass caps | 0 | 2 | +2 parts |
| Output caps (extra) | 0 | 2 | +2 parts |
| **Net change** | | | **−3 parts** |

## Implementation Steps

### Step 1: Create custom KiCad footprint (13 pads)

Create `layouts/default/lib.pretty/TI_VQFN-HR-9_2x2mm_P0.4mm.kicad_mod` with
**all 13 pads**:

- **9 functional pads** positioned per TI RPE0009B mechanical drawing:
  - Left side (3 pads): pin 1 (RT), pin 2 (PGOOD), pin 3 (EN)
  - Bottom (2 pads): pin 4 (VIN), pin 5 (SW)
  - Right side (2 pads): pin 7 (VCC), pin 6 (BOOT)
  - Top (2 pads): pin 9 (GND, large ~1.3×0.55mm), pin 8 (VOUT/FB)
- **4 corner anchor pads** (~0.225×0.225mm each), assigned pad number "9" (GND net)
- **No separate thermal pad** — this is HotRod flip-chip
- **Thermal vias**: small array under pin 9 (GND) area, tied to pad "9"

Best approach: download the footprint from **Ultra Librarian** for
LMR43620MSC3RPERQ1 (same RPE0009 package) and adapt to our lib.pretty naming.

### Step 2: Create LMR43620 component definitions in power.ato

Two component blocks with **CORRECT** pin mapping:

```
component LMR43620_5V:
    footprint = "lib:TI_VQFN-HR-9_2x2mm_P0.4mm"
    mpn = "LMR43620MB5RPER"
    designator_prefix = "U"
    signal rt_mode ~ pin 1   # MODE/SYNC — tie to GND for FPWM or float for PFM
    signal pgood ~ pin 2     # Power good (open drain) — leave floating if unused
    signal en ~ pin 3        # Enable — tie to VIN for always-on
    signal vin ~ pin 4       # Input supply (3–36V)
    signal sw ~ pin 5        # Switch node — to inductor
    signal boot ~ pin 6      # Bootstrap — 100nF cap to SW
    signal vcc ~ pin 7       # Internal 3.3V LDO — 1uF bypass to GND
    signal fb ~ pin 8        # VOUT/FB — tie directly to 5V output
    signal gnd ~ pin 9       # Ground (+ 4 corner anchors share this pad number)

component LMR43620_ADJ:
    footprint = "lib:TI_VQFN-HR-9_2x2mm_P0.4mm"
    mpn = "LMR43620RNXTRPER"
    designator_prefix = "U"
    signal rt ~ pin 1        # RT — resistor to GND sets frequency
    signal pgood ~ pin 2     # Power good — leave floating if unused
    signal en ~ pin 3        # Enable — tie to VIN for always-on
    signal vin ~ pin 4       # Input supply
    signal sw ~ pin 5        # Switch node — to inductor
    signal boot ~ pin 6      # Bootstrap — 100nF cap to SW
    signal vcc ~ pin 7       # Internal 3.3V LDO — 1uF bypass to GND
    signal fb ~ pin 8        # FB — resistor divider midpoint
    signal gnd ~ pin 9       # Ground
```

### Step 3: Remove MP1584EN and rewrite SECTION 2 (5V Buck)

- Remove `component MP1584EN` definition
- Keep `component Schottky_SS34` (still used for USB power OR)
- Replace 5V buck section with LMR43620_5V circuit:
  - VIN (pin 4) → vbat, GND (pin 9) → gnd, EN (pin 3) → vbat
  - Input caps: 4.7uF/50V + 100nF/50V on VIN/GND (pinned MPN for 4.7uF)
  - Bootstrap: 100nF from BOOT (pin 6) to SW (pin 5)
  - Inductor: 4.7uH from SW (pin 5) to rail_5v (keep existing inductor)
  - Output caps: 2× 22uF on rail_5v/GND
  - FB (pin 8) → rail_5v (direct connection for fixed variant)
  - VCC (pin 7): 1uF bypass to GND
  - MODE/SYNC (pin 1): tie to GND for forced-PWM
  - Remove: d_buck, r_fb_top, r_fb_bot, r_comp, c_comp, r_freq

### Step 4: Rewrite SECTION 2b (10V VTX Buck)

- Replace with LMR43620_ADJ:
  - Same power/enable/bootstrap/inductor topology as Step 3
  - RT (pin 1): 13kohm to GND for ~1MHz switching
  - FB (pin 8): divider midpoint (90.9k top / 10k bottom)
  - VCC (pin 7): 1uF bypass to GND
  - Remove: d_buck_10v, r_comp_10v, c_comp_10v
  - Replace: r_freq_10v → r_rt_10v (different value)
  - Modify: r_fb_10v_top 115kohm → 90.9kohm

### Step 5: Pin high-voltage VIN capacitors

Create `component Cap_4u7F_50V` with pinned MPN (e.g., Samsung CL21B475KBFNNNE,
0805, 50V X7R). The generic atopile solver cannot select by voltage rating — these
sit directly on VBAT (up to 25.2V) and must be explicitly rated.

### Step 6: Update documentation

- `revisions.md` — Add REV-009 entry
- `WEIGHT_BUDGET.md` — Update: remove 2× SS34, smaller ICs, adjust cap counts
- `layout-checklist.md` — Update Groups 4 & 5 for 13-pad VQFN-HR layout
- `specs/power.md` — Update component specs

### Step 7: Verify build

Run `ato build` and confirm no errors or warnings from the new components.

## Current Capacity Check

LMR43620 is rated **2A max** (vs MP1584EN 3A):
- **5V rail**: ~0.5A typical, ~1.5A peak with accessories. 2A is sufficient.
- **10V VTX rail**: 0.5–1.5A typical (5–15W at 10V). 2A is sufficient.

## What Was Wrong in the Previous Attempt

The Codex agents used an **incorrect pin mapping** (hallucinated during context
compaction). The previous plan had:
- Pin 1=BOOT, Pin 2=SW, Pin 3=VIN, Pin 4=GND, Pin 5=FB, Pin 6=EN, Pin 7=RT,
  Pin 8=PGOOD, Pin 9=VCC

The **correct** mapping (from TI datasheet Table 6-1) is:
- Pin 1=RT/MODE, Pin 2=PGOOD, Pin 3=EN, Pin 4=VIN, Pin 5=SW, Pin 6=BOOT,
  Pin 7=VCC, Pin 8=VOUT/FB, Pin 9=GND

Every single pin was wrong. The footprint also only had 9 pads instead of 13
(missing the 4 corner anchor pads that the user correctly observed on the Brave F7).
