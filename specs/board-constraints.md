# Spec: Board Constraints and Form Factor

## Physical
- PCB outline: ~36mm
- Mounting holes: 30.5x30.5mm pattern, M3
- Target weight: ≤ 8g (reference: Brave F7 = 8g)
- Input voltage: 2-6S LiPo (7.4-25.2V)
- Video system: Analog only

## DMA2 Errata (Critical — ES0206 §2.1.10)
- DMA2 transfers corrupted when AHB peripherals accessed simultaneously
- SPI1 uses DMA2 — gets dedicated DMA priority for gyro
- Bitbanged DShot also requires DMA2 — conflicts with SPI1
- Solution: PWM-based DShot (not bitbanged), Betaflight default for F4

## SPI Bus Strategy
| SPI | Device       | Rationale                                   |
|-----|--------------|---------------------------------------------|
| SPI1| BMI270 (IMU) | Highest priority, dedicated DMA2 streams    |
| SPI2| AT7456E (OSD)| Separate bus, no contention with gyro       |
| SPI3| W25Q128 (Flash)| Bursty writes, isolated from flight-critical |

## NDAA Compliance
All major ICs from NDAA-compliant sources:
- STM32F405: STMicroelectronics (Franco-Italian)
- BMI270: Bosch (German)
- BMP390: Bosch (German)
- AT7456E: Microchip/Atmel (US)
- W25Q128: Winbond (Taiwanese, generally clean)
- MP1584EN: Monolithic Power Systems (US)
