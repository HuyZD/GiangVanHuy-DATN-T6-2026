#include "SCD40.h"
SensirionI2cScd4x scd4x;
void SCD40_setup() {
 Wire.begin();
 scd4x.begin(Wire, 0x62);
 //scd4x.wakeUp();
 scd4x.stopPeriodicMeasurement();
 scd4x.reinit();
 scd4x.startPeriodicMeasurement();
 delay(5000);
}
void SCD40_read() {
 bool dataReady = false;
 if (scd4x.getDataReadyStatus(dataReady) == 0 && dataReady) {
   uint16_t co2;
   float temp, humidity;
   if (scd4x.readMeasurement(co2, temp, humidity) == 0) {
     Serial.print("CO2 [ppm]: "); Serial.println(co2);
     Serial.print("Temp [°C]: "); Serial.println(temp);
     Serial.print("Humidity   [%]: "); Serial.println(humidity);
   }
 }
 delay(5000); // 0.2Hz sampling
}