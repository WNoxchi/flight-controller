# TF405 Research Board — Pin Map Specification

**Document Version:** 0.2 (Draft)
**MCU:** STM32F405RGT6 (LQFP-64, 168MHz Cortex-M4, 1MB Flash, 192KB RAM)
**Reference Design:** Rotor Riot Brave F7 (functional clone, adapted F722→F405)
**Secondary Reference:** SIMPLIFLYF405 Betaflight target (proven F405 pin allocation)
**Board Format:** ~36mm PCB outline, 30.5×30.5mm mounting holes (M3)
**Input Voltage:** 2-6S LiPo (7.4–25.2V)
**Video System:** Analog only (AT7456E OSD → composite video out)
**Target Weight:** ≤ 8g (Brave F7 reference: 8g)

---

## 1. Design Constraints (F405-Specific)

### DMA2 Errata (Critical)
The STM32F405 has a silicon errata (ES0206 §2.1.10) where DMA2 transfers can be
corrupted when AHB peripherals are accessed simultaneously. In practice this means:

- **SPI1 uses DMA2** — it gets dedicated DMA priority for the gyro
- **Bitbanged DShot also requires DMA2** — conflicts with SPI1
- **Solution:** F405 boards must use **PWM-based DShot** (not bitbanged), which is the Betaflight default for F4 targets
- **Implication:** Motor timer selection is less constrained than on F7/H7 (no need to avoid TIM1/TIM8 specifically), but DMA stream conflicts between motors still matter

### SPI Bus Strategy
The F405RGT6 (LQFP-64) exposes SPI1, SPI2, and SPI3. Standard allocation:

| SPI Bus | Device       | Rationale                                      |
|---------|--------------|-------------------------------------------------|
| SPI1    | BMI270 (IMU) | Highest priority, dedicated DMA2 streams        |
| SPI2    | AT7456E (OSD)| Separate bus avoids contention with gyro polling |
| SPI3    | W25Q128 (Flash)| Blackbox writes are bursty, isolated from flight-critical paths |

### I2C Bus Strategy

| I2C Bus | Device         | Rationale                              |
|---------|----------------|----------------------------------------|
| I2C1    | BMP390 (Baro)  | Standard I2C1 on PB8/PB9, shared bus available for external mag via GPS connector |

### UART Allocation
The F405 provides USART1, USART2, USART3, UART4, UART5, and USART6 (6 total).
The Brave F7 (F722) has 6 UARTs. We match that capability.

| UART   | Function              | Notes                                          |
|--------|-----------------------|------------------------------------------------|
| USART1 | Receiver (RX)         | Most common default for serial RX in Betaflight |
| USART2 | GPS (TX+RX)           | Full duplex for GPS NMEA/UBX                   |
| USART3 | Spare / MSP           | Available for MSP, telemetry, or companion computer |
| UART4  | ESC Telemetry (RX only)| Receives ESC telemetry from 4-in-1 ESC         |
| UART5  | SmartAudio / Analog VTX| VTX control protocol (TX only typically)       |
| USART6 | N/A (conflict)        | PC6/PC7 shared with MOTOR1/MOTOR2 — not usable |

---

## 2. Complete Pin Allocation

### Motors (TIM8 — PWM DShot)

| Resource   | STM32 Pin | Timer     | AF   | DMA          | Connector     |
|------------|-----------|-----------|------|--------------|---------------|
| MOTOR1     | PC6       | TIM8_CH1  | AF3  | DMA2_St2_Ch7 | ESC connector |
| MOTOR2     | PC7       | TIM8_CH2  | AF3  | DMA2_St3_Ch7 | ESC connector |
| MOTOR3     | PC8       | TIM8_CH3  | AF3  | DMA2_St4_Ch7 | ESC connector |
| MOTOR4     | PC9       | TIM8_CH4  | AF3  | DMA2_St7_Ch7 | ESC connector |

All four motors on TIM8 channels 1-4 is the most common F405 pattern. PC6-PC9 map
cleanly to TIM8 with AF3. Using a single timer for all motors simplifies DShot timing.

### SPI1 — IMU (BMI270)

| Resource        | STM32 Pin | Function   |
|-----------------|-----------|------------|
| SPI1_SCK        | PA5       | Clock      |
| SPI1_MISO (SDI) | PA6       | Data In    |
| SPI1_MOSI (SDO) | PA7       | Data Out   |
| GYRO_1_CS       | PC4       | Chip Select|
| GYRO_1_EXTI     | PC5       | Interrupt (EXTI, data-ready) |

BMI270 configuration in Betaflight config.h:
```c
#define GYRO_1_CS_PIN        PC4
#define GYRO_1_SPI_INSTANCE  SPI1
#define GYRO_1_EXTI_PIN      PC5
#define GYRO_1_ALIGN         CW270_DEG  // Adjust based on physical orientation
```

### SPI2 — OSD (AT7456E)

| Resource         | STM32 Pin | Function    |
|------------------|-----------|-------------|
| SPI2_SCK         | PB13      | Clock       |
| SPI2_MISO (SDI)  | PB14      | Data In     |
| SPI2_MOSI (SDO)  | PB15      | Data Out    |
| MAX7456_CS       | PB12      | Chip Select |

OSD configuration:
```c
#define MAX7456_SPI_CS_PIN   PB12
#define MAX7456_SPI_INSTANCE SPI2
```

### SPI3 — Blackbox Flash (W25Q128JVSIQ)

| Resource         | STM32 Pin | Function    |
|------------------|-----------|-------------|
| SPI3_SCK         | PC10      | Clock       |
| SPI3_MISO (SDI)  | PC11      | Data In     |
| SPI3_MOSI (SDO)  | PB5       | Data Out    |
| FLASH_CS         | PB7       | Chip Select |

Flash configuration:
```c
#define FLASH_CS_PIN         PB7
#define FLASH_SPI_INSTANCE   SPI3
#define DEFAULT_BLACKBOX_DEVICE BLACKBOX_DEVICE_FLASH
```

**FLASH_CS pin choice (PB7 vs PA15):** PB7 was inherited from the SIMPLIFLYF405
reference target. PA15 is also commonly used as flash CS on F405 boards, but it
defaults to JTDI after reset and requires an AFIO remap to use as GPIO. Keeping
PA15 unallocated preserves full JTAG debug capability alongside the SWD interface
— a worthwhile option on a research board. PB7 is a clean GPIO with no alternate
function conflicts out of reset.

**FLASH_CS pin choice (PB7 vs PA15):** PB7 was inherited from the SIMPLIFLYF405
reference target. PA15 is also commonly used as flash CS on F405 boards, but it
defaults to JTDI after reset and requires an AFIO remap to use as GPIO. Keeping
PA15 unallocated preserves full JTAG debug capability alongside the SWD interface
— a worthwhile option on a research board. PB7 is a clean GPIO with no alternate
function conflicts out of reset.

### I2C1 — Barometer (BMP390) + External Mag (via GPS connector)

| Resource   | STM32 Pin | Function |
|------------|-----------|----------|
| I2C1_SCL   | PB8       | Clock    |
| I2C1_SDA   | PB9       | Data     |

I2C configuration:
```c
#define I2C1_SCL_PIN         PB8
#define I2C1_SDA_PIN         PB9
#define BARO_I2C_INSTANCE    I2CDEV_1
#define MAG_I2C_INSTANCE     I2CDEV_1
```

The BMP390 default I2C address is 0x77 (SDO high) or 0x76 (SDO low).
External magnetometer on the GPS module shares this I2C bus.

### UARTs

| Resource     | STM32 Pin | Connector        | Notes                        |
|--------------|-----------|------------------|------------------------------|
| UART1_TX     | PA9       | RX connector     | Receiver (bidirectional protocols) |
| UART1_RX     | PA10      | RX connector     | Serial RX input              |
| UART2_TX     | PA2       | GPS connector    | GPS TX (FC→GPS)              |
| UART2_RX     | PA3       | GPS connector    | GPS RX (GPS→FC)              |
| UART3_TX     | PB10      | Spare connector  | MSP / telemetry TX             |
| UART3_RX     | PB11      | Spare connector  | MSP / telemetry RX             |
| UART4_TX     | PA0       | (solder pad)     | Spare TX                     |
| UART4_RX     | PA1       | ESC connector    | ESC telemetry input          |
| UART5_TX     | PC12      | (solder pad)     | Spare / expansion            |
| UART5_RX     | PD2       | (solder pad)     | Spare / expansion            |
| UART6_TX     | PC6       | —                | CONFLICT: shared with MOTOR1 (not usable) |
| UART6_RX     | PC7       | —                | CONFLICT: shared with MOTOR2 (not usable) |

**USART6 note:** On the LQFP-64 package, USART6 TX/RX map to PC6/PC7 which are
already allocated to MOTOR1/MOTOR2 (TIM8). USART6 is therefore **not available** on
this design. This gives us 5 usable hardware UARTs, which matches most F405 FCs.

For SmartAudio VTX control (originally planned on UART6), use a **SoftSerial** port
on an available timer pin, or reassign UART5 if the spare isn't needed.

**Revised UART plan (5 hardware UARTs):**

| UART   | Function              | Config Default                         |
|--------|-----------------------|----------------------------------------|
| USART1 | Serial RX (Receiver)  | `SERIALRX_UART SERIAL_PORT_USART1`    |
| USART2 | GPS                   | `GPS_UART SERIAL_PORT_USART2`          |
| USART3 | Spare / MSP           | Available for companion computer, telemetry, etc. |
| UART4  | ESC Telemetry (RX)    | ESC sensor                             |
| UART5  | SmartAudio VTX        | `VTX_SMARTAUDIO_UART SERIAL_PORT_UART5`|

### ADC (Analog Sensing)

| Resource   | STM32 Pin | Function              | Voltage Divider       |
|------------|-----------|-----------------------|-----------------------|
| ADC_VBAT   | PC2       | Battery voltage sense | Resistive divider (typically 10:1) |
| ADC_CURR   | PC1       | Current sensor input  | From ESC current pad  |
| ADC_RSSI   | PC0       | RSSI analog input     | Optional, from RX     |

```c
#define ADC_VBAT_PIN         PC2
#define ADC_CURR_PIN         PC1
#define ADC_RSSI_PIN         PC0
#define ADC_INSTANCE         ADC3
```

### Miscellaneous

| Resource        | STM32 Pin | Function                     |
|-----------------|-----------|------------------------------|
| LED0            | PB0       | Status LED (active low)      |
| BEEPER          | PB1       | Buzzer output (inverted, drives FET) |
| LED_STRIP       | PB6       | WS2812 addressable LED data  |
| CAMERA_CONTROL  | PB3       | Betaflight camera control (OSD joystick) |
| USB_DM          | PA11      | USB Data-                    |
| USB_DP          | PA12      | USB Data+                    |
| BOOT0           | BOOT0 pin | DFU mode (active high)       |
| PINIO1          | PB2       | Switchable VBAT for analog VTX (pit mode) |

**⚠️ PB2/BOOT1 Hazard:** On the STM32F405, PB2 doubles as BOOT1. If BOOT0 is
held HIGH while PB2 is also HIGH, the MCU boots into SRAM instead of the DFU
bootloader — a confusing brick-like scenario. **A 10kΩ pull-down resistor on PB2
to GND is mandatory.** The PINIO MOSFET gate drive easily overcomes 10kΩ during
normal operation. The F722 Brave F7 doesn't need this because F7-series uses
option bytes instead of BOOT1.

```c
#define LED0_PIN             PB0
#define BEEPER_PIN           PB1
#define BEEPER_INVERTED
#define LED_STRIP_PIN        PB6
#define CAMERA_CONTROL_PIN   PB3
#define PINIO1_PIN           PB2
#define PINIO1_CONFIG        129    // Inverted push-pull (drives P-FET gate)
#define PINIO1_BOX           40     // USER1 mode (VTX pit mode)
```

### Video Path (Analog OSD)

| Signal    | STM32 Pin | Function                               |
|-----------|-----------|----------------------------------------|
| VID_IN    | —         | Camera composite video → AT7456E pin 17 (VIN) |
| VID_OUT   | —         | AT7456E pin 22 (VOUT) → VTX video input |

The video path does NOT pass through the MCU. Camera video goes directly into
the AT7456E, which overlays OSD text and outputs the composited signal to the VTX.
The MCU controls the OSD chip via SPI only.

---

## 3. Connector Pinouts

All connectors use JST-SH 1.0mm pitch (matching Brave F7 standard).
Solder pads provided in parallel with each connector.

### ESC Connector (8-pin JST-SH 1.0)
Follows Betaflight standard ESC pinout:

| Pin | Signal  | Notes                    |
|-----|---------|--------------------------|
| 1   | GND     |                          |
| 2   | VBAT    | Battery voltage passthrough |
| 3   | CURR    | Current sensor analog    |
| 4   | M1      | Motor 1 (PC6, DShot)    |
| 5   | M2      | Motor 2 (PC7, DShot)    |
| 6   | M3      | Motor 3 (PC8, DShot)    |
| 7   | M4      | Motor 4 (PC9, DShot)    |
| 8   | TELEM   | ESC telemetry (UART4_RX, PA1) |

### Receiver Connector (4-pin JST-SH 1.0)

| Pin | Signal  | Notes                          |
|-----|---------|--------------------------------|
| 1   | GND     |                                |
| 2   | 5V      | Regulated 5V BEC output        |
| 3   | RX1     | UART1_RX (PA10) — Serial RX in |
| 4   | TX1     | UART1_TX (PA9) — Telemetry out |

### GPS Connector (6-pin JST-SH 1.0)

| Pin | Signal  | Notes                          |
|-----|---------|--------------------------------|
| 1   | GND     |                                |
| 2   | 5V      | Regulated 5V                   |
| 3   | TX2     | UART2_TX (PA2) — FC→GPS        |
| 4   | RX2     | UART2_RX (PA3) — GPS→FC        |
| 5   | SCL     | I2C1_SCL (PB8) — External magnetometer |
| 6   | SDA     | I2C1_SDA (PB9) — External magnetometer |

This matches the Brave F7 and Matek standard GPS pinout.
Compatible with Matek M10Q, BN-880, and other GPS+Mag combo modules.

### Spare / MSP Connector (6-pin JST-SH 1.0)

Available for companion computer, telemetry radio, or other serial peripheral.

| Pin | Signal  | Notes                          |
|-----|---------|--------------------------------|
| 1   | GND     |                                |
| 2   | 5V      | Regulated 5V                   |
| 3   | TX3     | UART3_TX (PB10)                |
| 4   | RX3     | UART3_RX (PB11)               |
| 5   | 5V      | (secondary 5V reference)       |
| 6   | GND     | Second ground                  |

Pin layout retained from Brave F7 HD VTX connector for physical compatibility.
If a digital VTX is connected in the future, MSP DisplayPort can be enabled
on UART3 via Betaflight configuration.

### Analog Camera Connector (5-pin JST-SH 1.0)

| Pin | Signal  | Notes                          |
|-----|---------|--------------------------------|
| 1   | GND     |                                |
| 2   | 5V      | Camera power                   |
| 3   | VI      | Composite video from camera to OSD |
| 4   | CC      | Camera control (PB3)           |
| 5   | GND     | Secondary ground               |

### Analog VTX Connector (5-pin JST-SH 1.0)

| Pin | Signal    | Notes                              |
|-----|-----------|------------------------------------|
| 1   | 10V       | Switchable 10V via PINIO1 (pit mode on/off) |
| 2   | GND       |                                    |
| 3   | VIDEO     | Composite video in (from OSD out)  |
| 4   | RX        | UART5_RX (PD2) for bidirectional VTX protocols |
| 5   | TX        | UART5_TX (PC12) SmartAudio/Tramp control |

**Note:** VTX power is supplied by the 10V buck and switched through the PINIO1
high-side FET stage for pit mode control.

### USB-C Connector (16-pin SMD, e.g. GCT USB4085-GF-A)

| Function   | Connection                              |
|------------|-----------------------------------------|
| VBUS       | → Schottky diode → 5V rail (power OR)  |
| CC1        | → 5.1kΩ to GND                         |
| CC2        | → 5.1kΩ to GND                         |
| D+         | → ESD prot → 22Ω → PA12 (USB_DP)      |
| D-         | → ESD prot → 22Ω → PA11 (USB_DM)      |
| GND        | → Ground plane                         |
| SHIELD     | → GND via 1MΩ ∥ 4.7nF                 |

USB-C is used for DFU firmware flashing and Betaflight Configurator access.
BOOT0 button + USB-C connection enters DFU bootloader mode.
FC is fully functional on USB power alone (no battery required for configuration).

---

## 4. Pin Budget Summary

### LQFP-64 Pin Usage

| Category         | Pins Used | Pins          |
|------------------|-----------|---------------|
| Motors (TIM8)    | 4         | PC6,7,8,9     |
| SPI1 (IMU)       | 5         | PA5,6,7 + PC4,5 |
| SPI2 (OSD)       | 4         | PB12,13,14,15 |
| SPI3 (Flash)     | 4         | PC10,11 + PB5,7 |
| I2C1 (Baro/Mag)  | 2         | PB8,9          |
| UART1 (RX)       | 2         | PA9,10         |
| UART2 (GPS)      | 2         | PA2,3          |
| UART3 (Spare/MSP)| 2         | PB10,11        |
| UART4 (ESC Telem)| 2         | PA0,1          |
| UART5 (Spare/SA) | 2         | PC12 + PD2    |
| ADC              | 3         | PC0,1,2        |
| USB              | 2         | PA11,12        |
| Misc (LED, Buzz) | 4         | PB0,1,2,3     |
| LED Strip        | 1         | PB6            |
| **Total**        | **39**    |                |

LQFP-64 has 51 GPIO pins (64 pins minus power/ground/reset/boot/osc).
This leaves ~12 pins as spares or for optional features (servo output,
additional PINIO, second camera input, etc.).

### Unallocated Pins (Available for Future Use)

| Pin  | Potential Use                              |
|------|--------------------------------------------|
| PA4  | Peripheral signal output (GPIO/DAC)       |
| PA8  | Gyro CLKIN (if BMI270 external clock used) |
| PA13 | SWDIO (debug, keep accessible)             |
| PA14 | SWCLK (debug, keep accessible)             |
| PA15 | Spare GPIO / additional CS                 |
| PB4  | Spare timer output (servo)                 |
| PC3  | Spare ADC input                            |
| PC13 | Spare GPIO                                 |
| PC14 | OSC32_IN (if no LSE crystal, usable as GPIO) |
| PC15 | OSC32_OUT (if no LSE crystal, usable as GPIO) |

**PA4 peripheral signal output:** Reserve this GPIO/DAC-capable pin for signaling
to peripheral devices. Break it out to a solder pad labeled PA4. Firmware defines
the signal behavior; hardware-timer PWM servo support is not specified here.

---

## 5. Power Architecture

### Power Tree

```
VBAT (2-6S, 7.4–25.2V)
 │
 ├─── TVS Diode (SMBJ26A or equiv, clamp ~29V) ── input protection
 │
 ├─── VBAT passthrough ─────── ESC connector (battery pads)
 │
 ├─── 10V Buck Regulator ────── rail_10v
 │     LMR43620RNXTRPER, ~10.09V output
 │
 ├─── PINIO1 switch stage ───── Analog VTX connector (10V)
 │     PB2 -> 10k -> 2N7002 -> AO3401A gate, 100k pullup to 10V
 │     Provides switchable 10V for VTX pit mode control (USER1)
 │
 ├─── Voltage Divider (10:1) ── ADC_VBAT (PC2)
 │     R_top = 10kΩ, R_bot = 1kΩ → 25.2V in = 2.29V at ADC (safe for 3.3V ADC)
 │
 ├─── 5V Buck Regulator ─────── 5V rail
 │     LMR43620R5RPER, fixed 5V
 │     │                          ├── GPS module
 │     │                          ├── Receiver
 │     │                          ├── Camera (analog)
 │     │                          ├── LED strip (WS2812)
 │     │                          ├── Buzzer driver
 │     │                          ├── USB VBUS output (via Schottky OR)
 │     │                          └── 3.3V LDO input
 │     │
 │     └─── 3.3V LDO ──────────── 3.3V rail
 │                                  ├── STM32F405 (VDD, VDDA)
 │                                  ├── BMI270 (VDD + VDDIO)
 │                                  ├── BMP390 (VDD + VDDIO)
 │                                  ├── AT7456E (DVDD + AVDD via ferrite)
 │                                  ├── W25Q128 (VCC)
 │                                  └── I2C pullups, SPI pullups
 │
 └─── Current Sense (from ESC) ── ADC_CURR (PC1)
       Via shunt resistor on ESC, voltage output to FC

USB VBUS (5V from computer)
 │
 └─── Schottky Diode ──── 5V rail (OR'd with BEC output)
       Allows USB power to run FC without battery
       Prevents backfeed from battery BEC into USB host
```

**Design note — REV-009 power topology:** This board now includes two LMR43620
buck stages: a fixed 5V rail and an adjustable ~10V rail for analog VTX power.
The 10V rail is switched to the VTX connector through the PINIO1 high-side FET.

### 5V Buck Regulator

**Implemented: LMR43620R5RPER** (Texas Instruments, fixed output)
- Input: 3–36V operating range (board target 2-6S, 7.4–25.2V)
- Output: fixed 5V
- Max current: 2A
- Switching frequency: set with RT resistor (13kΩ used, ~1MHz target)
- Package: VQFN-HR 2x2mm with exposed thermal pad
- Topology: synchronous buck, internally compensated

**Required external components (LMR43620 5V stage):**
- Input cap: 4.7µF/50V ceramic + 100nF HF bypass
- Output caps: 2x 22µF ceramics at the buck output node
- Inductor: 4.7µH shielded power inductor
- BOOT cap: 100nF between BOOT and SW
- VCC cap: 1µF local bypass
- Feedback: direct tie from VOUT/FB pin to 5V rail (fixed variant)

### 10V VTX Buck Regulator

**Implemented: LMR43620RNXTRPER** (Texas Instruments, adjustable)
- Input: 3–36V operating range (board target 2-6S, 7.4–25.2V)
- Output: ~10.09V via 90.9kΩ / 10kΩ divider
- Max current: 2A
- Package: VQFN-HR 2x2mm with exposed thermal pad
- Topology: synchronous buck, internally compensated

### 3.3V LDO Regulator

**Recommended: AMS1117-3.3** (or ME6211C33 for lower dropout)
- Input: 5V (from BEC)
- Output: 3.3V
- Max current: 1A (AMS1117) / 500mA (ME6211)
- Dropout: ~1.1V (AMS1117) / ~0.1V (ME6211)
- Package: SOT-223 (AMS1117) / SOT-23-5 (ME6211)

**Current budget on 3.3V rail:**

| Consumer          | Typical Current | Peak Current |
|-------------------|-----------------|--------------|
| STM32F405 (168MHz)| 50mA            | 100mA        |
| BMI270            | 0.7mA           | 5mA          |
| BMP390            | 0.7mA           | 3mA          |
| AT7456E           | 30mA            | 50mA         |
| W25Q128 (write)   | 15mA            | 25mA         |
| I2C/SPI pullups   | 5mA             | 10mA         |
| **Total**         | **~100mA**      | **~193mA**   |

The 3.3V rail peak is well under 200mA. Either AMS1117 or ME6211 has ample margin.
The AMS1117 is the most commonly used LDO on FPV flight controllers and is extremely
cheap (~$0.03 on LCSC). Its SOT-223 footprint also provides decent thermal dissipation.
Power dissipation at worst case: (5.0 - 3.3V) × 0.2A = 0.34W — trivial for SOT-223.

**Required external components (AMS1117-3.3):**
- Input cap: 10µF ceramic (close to LDO input pin)
- Output cap: 22µF tantalum OR 22µF ceramic + 1Ω series resistor
  (AMS1117 requires ESR on output for stability — tantalum is safest)
- Note: Many modern AMS1117 clones are stable with ceramics, but the
  tantalum + ceramic combo is the proven flight controller approach

### USB-C Implementation

The STM32F405 has an integrated USB 2.0 Full-Speed OTG peripheral (PA11/PA12).
USB-C is implemented as a **device-only (UFP/sink)** connection for firmware flashing
and Betaflight configurator access.

**USB-C connector:** Standard 16-pin mid-mount SMD (GCT USB4085-GF-A or equiv)

**Required circuit:**

```
USB-C Connector                    STM32F405
┌──────────┐
│ VBUS ────┼──── 5.1kΩ to GND (CC1)    (CC resistors identify as UFP/sink)
│ CC1  ────┼──── 5.1kΩ to GND (CC2)
│ CC2  ────┼
│ D+   ────┼──── ESD ──── 22Ω ──── PA12 (USB_DP)
│ D-   ────┼──── ESD ──── 22Ω ──── PA11 (USB_DM)
│ GND  ────┼──── GND
│ SHIELD──┼──── GND (via 1MΩ + 4.7nF to GND, or direct)
└──────────┘
      │
      VBUS ──── Schottky diode ──── 5V rail (power OR with BEC)
                (SS34 or equiv, Vf ~0.3V)
```

**Key components:**
- **2× 5.1kΩ resistors** on CC1 and CC2: Required by USB-C spec to identify the
  device as a sink/UFP. Without these, USB-C hosts won't provide power or enumerate.
- **ESD protection:** USBLC6-2SC6 (ST) or PRTR5V0U2X (Nexperia) — dual-line TVS
  for D+/D-. Place as close to connector as possible.
- **22Ω series resistors** on D+/D-: Impedance matching per USB 2.0 spec.
  The STM32F405 has an internal 1.5kΩ pull-up on D+ (embedded), so no external
  pull-up is needed.
- **Schottky diode** on VBUS: Prevents battery BEC from backfeeding into USB host.
  Allows the FC to be powered from USB alone (for configuration without battery).
  The Brave F7 specifically advertises this capability.
- **VBUS decoupling:** 4.7µF ceramic on VBUS after the Schottky.

**NDAA note:** USBLC6-2SC6 is STMicroelectronics (Franco-Italian, clean).
PRTR5V0U2X is Nexperia (Dutch, clean). GCT connectors are a UK company (clean).

### Battery Voltage Sensing

**Resistor divider: 10kΩ (top) + 1kΩ (bottom)**
- Ratio: 1:11 → 25.2V battery = 2.29V at ADC pin
- STM32 ADC range: 0–3.3V (12-bit, 4096 counts)
- Resolution: 3.3V / 4096 × 11 = ~8.86mV per count
- Betaflight voltage scale: 110 (default for 10:1 divider)

Add 100nF filter cap across the bottom resistor (at ADC pin) for noise filtering.

### Current Sensing

Current measurement comes from the 4-in-1 ESC's built-in current sensor.
The ESC outputs an analog voltage proportional to total current draw.
This connects to ADC_CURR (PC1) through a simple RC filter (1kΩ + 100nF).

The current scale in Betaflight depends on the specific ESC's sensor gain,
typically configured during initial setup.

### PINIO1 — Switchable 10V for Analog VTX

PB2 drives an N-FET/P-FET level-shifted high-side switch to control the
regulated 10V rail to the analog VTX connector. This provides pit mode functionality:
- VTX power off when disarmed (pit mode)
- VTX power controlled via Betaflight modes (USER1)

**Circuit:** PB2 -> 10kΩ -> 2N7002 gate; 2N7002 drain drives AO3401A gate with 100kΩ pullup to 10V
- **N-FET:** 2N7002 level shifter from 3.3V logic to 10V gate domain
- **P-FET:** AO3401A high-side switch
- **Source (P-FET):** 10V buck rail
- **Drain (P-FET):** VTX connector 10V pin
- Default OFF state is guaranteed by PB2 BOOT1 pulldown and the gate pullup network

### Decoupling Strategy

| Location              | Capacitor          | Notes                          |
|-----------------------|--------------------|--------------------------------|
| Each VDD pin (F405)   | 100nF ceramic      | As close to pin as possible    |
| VDDA                  | 1µF + 100nF        | Analog supply, extra filtering |
| VCAP1, VCAP2          | 2.2µF ceramic each | Internal regulator caps (required) |
| BMI270 VDD            | 100nF              | Close to chip                  |
| BMI270 VDDIO          | 100nF              | Close to chip                  |
| BMP390                | 100nF              | Close to chip                  |
| AT7456E DVDD          | 100nF              | Digital supply                 |
| AT7456E AVDD          | 100nF + ferrite bead | Analog supply, isolated from digital noise |
| W25Q128 VCC           | 100nF              | Close to chip                  |
| 5V rail bulk          | 4x 22µF MLCC total | 2x at buck output + 2x downstream bulk |
| 3.3V rail bulk        | 22µF tantalum      | Near LDO output (stability)    |
| VBAT input            | 2x 22µF/35V MLCC   | Near battery pads               |

### Power BOM Summary

| Component              | Part Number (example)  | LCSC Price  | NDAA    |
|------------------------|------------------------|-------------|---------|
| 5V Buck                | LMR43620R5RPER         | ~$1.70      | ✅ US (TI) |
| 10V Buck               | LMR43620RNXTRPER       | ~$0.93      | ✅ US (TI) |
| 3.3V LDO              | AMS1117-3.3            | ~$0.03      | ⚠️ (varies by mfg) |
| USB ESD Protection     | USBLC6-2SC6            | ~$0.15      | ✅ (ST, Franco-Italian) |
| Schottky (USB VBUS)    | SS34 (SMA package)     | ~$0.03      | ✅      |
| TVS (VBAT input)       | SMBJ26A                | ~$0.05      | ✅      |
| VTX MOSFET (PINIO)     | AO3401A                | ~$0.03      | ✅ (US, Alpha & Omega) |
| Buck inductor 4.7µH    | Various shielded       | ~$0.10      | ✅      |
| USB-C Connector        | GCT USB4085-GF-A       | ~$0.30      | ✅ (UK) |

**Estimated power section BOM cost: ~$1.50** (excluding passives)

---

## 6. MCU Support Circuits

These are essential support circuits for the STM32F405 that don't fall under
"power" or "peripherals" — they're the basic infrastructure the MCU needs to run.

### 8MHz HSE Crystal Oscillator

The STM32F405 requires an external 8MHz crystal for its High-Speed External
(HSE) oscillator. The PLL multiplies this up to the 168MHz core clock.

```
            STM32F405 (LQFP-64)
  Pin 12 ──┤ PH0 (OSC_IN)   ├──── 8MHz Crystal ────┤ PH1 (OSC_OUT) ├── Pin 13
            │                                         │
           C1 (20pF)                                 C2 (20pF)
            │                                         │
           GND                                       GND
```

**Components:**
- 8MHz crystal: 3.2×2.5mm SMD package (e.g., ABM8-8.000MHZ-B2-T), ±20ppm
- 2× load capacitors: 15–20pF ceramic (exact value per crystal datasheet)
- Optional: 1MΩ feedback resistor across crystal (some layouts include this)

**Layout rules:**
- Traces as short as possible (< 10mm)
- Ground pour under and around crystal area
- No signal vias under crystal footprint
- Keep digital signals away from oscillator traces

PH0 and PH1 are dedicated oscillator pins — not general-purpose GPIO.

### 32.768kHz LSE Crystal (Optional)

A Low-Speed External crystal on PC14/PC15 enables the RTC (Real-Time Clock).
Not required for Betaflight but useful for ArduPilot timestamp logging.

**For this research board:** Omit the LSE crystal. PC14 and PC15 are freed
as GPIO (the Brave F7 uses PC14 for LED0, PC13 for BEEPER — we use PB0/PB1
instead, so these pins are spare on our board).

If desired later, the LSE can be added with the same circuit topology as the
HSE but with a 32.768kHz crystal and 6.8pF load caps.

### BOOT0 Button (DFU Firmware Flashing)

The BOOT0 pin controls where the STM32 boots from on power-up. Normally
pulled LOW to boot from internal flash. Pulling HIGH during reset/power-on
enters the built-in DFU bootloader in system ROM, allowing firmware flashing
over USB.

```
         3.3V
          │
    ┌─────┤
    │  [BOOT0 Button]   (momentary tactile switch, e.g., 3×6mm SMD)
    │     │
    ├─────┴──── BOOT0 pin (pin 60 on LQFP-64)
    │
   10kΩ  (pull-down to GND — ensures normal boot from flash)
    │
   GND
```

**Optional:** 100nF debounce cap in parallel with the pull-down resistor.

**Usage workflow:**
1. Hold BOOT0 button
2. Plug in USB-C cable (or press RESET if already connected)
3. MCU enters DFU bootloader — shows as "STM32 BOOTLOADER" on PC
4. Flash Betaflight using Configurator or STM32CubeProgrammer
5. Release button, power cycle → boots normally from flash

This is how initial firmware is loaded before Betaflight's own `bl` CLI
command becomes available. The Brave F7 has this button.

### nRESET Button

Resets the MCU without power-cycling. Essential for a development board.

```
         3.3V
          │
        10kΩ  (external pull-up — supplements internal ~40kΩ)
          │
    ┌─────┤
    │   100nF  (debounce capacitor)
    │     │
    ├─────┴──── NRST pin (pin 14 on LQFP-64)
    │
    │  [RESET Button]   (momentary tactile switch)
    │     │
    └─────┘
          │
         GND
```

The STM32F405 has an internal pull-up on NRST (~40kΩ), but the external 10kΩ
improves noise immunity. The 100nF cap filters short glitches.

### SBUS Hardware Inverter (F405-Specific)

**This is the most significant F722→F405 porting difference.**

The STM32F722 (Brave F7) has built-in UART signal inversion configurable via
the USART_CR2 register (TXINV/RXINV bits). The STM32F405 does **NOT** have
hardware UART inversion.

SBUS (FrSky/Futaba protocol) uses an inverted UART signal at 100000 baud.
Without a hardware inverter, SBUS receivers will not work.

**Implemented circuit — N-channel MOSFET inverter on UART1_RX:**

```
                        3.3V
                         │
                       10kΩ  (pull-up)
                         │
SBUS RX output ── 1kΩ ──┤── Gate          Drain ──── UART1_RX (PA10)
                         │
                      2N7002 (N-FET, SOT-23)
                         │
                       Source
                         │
                        GND
```

**How it works:** SBUS idles HIGH (inverted logic). When SBUS signal is HIGH,
the FET turns ON, pulling UART1_RX LOW. When SBUS is LOW, FET is OFF, pull-up
brings UART1_RX HIGH. This inverts the signal back to standard UART polarity.

**Components:** 1× 2N7002 N-FET (SOT-23, ~$0.01), 1× 1kΩ, 1× 10kΩ

**Alternative approach — Dedicated SBUS pad:**
Many F405 boards provide a separate SBUS pad with the inverter circuit, while
the main RX connector pad bypasses the inverter for non-inverted protocols
(CRSF, ELRS, IBUS). This maximizes compatibility:

- **RX pad** (on RX connector): Direct to UART1_RX — for CRSF/ELRS (no inversion)
- **SBUS pad** (solder pad): Through inverter to UART1_RX — for SBUS receivers

**Recommendation for TF405:** Include the inverter with a solder bridge
or jumper to select inverted (SBUS) vs. non-inverted (CRSF/ELRS) input.
Default: non-inverted (CRSF/ELRS), since most modern receivers use these.

### SWD Debug Interface

Test pads for connecting an ST-LINK V2 debugger (~$3). Invaluable for a
research board — enables real-time debugging, breakpoints, flash recovery,
and live variable inspection.

| Pad | Signal | STM32 Pin | Notes |
|-----|--------|-----------|-------|
| 1   | SWDIO  | PA13      | Serial Wire Debug data |
| 2   | SWCLK  | PA14      | Serial Wire Debug clock |
| 3   | GND    | —         | Ground reference |
| 4   | 3.3V   | —         | Target power reference (optional) |
| 5   | NRST   | NRST      | Reset from debugger (optional) |

**Physical format:** Labeled through-hole pads or 1.27mm pitch header footprint
on board edge. Test pads are more space-efficient for the 30.5mm form factor.

PA13 and PA14 are dedicated SWD pins by default after reset. They can be
reclaimed as GPIO in firmware, but this is not recommended — it would lock
out the debugger. Betaflight does not remap these pins.

### Support Circuit BOM Addition

| Component            | Part (example)        | LCSC Price | Qty |
|----------------------|-----------------------|------------|-----|
| 8MHz crystal         | ABM8-8.000MHZ-B2-T   | ~$0.15     | 1   |
| HSE load caps        | 20pF 0402 ceramic     | ~$0.01     | 2   |
| BOOT0 button         | 3×6mm SMD tactile     | ~$0.02     | 1   |
| BOOT0 pull-down      | 10kΩ 0402             | ~$0.01     | 1   |
| BOOT1 pull-down      | 10kΩ 0402 (on PB2)    | ~$0.01     | 1   |
| RESET button         | 3×6mm SMD tactile     | ~$0.02     | 1   |
| RESET pullup+cap     | 10kΩ + 100nF          | ~$0.02     | 1+1 |
| SBUS inverter FET    | 2N7002 (SOT-23)       | ~$0.01     | 1   |
| SBUS resistors       | 1kΩ + 10kΩ 0402       | ~$0.02     | 2   |

**Estimated support circuit BOM: ~$0.30**

---

## 7. Betaflight config.h (Complete Draft)

```c
/*
 * TF405 Research Board
 * Betaflight Target Configuration
 */

#pragma once

#define FC_TARGET_MCU     STM32F405

#define BOARD_NAME        TF405
#define MANUFACTURER_ID   TF05

// Sensor drivers
#define USE_GYRO
#define USE_ACC
#define USE_ACCGYRO_BMI270

#define USE_BARO
#define USE_BARO_BMP388   // BMP390 is register-compatible, uses BMP388 driver

#define USE_MAX7456

#define USE_FLASH
#define USE_FLASH_W25Q128FV

// Beeper
#define BEEPER_PIN           PB1
#define BEEPER_INVERTED

// Motors
#define MOTOR1_PIN           PC6
#define MOTOR2_PIN           PC7
#define MOTOR3_PIN           PC8
#define MOTOR4_PIN           PC9

// LED Strip
#define LED_STRIP_PIN        PB6

// UARTs
#define UART1_TX_PIN         PA9
#define UART1_RX_PIN         PA10
#define UART2_TX_PIN         PA2
#define UART2_RX_PIN         PA3
#define UART3_TX_PIN         PB10
#define UART3_RX_PIN         PB11
#define UART4_TX_PIN         PA0
#define UART4_RX_PIN         PA1
#define UART5_TX_PIN         PC12
#define UART5_RX_PIN         PD2

// I2C1 — Baro + external Mag
#define I2C1_SCL_PIN         PB8
#define I2C1_SDA_PIN         PB9
#define BARO_I2C_INSTANCE    I2CDEV_1
#define MAG_I2C_INSTANCE     I2CDEV_1

// Status LED
#define LED0_PIN             PB0

// SPI1 — IMU (BMI270)
#define SPI1_SCK_PIN         PA5
#define SPI1_SDI_PIN         PA6
#define SPI1_SDO_PIN         PA7
#define GYRO_1_CS_PIN        PC4
#define GYRO_1_SPI_INSTANCE  SPI1
#define GYRO_1_EXTI_PIN      PC5
#define GYRO_1_ALIGN         CW270_DEG
#define USE_EXTI
#define USE_GYRO_EXTI

// SPI2 — OSD (AT7456E)
#define SPI2_SCK_PIN         PB13
#define SPI2_SDI_PIN         PB14
#define SPI2_SDO_PIN         PB15
#define MAX7456_SPI_CS_PIN   PB12
#define MAX7456_SPI_INSTANCE SPI2

// SPI3 — Blackbox Flash (W25Q128)
#define SPI3_SCK_PIN         PC10
#define SPI3_SDI_PIN         PC11
#define SPI3_SDO_PIN         PB5
#define FLASH_CS_PIN         PB7
#define FLASH_SPI_INSTANCE   SPI3
#define DEFAULT_BLACKBOX_DEVICE BLACKBOX_DEVICE_FLASH

// Camera control
#define CAMERA_CONTROL_PIN   PB3

// ADC
#define ADC_VBAT_PIN         PC2
#define ADC_CURR_PIN         PC1
#define ADC_RSSI_PIN         PC0
#define ADC_INSTANCE         ADC3
#define ADC3_DMA_OPT         1

// PinIO (switchable 10V for analog VTX pit mode)
#define PINIO1_PIN           PB2
#define PINIO1_CONFIG        129
#define PINIO1_BOX           40

// General-purpose peripheral signal output (solder pad)
// PA4 reserved for peripheral signaling — not in default config

// Default serial functions
// NOTE: SBUS requires external hardware inverter on F405 (see Section 6).
// Default RX connector is non-inverted for CRSF/ELRS.
// SBUS pad routes through N-FET inverter to the same UART1_RX pin.
#define SERIALRX_UART        SERIAL_PORT_USART1
#define GPS_UART             SERIAL_PORT_USART2
#define VTX_SMARTAUDIO_UART  SERIAL_PORT_UART5

// Timer mapping
#define TIMER_PIN_MAPPING \
    TIMER_PIN_MAP( 0, MOTOR1_PIN,        2,  1 ) \
    TIMER_PIN_MAP( 1, MOTOR2_PIN,        2,  1 ) \
    TIMER_PIN_MAP( 2, MOTOR3_PIN,        2,  1 ) \
    TIMER_PIN_MAP( 3, MOTOR4_PIN,        2,  0 ) \
    TIMER_PIN_MAP( 4, LED_STRIP_PIN,     1,  0 ) \
    TIMER_PIN_MAP( 5, CAMERA_CONTROL_PIN,1, -1 ) \
    TIMER_PIN_MAP( 6, BEEPER_PIN,        1, -1 )

// System
#define SYSTEM_HSE_MHZ 8
#define DEFAULT_CURRENT_METER_SOURCE CURRENT_METER_ADC
#define DEFAULT_VOLTAGE_METER_SOURCE VOLTAGE_METER_ADC
```

---

## 8. Transferability to H743 Production Board

Most peripheral circuits transfer directly. Key changes required:

| Subsystem        | F405 → H743 Change Required                    |
|------------------|-------------------------------------------------|
| MCU Power        | Single 3.3V LDO → SMPS + multi-domain supply   |
| Pin mapping      | Re-map to LQFP-100 pinout (more pins available) |
| SPI buses        | Same 3-bus architecture, potentially add SPI4 for dual gyro |
| UARTs            | Gain UART7/8 (up to 8 hardware UARTs)           |
| DMA              | H7 has DMAMUX — no DMA2 errata, bitbanged DShot OK |
| CAN bus          | H743 adds CAN FD (not present on F405 LQFP-64)  |
| Motor timers     | Can use bitbanged DShot on TIM1/TIM8             |
| Clock            | 168MHz → 480MHz, adjust PLL config               |
| Flash/Blackbox   | Can upgrade to MicroSD (SDIO interface on H743)   |
| Dual gyro        | Add second IMU on SPI4 with independent EXTI      |
| SBUS inverter    | Remove hardware inverter — H7 has software UART inversion |
| HSE crystal      | Same 8MHz crystal, no change                      |
| Video system     | Add 10V/2A BEC for HD digital VTX support (DJI O3, Walksnail) |
| PINIO1           | Switch from VBAT passthrough to 10V BEC control   |

The schematic for IMU, baro, OSD, flash, connectors, ADC sensing, and BEC
will transfer with minimal changes (same chips, same interfaces, different pin numbers).
The primary additions for the H743 board are HD digital VTX support (10V BEC + MSP
DisplayPort UART) and dual-gyro redundancy.
