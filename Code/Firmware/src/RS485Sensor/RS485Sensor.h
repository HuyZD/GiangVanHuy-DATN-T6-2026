#ifndef RS485_SENSOR_H
#define RS485_SENSOR_H
#include <ModbusMaster.h>
#include <SoftwareSerial.h>

#define MAX485_CONTROL 2   // chân RE + DE
void preTransmission(); 
void postTransmission();
void RS485_Sensor_setup();
void RS485_Sensor_read(float temperature, float humidity);

#endif	//RS485_SENSOR_H    