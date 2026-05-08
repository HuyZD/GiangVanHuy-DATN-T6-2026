#ifndef PH_SENSOR_H
#define PH_SENSOR_H
#include <Arduino.h>
#define PH_PIN A7
void PH_Sensor_setup();
float PH_Sensor_read();

#endif	//PH_SENSOR_H