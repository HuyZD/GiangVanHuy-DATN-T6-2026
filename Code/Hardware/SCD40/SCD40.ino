#include <SensirionI2cScd4x.h>
#include <Wire.h>
#define PowEn3 A3 
SensirionI2cScd4x sensor;

static char errorMessage[64];
static int16_t error;

void setup() {
    Serial.begin(115200);
         pinMode(PowEn3, OUTPUT);
  digitalWrite(PowEn3, LOW); 
    Wire.begin();
    sensor.begin(Wire, SCD41_I2C_ADDR_62); // alt.: SCD40_I2C_ADDR_62
    uint64_t serialNumber = 0;
    delay(30);

    error = sensor.wakeUp();
    if (error) {
        Serial.print("Error trying to execute wakeUp(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
    }

    error = sensor.stopPeriodicMeasurement();
    if (error) {
        Serial.print("Error trying to execute stopPeriodicMeasurement(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
    }

    error = sensor.reinit();
    if (error) {
        Serial.print("Error trying to execute reinit(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
    }

    error = sensor.getSerialNumber(serialNumber);
    if (error) {
        Serial.print("Error trying to execute getSerialNumber(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
        return;
    }
    Serial.print("SCD4x connected, serial number: ");
    PrintUint64(serialNumber);
    Serial.println();

    error = sensor.startPeriodicMeasurement();
    if (error) {
        Serial.print("Error trying to execute startPeriodicMeasurement(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
        return;
    }
}

void loop() {
    bool dataReady = false;
    uint16_t co2Concentration = 0;
    float temperature = 0.0;
    float relativeHumidity = 0.0;

    error = sensor.getDataReadyStatus(dataReady);
    if (error) {
        Serial.print("Error trying to execute getDataReadyStatus(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
        return;
    }

    if (dataReady) {
        sensor.readMeasurement(co2Concentration, temperature, relativeHumidity);
  
        Serial.println();
        Serial.print("CO2[ppm]: ");
        Serial.print(co2Concentration);

        // Serial.print("\tTemperature[°C]: ");
        // Serial.print(temperature, 1);

        // Serial.print("\tHumidity[%RH]: ");
        // Serial.print(relativeHumidity, 1);

        Serial.println();
    }
    else
        Serial.print(".");

    delay(500);
}

void PrintUint64(uint64_t& value) {
    Serial.print("0x");
    Serial.print((uint32_t)(value >> 32), HEX);
    Serial.print((uint32_t)(value & 0xFFFFFFFF), HEX);
}