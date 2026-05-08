#include "PH_sensor.h"

void PH_Sensor_setup()
{
}

float PH_Sensor_read()
{
  int adcValue = analogRead(PH_PIN);     // đọc ADC (0-1023)
  float voltage = adcValue * 5.0 / 1023; // đổi sang điện áp

  // công thức chuyển sang pH (cần hiệu chuẩn)
  float phValue = 7 + (2.5 - voltage) / 0.18;

  // Serial.print("ADC: ");
  // Serial.print(adcValue);

  // Serial.print("  Voltage: ");
  // Serial.print(voltage, 3);

  delay(1000);
  return phValue;
}
