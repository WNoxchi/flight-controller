# Spec: Barometer — BMP390 on I2C1

## Overview
Bosch BMP390 barometric pressure sensor for altitude hold.

## Connections
- I2C1_SCL: PB8, I2C1_SDA: PB9
- I2C address: 0x77 (SDO high) or 0x76 (SDO low)
- Shares I2C1 bus with external magnetometer via GPS connector

## Circuit
- VDD and VDDIO: 3.3V with 100nF decoupling
- I2C pullups: 4.7kΩ to 3.3V on SCL and SDA (one set for the bus)
- BMP390 is register-compatible with BMP388 (uses BMP388 Betaflight driver)

## Assert Constraints
```
# BMP390 supply voltage (datasheet: VDD 1.7–3.6V, VDDIO 1.2–3.6V)
assert vdd within 1.7V to 3.6V
assert vddio within 1.2V to 3.6V

# Decoupling caps
assert c_vdd.value within 80nF to 120nF
assert c_vddio.value within 80nF to 120nF

# I2C bus pullups (one set for the bus, 4.7k standard)
assert r_scl_pullup.value within 4.5kohm to 4.9kohm
assert r_sda_pullup.value within 4.5kohm to 4.9kohm
```
