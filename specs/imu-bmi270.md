# Spec: IMU — BMI270 on SPI1

## Overview
Bosch BMI270 6-axis IMU (accel+gyro) on dedicated SPI1 bus with highest DMA priority.

## Connections
- SPI1_SCK: PA5, SPI1_MISO: PA6, SPI1_MOSI: PA7
- Chip Select: PC4 (GYRO_1_CS)
- Data-ready interrupt: PC5 (GYRO_1_EXTI)
- DMA2 streams dedicated to SPI1 (DMA2 errata: gets priority)

## Circuit
- VDD and VDDIO: 3.3V with 100nF decoupling each (close to chip)
- SPI mode: CPOL=0, CPHA=0 (Mode 0), max 10MHz clock
- CS active low, directly driven from MCU GPIO
- EXTI configured as rising edge for data-ready

## Betaflight Config
- GYRO_1_ALIGN: CW270_DEG (adjust based on physical orientation on PCB)
- USE_ACCGYRO_BMI270
