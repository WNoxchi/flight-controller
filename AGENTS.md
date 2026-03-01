# TF405 Flight Controller

STM32F405RGT6-based drone flight controller PCB designed in atopile. Specs are in `specs/` — read these for requirements. Each spec maps 1:1 to a source file in `src/` (e.g., `specs/power.md` → `src/power.ato`). The ground truth reference is `fc405-pinmap-spec.md`.

## Build & Run
```bash
ato build                     # Compile all builds defined in ato.yaml
ato build -b default          # Build specific target
ato build --open              # Build and open in KiCad
ato add <package-name>        # Add dependency (browse https://packages.atopile.io)
```

## Validation
After implementing, run `ato build` to verify the design compiles. This is the only backpressure — there are no unit tests, linters, or typecheckers. A passing `ato build` means the circuit netlist is valid. Check for:
- No unconnected pins on critical ICs
- All power rails have decoupling
- Constraint assertions pass (voltage ranges, resistance values)

## Key Design Constraints
1. **DMA2 errata**: PWM DShot only (not bitbanged). All motors on TIM8.
2. **SBUS inverter**: Hardware N-FET inverter on UART1_RX (F405 lacks software inversion).
3. **PB2/BOOT1**: Mandatory 10k pull-down (prevents SRAM boot trap).
4. **Analog video only**: No HD VTX BEC. AT7456E OSD overlays on composite video.
5. **USART6 unavailable**: PC6/PC7 used for motors. 5 usable UARTs.

## Common Mistakes to Avoid
- Don't forget VCAP1/VCAP2 on STM32F405 (internal regulator caps, 2.2uF each)
- Don't forget CC1/CC2 5.1k on USB-C (host won't enumerate without them)
- Don't forget the PB2 BOOT1 pull-down
- AT7456E needs separate analog power (ferrite bead isolation on AVDD)
- I2C needs bus-level pullups (one set per bus, not per device)

## Operational Notes

### atopile v0.2.69 Syntax (CRITICAL)
- **Signals**: Use `signal name` (NOT `name = new Electrical` — that's v0.10+ syntax)
- **Imports**: Paths are relative to the importing file (e.g., `from "power.ato" import X`, NOT `from "src/power.ato"`)
- **Config**: `ato.yaml` uses `ato-version` key (NOT `requires-atopile`); entry path must include `src/` prefix
- **Components**: Define with `component Name:` block, use `signal name ~ pin N` for pin mapping
- **Passives**: Define generic `component Capacitor` / `component Resistor` with `value: capacitance` / `value: resistance`, then set `.value = 100nF +/- 10%` on instances. The solver auto-picks LCSC parts.
- **Asserts**: `assert X.value within Yunit to Zunit` — the component's tolerance range must fit ENTIRELY within the assert range (e.g., `2.2uF +/- 10%` = 1.98-2.42uF FAILS `within 2.0uF to 2.4uF`; use `+/- 5%` instead)
- **Builtins**: Only `MODULE`, `COMPONENT`, `INTERFACE`, `PIN`, `SIGNAL` are built-in types
- **No generics library**: v0.2.69 has no built-in generics. Define Capacitor/Resistor/etc. in your source files.

### Build
- Activate venv first: `source .venv/bin/activate`
- Run: `ato build`
- Build outputs go to `build/` directory (netlist, BOM, assertions report)
- Check https://packages.atopile.io with subagents before defining components from scratch
- Reference atopile docs at https://docs.atopile.io/atopile/

### Component Patterns (established in mcu.ato)
- Custom ICs: `component Name:` with `footprint`, `mpn`, `designator_prefix`, and `signal ~ pin` mappings
- Generic passives: `component Capacitor:` with `value: capacitance` type annotation, `designator_prefix = "C"`, `mpn = "generic_capacitor"`
- Buttons: Fixed `footprint` and `mpn` on the component definition
- Connect passives inline: `node_a ~ cap.p1; cap.p2 ~ node_b`

