#ifndef TDS_SENSOR_H
#define TDS_SENSOR_H

#include <Arduino.h>
#define TdsSensorPin A6
#define VREF 5.0              // analog reference voltage(Volt) of the ADC
#define SCOUNT  20           // sum of sample point

extern int analogBuffer[SCOUNT];     // store the analog value in the array, read from ADC
extern int analogBufferTemp[SCOUNT];
extern int analogBufferIndex ;
extern int copyIndex ;

extern float averageVoltage ;

extern float temperature ;       // current temperature for compensation
void TDS_Sensor_setup();
float TDS_Sensor_read();

#endif	//TDS_SENSOR_H