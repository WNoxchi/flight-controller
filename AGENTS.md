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
- Real `component` definitions with correct footprints, `mpn`, and pin mappings
- Real passive values with units and tolerances (e.g., `10kohm +/- 1%`, `100nF`)
- Check https://packages.atopile.io with subagents before defining components from scratch
- You can reference atopile documentation with subagents at https://docs.atopile.io/atopile/
- Connect components (wire them up)
- use the 'flight-controller' conda environment for python

